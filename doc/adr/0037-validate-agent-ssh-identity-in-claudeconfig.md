# 37. Validate the agent SSH identity in claudeconfig

Date: 2026-06-15

## Status

Accepted

Builds on [ADR 0031](0031-role-scoped-agent-git-identity.md) (role-scoped agent
git identity) and [ADR 0036](0036-fail-loud-role-resolution.md) (fail-loud role
resolution).

## Context

`bin/check-agent-ssh-key` validates that an agent SSH identity is set up
correctly: local key files, Keychain, GitHub registration, Claude settings
wiring, and live SSH auth. But nothing ever forced it to run. It was a manual
command you remembered to invoke, which means in practice you didn't, and the
identity drifted out from under you silently.

Two failure modes recently proved how silent this gets:

1. **The auth check passed via the wrong key.** Step 7's `ssh -T github.com` lacked
   `-F /dev/null`, so `~/.ssh/config`'s additive `Host *` `IdentityFile` left the
   human laptop key as a candidate (`IdentitiesOnly=yes` does not drop
   config-supplied identities, only extra agent-offered ones). ssh offered the
   laptop key first and the server accepted it. Because both keys live on the same
   GitHub account, the `Hi <user>!` greeting was identical, so the check went green
   while never exercising the agent key. It would pass even for a broken or
   unregistered agent key. This is the same leak [ADR 0031](0031-role-scoped-agent-git-identity.md)'s
   live `sshCommand` fix already addressed; the verifier hadn't caught up.

2. **The key authenticated but was not authorized for an org's SAML SSO.** A key
   can authenticate to github.com yet still be rejected for org-owned repos until
   it is explicitly authorized for that org (a separate, per-org, browser-only
   grant, not exposed via `gh` or the API). The work agent key was authorized for
   one org but not another; every existing check passed, and the only symptom was
   agent git operations failing against the unauthorized org at runtime.

`claudeconfig.sh` already generates the role's `GIT_CONFIG_GLOBAL`, which is where
the agent git identity is wired in per [ADR 0031](0031-role-scoped-agent-git-identity.md).
It is the natural place to also confirm the identity it just wired actually works
end to end, instead of leaving that to a command nobody runs.

## Decision

After its apply phases, `claudeconfig.sh` validates the active role's agent SSH
identity by delegating to `bin/check-agent-ssh-key`, and **fails loud** (exits
non-zero) if validation fails. Specifics:

- The agent email is read from the role's gitconfig include
  (`home/.gitconfig.d/claude-agent-$ROLE` `user.email`), so there is one source of
  truth and no per-role email mapping to drift.
- Apply runs first, so a validation failure never leaves config half-written; only
  the exit code reflects validation.
- Roles with no agent include (e.g. `base`) are a no-op.
- `bin/check-agent-ssh-key` was hardened to make validation trustworthy: step 7
  now forces `-F /dev/null` and asserts the fingerprint the server accepted equals
  this key's, and a per-org SAML SSO probe was added (work role only) that
  `git ls-remote`s a canary repo per org and detects the "enabled or enforced SAML
  SSO" rejection.

### Escape hatch

`--skip-ssh-check` (or `SKIP_SSH_CHECK=1`) skips only the validation, leaving apply
intact. This exists because the validation depends on external state that is not
always reachable or ready:

- On a fresh machine, `claudeconfig.sh` runs before the key has been registered and
  SSO-authorized on GitHub. `bin/setup-agent-ssh-key` step 4 uses `--skip-ssh-check`
  for exactly this reason.
- Offline, the network and `gh` checks cannot run.

### Why hard-fail here when ADR 0036 chose warn-not-fail

[ADR 0036](0036-fail-loud-role-resolution.md) deliberately warns rather than
exits for a missing role file, because a missing role file degrades to a still-usable
`settings.json` generated from base plus stacks: a local, recoverable condition.

A broken agent identity is different in kind. It is external state (GitHub key
registration, the per-org SSO grant) that the user has to go fix, and when it is
wrong, agent git operations fail later in confusing ways far from the cause. That is
precisely the silent-failure class ADR 0036 set out to kill. Surfacing it as a
warning would get scrolled past and reproduce the same weeks-later mystery. The
hard-fail makes it un-ignorable; the `--skip-ssh-check` escape hatch preserves the
recoverable path for the legitimate cases (offline, mid-setup) without weakening the
default.

## Consequences

### Positive

- The agent identity `claudeconfig.sh` wires is confirmed working at config time,
  not discovered broken mid-session.
- Both failure modes above (wrong-key false pass, missing SSO authorization) can no
  longer ride along silently.
- SSO authorization, a manual browser-only step that is easy to forget, is now
  enforced for the work role on every validated run.

### Negative

- Couples a previously offline, deterministic config apply to network reachability,
  `gh` authentication, and GitHub-side state by default. The validation needs `gh`
  token scopes (`user:email`, `read:public_key`, `read:ssh_signing_key`) and adds
  a few seconds of network round-trips to a validated run.
- Fresh-machine setup and offline runs must pass `--skip-ssh-check`. The guard makes
  the right path obvious, but it is one more thing to know.
- Only `claudeconfig.sh` enforces this. Other role-keyed setup steps still have
  their own behavior and are not unified under one validation mechanism.
