# 30. SSH Keychain Loading at Login

Date: 2026-04-13

## Status

Accepted

## Context

### The Prehistory of SSH Identity Management on macOS

macOS has had a complicated relationship with SSH keys over the years, and each era brought its own set of "just run this" advice.

**The Old Days (pre-Sierra):** macOS's SSH agent was tightly integrated with Keychain. You'd `ssh-add -K` your key once, and the system would load it from Keychain on every login automatically. It Just Worked, and you never thought about it.

**macOS Sierra (2016):** Apple changed the default behavior. SSH keys stored in Keychain were no longer automatically loaded into the agent at login. The community scrambled. The fix was two `~/.ssh/config` options:

```
Host *
    AddKeysToAgent yes
    UseKeychain yes
```

`UseKeychain yes` tells SSH to store/retrieve passphrases from Keychain. `AddKeysToAgent yes` adds the key to the running agent after first use. But there's a gap: after a reboot, the agent is empty. The first SSH operation triggers a passphrase prompt (or Keychain dialog), and only then does the key get added for the rest of the session.

**The `--apple-load-keychain` flag:** Apple added `ssh-add --apple-load-keychain` (renamed from the deprecated `-A` flag) to explicitly load all Keychain-stored identities into the agent. Running this once after login fills the gap. The question is where to put it.

### Our Setup

This dotfiles repo has a few SSH-related pieces:

- `~/.ssh/config` sets `AddKeysToAgent yes`, `UseKeychain yes`, and `IdentityFile ~/.ssh/id_ed25519`
- `ssh/config.d/auth` configures 1Password's IdentityAgent for the `Host *` scope (via ADR 0026's fragment system)
- `install.sh` runs `ssh-add --apple-load-keychain` during initial setup, but that's a one-time event
- The `danhper/fish-ssh-agent` Fisher plugin manages the SSH agent process, starting one if needed and persisting it across shell sessions via `~/.ssh/environment`

The symptom: after a reboot, the first `git push` prompts for the SSH key passphrase. Not a showstopper, but annoying enough to fix.

### Why Not a LaunchAgent?

The first attempt was a LaunchAgent (`com.technicalpickles.ssh-load-keychain.plist`). It ran successfully at login, and the logs confirmed "Identity added." But `ssh-add -l` in a terminal showed no identities.

The reason: `fish-ssh-agent` runs its own SSH agent with a custom socket (`~/.ssh/agent/`), not the system's default agent. The LaunchAgent loaded keys into the system agent, but all terminal sessions talk to fish-ssh-agent's socket. Two agents, two identity stores, zero overlap.

## Decision

Load SSH keys from Keychain via a fish shell `conf.d` snippet that runs after the fish-ssh-agent plugin starts.

### Implementation

**`config/fish/conf.d/ssh-keychain.fish`:**

```fish
if test (uname) = Darwin
    ssh-add --apple-load-keychain 2>/dev/null
end
```

This works because:

1. Fish conf.d files load alphabetically: `fish-ssh-agent.fish` (f) runs before `ssh-keychain.fish` (s), so the agent socket exists when we load keys
2. The `uname` guard makes it macOS-only (no-op on Linux, Codespaces, etc.)
3. `2>/dev/null` suppresses the "Identity added" stderr output on every new shell
4. The command is idempotent. Adding an already-loaded key is a no-op.

### Incidental Fix: fish.sh Symlink Ordering

While implementing this, we discovered two bugs in `fish.sh`:

1. **Missing `DIR` fallback:** `fish.sh` relied on `$DIR` being exported from `install.sh`. Running `./fish.sh` standalone left `DIR` empty, so the conf.d symlink loop resolved to `/config/fish/conf.d/*` and matched nothing. Fixed by adding `DIR="${DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"`.

2. **Symlink/Fisher race:** The conf.d symlink loop ran _before_ `fisher update`. Fisher's install phase recreates its managed files in conf.d, which could blow away freshly-created symlinks. Fixed by splitting the symlink block: `config.fish` and `fish_plugins` are symlinked before fisher (it needs them), while conf.d and functions are symlinked after.

### Alternatives Considered

1. **LaunchAgent**: Runs at login before any terminal, which is ideal timing. But our fish-managed SSH agent doesn't exist yet at that point. The keys would load into the wrong agent.

2. **mise task/hook**: Per-project, not system-wide. Wrong scope for something that should happen once at login.

3. **Modify fish-ssh-agent plugin**: Could fork it to add keychain loading. But modifying upstream plugins means maintaining a fork, and a one-line conf.d snippet does the same job.

## Consequences

### Positive

- SSH keys are available immediately in every new shell after reboot, no passphrase prompts
- macOS-only by design (the `uname` guard), so it's harmless on other platforms
- `fish.sh` now works correctly when run standalone, not just via `install.sh`
- New conf.d files added to dotfiles will survive `fisher update` going forward

### Negative

- `ssh-add --apple-load-keychain` runs on every new shell, not just the first after reboot. It's fast and idempotent, but it's technically redundant work after the first shell.
- The alphabetical ordering dependency (`f` before `s`) is implicit. If the fish-ssh-agent plugin were renamed, this could break. Acceptable risk given the plugin hasn't changed names in years.
