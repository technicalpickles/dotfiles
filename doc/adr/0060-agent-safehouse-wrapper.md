# 60. agent-safehouse wrapper for sandboxed agent CLIs

Date: 2026-10-14

## Status

Accepted

## Context

[agent-safehouse](https://github.com/eugene1g/agent-safehouse) wraps a command
in a macOS Seatbelt profile with built-in profiles per agent (pi, claude, codex,
...). Running pi under it on the work machine turned up several things its
defaults don't cover for this setup:

- **Node's PATH walk stops at the first EPERM directory.** `sh` skips a denied
  PATH entry; libuv's execvp gives up. `~/.pickles/bin` (a symlink into this
  repo) and Gusto's `/pkg/env/global/bin` both come before `/opt/homebrew/bin`,
  so every bare-name spawn from pi failed: rg/fd detection (pi then tried to
  download them and `tar` failed too) and `open` for MCP OAuth sign-in.
- **Symlinks need the link granted, not just the target.** `~/.pickles`,
  `~/.gitconfig` and `~/.gitconfig.d` all point into this repo. Safehouse's env
  grants (`SAFEHOUSE_ADD_DIRS*`) resolve symlinks, so they can't express that.
  It takes a `.sb` rule.
- **No global config.** Safehouse loads only a per-workdir `.safehouse` (after
  trust) and a few env vars. There's no env var for `--append-profile` or
  `--enable`.
- **Safehouse strips the environment.** `GIT_CONFIG_GLOBAL=claude-agent-<role>`
  ([ADR 0031](0031-role-scoped-agent-git-identity.md)) never reached pi, so git
  fell back to the personal signing key, which is in `~/.ssh` and denied.
  Passing the interactive `SSH_AUTH_SOCK` through would fix signing but expose
  the personal key held in that agent.

## Decision

`bin/safe` wraps `safehouse` and is the supported way to run agent CLIs under
it (`safe pi`). It:

- appends `config/agent-safehouse/common.sb`, then `role-$DOTPICKLES_ROLE.sb`
  when one exists. Role rules come last so their denies win.
- enables `clipboard`, `keychain`, and `launch-services`.
- starts a **dedicated ssh-agent** at `~/.ssh/agent/safehouse.sock`, fills it
  with `bin/load-agent-ssh-keys` (Keychain passphrase per
  [ADR 0030](0030-ssh-keychain-loading-at-login.md), skipping keys Automic Vault
  serves per [ADR 0059](0059-automic-vault-for-git-signing-and-agent-ssh.md)),
  and passes only that socket plus `GIT_CONFIG_GLOBAL=claude-agent-<role>` into
  the sandbox. Commits inside the sandbox sign as the agent, and the personal key
  never becomes reachable.

The split between files follows role, not convenience:

- `common.sb`: dotfiles' own symlink literals, agent `.pub` files and the
  dedicated socket, the plannotator pi extension, and mcporter's `~/.mcporter`
  (vault and caches; its `mcporter.json[c]` config stays write-denied, since it
  names commands that run unsandboxed later).
- `role-work.sb`: everything Gusto- or pickleton-specific: `~/pickleton`
  read/write, pickletown config and dolt info file, `/pkg`, and the dotslash
  cache for Gusto's managed pi.
- `role-home.sb`: read access to the dotfiles checkout, which is where the
  symlinks point on home machines.

`safehouse` itself installs through mise's github backend (macOS only).

## Consequences

- **Escape guard.** On work machines `role-work.sb` makes `~/pickleton`
  writable, and that reaches files that run outside the sandbox later. This
  repo's `main` worktree is the target of `~/.pickles`, `~/.gitconfig*`, shell
  rc files and `~/.config/*`, including this policy and `bin/safe`. And every
  repo's git hooks and config run on the next unsandboxed `git`. `role-work.sb`
  denies writes to the dotfiles `main` worktree, and to `.git/hooks`,
  `.git/config` and `bare.git` hooks/config anywhere under `~/pickleton`, the
  same paths Claude Code hardcodes. Edit dotfiles from another worktree and
  merge. This is an interim deny list, not a full model. Other execute-later
  paths (mise tasks, lefthook config, LaunchAgent sources, ...) aren't covered
  yet, and Claude Code launched from the pt root has the same exposure.
- Home role adds `role-home.sb`: a read-only grant on
  `~/github.com/technicalpickles/dotfiles`, the target of `~/.pickles` and
  `~/.gitconfig*` there. Without it `git config` couldn't read
  `claude-agent-home` and `~/.pickles/bin` was EPERM. Read-only, since write
  access would reach the same execute-later files the work escape guard covers.
- Signing on home is still open. Where Automic Vault serves the agent key,
  `load-agent-ssh-keys` skips it, so the dedicated agent has nothing to sign
  with (`ssh-add -l` reports no identities). Signing inside the sandbox on an AV
  machine would need `av-gpg` reachable from the sandbox. Not done.
- `--enable=clipboard` lets sandboxed code read the clipboard.
- `--enable=keychain` lets `gh` read its token from the Keychain (`gh auth status` reports it invalid without this), but sandboxed code can read every Keychain item the user owns. Accepted tradeoff; a narrower option is a dedicated token passed via `--env-pass`.
- `--enable=launch-services` lets `open` work (MCP OAuth sign-in, plannotator), but anything it launches runs outside the sandbox with full privileges. Accepted tradeoff: this is a sandbox escape hatch (e.g. `open -a Terminal`), and the escape guard in `role-work.sb` does not cover it.
- No Linux story; safehouse is Seatbelt-only.
