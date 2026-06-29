# 40. claude-code-remote role for Claude Code on the web

Date: 2026-06-28

## Status

Accepted

## Context

The role system (`home`/`work`/`container`) assumes a macOS or local-container
machine: a dotfiles-managed sandbox with macOS hosts/paths, an agent SSH identity
wired via `GIT_CONFIG_GLOBAL`, and `claudeconfig.sh` validating that key. None of
that fits Claude Code on the web (cloud): the container is already isolated
(`IS_SANDBOX=yes`), git auth/push go through the GitHub integration rather than an
SSH key, and the macOS sandbox entries point at paths that don't exist on the
Linux runner. The cloud environment is detectable via `CLAUDE_CODE_REMOTE=true`.

While adding this, pre-existing role drift surfaced and was worth fixing in the
same pass:

- `claudeconfig.sh` still defaulted `DOTPICKLES_ROLE` to `personal`, while the
  shells emit `home` and there was no `home.jsonc` (the file was `personal.jsonc`).
- `gitconfig.sh` branched on `personal)` with `*) exit 1`, so it errored on `home`,
  `container`, and any new role.
- `container` was a canonical role with no `container.jsonc` (tripping the
  fail-loud guard from ADR 0036), and container detection lived only in
  `home/.zshenv`, not `install.sh` or the fish copy.

## Decision

Add `claude-code-remote` as a canonical role.

- Detection (precedence `claude-code-remote` -> `container` -> `work` -> `home`;
  the claude check wins because cloud is also a container) added to all three
  shells: `install.sh`, `config/fish/conf.d/dotpickles-role.fish`, `home/.zshenv`.
- New `claude/roles/claude-code-remote.jsonc` sets `sandbox.enabled = false` (which
  also makes the macOS-only sandbox arrays from stacks inert) and declares no agent
  identity, so `claudeconfig.sh`'s SSH validation self-skips.
- Cloud bootstrap is `claudeconfig.sh` standalone (it is already not part of
  `install.sh`), set as the environment's setup command. Nothing else from
  `install.sh` is run (brew/macOS/ssh/1Password/tmux/fish would duplicate what the
  cloud runner already provisions).

Cleanup folded in: default `personal` -> `home`; rename `personal.jsonc` ->
`home.jsonc` (the agent _identity_ keeps the `personal-agent` name per ADR 0035,
only the file/role name changes); add a placeholder `container.jsonc`; rework the
`gitconfig.sh` case to `home | container | claude-code-remote)` (basic personal
identity; the 1Password signing block is macOS-guarded, so it's a no-op on Linux).

## Consequences

### Positive

- A clean, lean cloud config: no sandbox fighting the runner, no SSH validation
  that can't pass, no macOS paths.
- `DOTPICKLES_ROLE=home` finally loads a role file; `gitconfig.sh` no longer errors
  on `home`/`container`; detection is consistent across all three shells.

### Negative

- The role name `claude-code-remote` is long and shows up verbatim in the prompt
  during cloud sessions.
- More role files and case branches to keep in sync (mitigated by the canonical
  list and the fail-loud guard).
