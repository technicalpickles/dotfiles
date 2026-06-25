# 34. Local SSH allowed signers for commit verification

Date: 2026-06-12

## Status

Accepted

## Context

Commits are signed with SSH keys (`gpg.format = ssh`, see
[ADR 31](0031-role-scoped-agent-git-identity.md)). Signing only needs the
private key, so it works with no extra config. Verification is different.

Unlike GPG, SSH signing has no keyservers or web of trust. A signature only
proves "some key signed this blob"; git can't map that key back to an identity
on its own. To verify, git needs an allowed-signers file that lists which
public keys it should trust for which committer emails. Without it,
`git log --show-signature` and `git verify-commit` fail with:

```
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
```

So locally, every signed commit shows as unverified, including the user's own.
GitHub is unaffected: it verifies server-side against the keys enrolled on the
account and shows the Verified badge regardless. The gap is purely local
verification.

## Decision

Manage a dotfiles-tracked allowed-signers file at
`home/.gitconfig.d/allowed_signers` (surfaced as `~/.gitconfig.d/allowed_signers`
via the symlinked `~/.gitconfig.d` directory) and point
`gpg.ssh.allowedSignersFile` at it from the `signing` fragment.

Because the `signing` fragment is included by the generated `~/.gitconfig.local`
and the agent gitconfig (`claude-agent-<role>`) `[include]`s `~/.gitconfig`, both
the human and agent identities inherit the setting from one place.

The file lists one line per identity (`<email> <keytype> <key-blob>`):

- `joshua.nichols@gmail.com` -- personal human (1Password-managed key)
- `joshua.nichols+personal-agent@gmail.com` -- personal agent (ADR 31)

It is a plain data file, not a gitconfig fragment, and the dir is included
per-file (not globbed), so it is never parsed as config. Public keys are safe
to commit; the email is already present in `home-identity`.

### Why a single fleet-wide file rather than role-scoped

Unlike the 1Password agent allowlist ([ADR 33](0033-1password-ssh-agent-allowlist.md)),
allowed-signers is additive: listing a key that never signs anything on this
host costs nothing. The same repo's history can contain commits from any role's
identity (e.g. a personal laptop checking out a branch with work-agent commits),
so one file listing every identity gives the most complete local verification.
Work-role identities (`josh.nichols+agent@gusto.com` and the work human key)
are appended to the same file when that role's keys are available.

## Consequences

### Positive

- `git log --show-signature` / `verify-commit` confirm the user's own signed
  commits locally (`Good "git" signature for <email>`), no GitHub round-trip.
- One setting in the `signing` fragment covers both human and agent identities.
- No effect on signing, on the GitHub Verified badge, or on any enforcement;
  git never blocks a commit, push, or merge based on this file.

### Negative

- The file is a second copy of public keys that must stay in sync with what is
  enrolled on GitHub. Rotate a key and forget to update here, and local verify
  breaks while GitHub keeps working, a confusing state to debug.
- Until work-role identities are added, work-agent commits in shared history
  verify as `U` (good signature, `No principal matched`), not `G`.
- GPG-signed commits (e.g. GitHub PR-merge commits, signed with GitHub's RSA
  key) still show as `E` under SSH verification; allowed-signers only covers SSH
  signatures.

## Links

- Refines [ADR 31](0031-role-scoped-agent-git-identity.md) (agent SSH signing)
- Related [ADR 30](0030-ssh-keychain-loading-at-login.md) (silent key load)
