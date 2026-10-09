# 58. work-coder role for Coder workspaces

Date: 2026-10-09

## Status

Accepted

## Context

Work is piloting [Coder](https://coder.com) cloud development environments. A
workspace is a disposable Linux VM (Ubuntu 22.04, amd64, user `coder`) built
from an employer-managed Terraform template, and `coder dotfiles <repo>` clones
this repo and runs `install.sh` inside it. Coder sets `CODER=true` in the
workspace environment.

The first real run (2026-10-09) showed that none of the existing roles fit:

- Detection fell through to `home`: the hostname is the workspace name, not
  `josh-nichols-*`, and the VM isn't a container. So a work machine got the
  personal git identity and the personal agent identity.
- The template already owns git identity and commit signing. Its
  `git-commit-signing` module writes `~/.gitconfig` with a per-workspace SSH
  signing key at `~/.ssh/git-commit-signing/coder` and registers that key on
  GitHub. dotfiles' `~/.gitconfig` symlink replaced it. Under `work`,
  `gitconfig.sh` turned signing on but only sets a key when
  `~/.ssh/id_ed25519.pub` exists, so every commit failed.
- `claudeconfig.sh`'s agent SSH validation is macOS-only and exits 1, which
  aborts the whole install. `coder dotfiles` can't pass `--skip-ssh-check`.
- The `work` role declares `requiresPrivateOverlay`, and that overlay only
  exists on the laptop.
- Claude Code auth comes from the template's managed settings
  (`/etc/claude-code/managed-settings.d/`), which only set auth env vars.
  The sandbox and permissions come entirely from dotfiles, and the stacks'
  sandbox entries are macOS paths.

## Decision

Add `work-coder` as a canonical role.

- Detection: `CODER=true` → `work-coder`, checked after `claude-code-remote`
  and before `container` (a Coder workspace's devcontainer is also a
  container). Added to all three copies: `functions.sh`, `home/.zshenv`,
  `config/fish/conf.d/dotpickles-role.fish`. Added to `dotfiles-doctor`'s
  valid roles.
- `claude/roles/work-coder.jsonc`, modeled on `claude-code-remote`:
  - Sandbox disabled. The VM is already isolated and egress-filtered, and
    disabling it makes the stacks' macOS sandbox entries inert.
  - No agent identity (no `GIT_CONFIG_GLOBAL`). Claude commits as the
    workspace owner through the template's signing key, and
    `claudeconfig.sh`'s SSH validation self-skips.
  - No `requiresPrivateOverlay`. Employer-specific hostnames stay out of this
    public file.
  - A short `autoMode.environment` note that this is a disposable dev VM, not
    production.
- `gitconfig.sh` gets a `work-coder)` branch: the work identity, plus signing
  with `~/.ssh/git-commit-signing/coder` when it exists (signing stays off with
  a warning when it doesn't).

The name `work-coder` rather than `coder` keeps "work" in the prompt context
and leaves room for a personal Coder deployment later.

## Consequences

### Positive

- `coder dotfiles` lands the work identity, keeps commit signing working, and
  gets past the macOS-only SSH check without any env vars.
- Claude in the workspace runs without fighting a sandbox built for macOS.

### Negative

- One more role in the case branches and detection copies to keep in sync.
- Still not a complete Linux story. `fish.sh` hard-fails when fish isn't
  installed, oh-my-bash replaces the template's `~/.bashrc`, fish's PATH lacks
  `~/.local/bin`, and `core.fsmonitor` warns on Linux git. Those are tracked
  separately, not solved by this role.
