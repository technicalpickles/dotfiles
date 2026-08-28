# 48. Agent-session SSH key override via Match exec

Date: 2026-08-22

## Status

Accepted

## Context

[ADR 0031](0031-role-scoped-agent-git-identity.md) solved the "1Password
requires interactive TouchID approval" problem for git-over-SSH by pointing
git's `core.sshCommand` at a dedicated, Keychain-loaded agent key
(`~/.ssh/agents/<role>/id_ed25519`), bypassing `~/.ssh/config` entirely with
`-F /dev/null`. That fix is scoped to git.

Plain `ssh <host>` from an agent session still resolves through
`~/.ssh/config`'s `Host *` block, which points at 1Password's `IdentityAgent`
(`ssh/config.d/auth`, [ADR 0033](0033-1password-ssh-agent-allowlist.md)).
1Password requires a TouchID/biometric prompt per connection, which an
unattended agent session can't satisfy -- the same class of problem ADR 0031
solved for git, showing up again for direct SSH (e.g. `ssh picklelab` to a
homelab host).

The Keychain-loaded agent key from ADR 0031/0030 is already sitting in
fish-ssh-agent, unlocked, with no per-use prompt. The question was how to get
plain `ssh` to prefer it during agent sessions, without maintaining a
`Host <name>` block per target host.

## Decision

Add `Match exec` blocks to `ssh/config.d/auth`, before the `Host *` block,
that key off two environment variables:

- `$CLAUDECODE` -- set to `1` by Claude Code in every session it spawns
- `$DOTPICKLES_ROLE` -- the existing role variable (`home`, `work`, ...)

```
Match exec "test -n \"$CLAUDECODE\" -a \"$DOTPICKLES_ROLE\" = home"
  IdentityFile ~/.ssh/agents/home/id_ed25519
  IdentityAgent SSH_AUTH_SOCK
  IdentitiesOnly yes

Match exec "test -n \"$CLAUDECODE\" -a \"$DOTPICKLES_ROLE\" = work"
  IdentityFile ~/.ssh/agents/work/id_ed25519
  IdentityAgent SSH_AUTH_SOCK
  IdentitiesOnly yes

Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

`Match exec` runs the test command with ssh's environment, so it sees the
same `$CLAUDECODE`/`$DOTPICKLES_ROLE` the calling shell has. `IdentityAgent
SSH_AUTH_SOCK` redirects to fish-ssh-agent's socket (the literal string
`SSH_AUTH_SOCK` is specially resolved by ssh to the env var's value), same
mechanism ADR 0031 uses for git.

This is host-agnostic: any host the agent key is authorized on (via that
host's `~/.ssh/authorized_keys`) works with zero per-host config. Outside an
agent session (`$CLAUDECODE` unset), `Host *` still routes through
1Password as before, so interactive use is unchanged.

### Alternatives Considered

1. **Per-host `Host <name>` blocks pointing at the agent key**

   - Pros: explicit, no reliance on `Match exec`/env var detection
   - Cons: requires editing `ssh/config.d/` (or the gitignored local
     `~/.ssh/config.d/hosts`) every time a new host needs agent access;
     doesn't generalize -- exactly the friction this ADR avoids
   - Rejected: doesn't scale, and the "agent session" condition is what
     actually determines which key should be offered, not the target host

2. **Extend git's `-F /dev/null` bypass pattern to a wrapper around `ssh`**
   - Pros: reuses proven git mechanism
   - Cons: would require aliasing/wrapping the `ssh` binary itself for every
     shell an agent spawns, more invasive than a config fragment
   - Rejected: `Match exec` achieves the same env-based branching natively

## Consequences

### Positive

- Any host reachable via the Keychain-loaded agent key works with zero
  per-host SSH config, as long as the key is authorized on that host
- Interactive shells are unaffected; only sessions with `$CLAUDECODE` set
  take the override path
- Consistent with the git-side mechanism from ADR 0031 (same key, same
  `IdentityAgent SSH_AUTH_SOCK` redirect)

### Negative

- Still requires manually authorizing the agent key's public half on each
  target host's `~/.ssh/authorized_keys` -- this ADR only changes which key
  ssh _offers_, not which hosts accept it
- Depends on `$CLAUDECODE` remaining Claude Code's session marker; if it's
  renamed or unset in some spawn path (e.g. a future non-shell tool
  invocation), the override silently falls back to 1Password (safe failure
  mode, but worth knowing)
- Only `home` and `work` roles are wired up; a new role needing this would
  need its own `Match exec` block

## Links

- Extends [ADR 0031](0031-role-scoped-agent-git-identity.md) (role-scoped
  agent git identity) from git-over-SSH to plain SSH
- Builds on [ADR 0030](0030-ssh-keychain-loading-at-login.md) (Keychain
  loading into fish-ssh-agent)
- Sits alongside [ADR 0033](0033-1password-ssh-agent-allowlist.md) (the
  `Host *` 1Password path this overrides during agent sessions)
