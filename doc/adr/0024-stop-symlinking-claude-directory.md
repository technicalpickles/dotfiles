# 24. Stop Symlinking ~/.claude Directory

Date: 2026-03-17

## Status

Accepted (partially supersedes [ADR 0013](0013-claude-code-configuration-management.md))

## Context

The previous setup (from ADR 0013) symlinked the entire `~/.claude` directory into the dotfiles repo via `home/.claude/`. This meant all of Claude Code's runtime state (history, sessions, plugins, cache, shell snapshots, todos) lived physically inside the dotfiles git worktree.

Problems encountered:

1. **Git noise**: The gitignore had to exclude `home/.claude/*` with a carve-out for tracked files. Any new runtime artifact risked appearing in `git status`.
2. **Session fragility**: Running `claudeconfig.sh` or `install.sh` while Claude Code sessions were active could disrupt state, since the symlink target was inside a worktree that might get manipulated.
3. **Worktree complications**: The symlink target lived inside a specific worktree (`repos/dotfiles/worktrees/main/home/.claude/`), tying runtime state to a particular checkout.
4. **Plugin cache bloat**: Full Python venvs for plugins accumulated in the worktree directory, adding unnecessary weight to the repo's working tree.

Only two things in `~/.claude` actually needed version control: `CLAUDE.md` (global instructions) and `skills/permissions-manager/` (a tracked skill).

## Decision

Make `~/.claude` a real directory. Symlink only the managed files into it:

- `claude/CLAUDE.md` -> `~/.claude/CLAUDE.md`
- `claude/skills/permissions-manager/` -> `~/.claude/skills/permissions-manager/`

`claudeconfig.sh` gains a `setup_claude_directory()` function that:
1. Creates `~/.claude/` and `~/.claude/skills/` if missing
2. Symlinks managed files (with safety checks for existing files/directories)

The `home/.claude/` directory is removed from the repo entirely. Settings generation (`claudeconfig.sh`) continues to write `~/.claude/settings.json` directly, unchanged from ADR 0013.

A one-time migration script (`scripts/migrate-claude-config.sh`) handles the transition:
1. Verifies `~/.claude` is a symlink
2. Replaces it with a real directory (same-filesystem `mv`, instant)
3. Cleans up files that get re-symlinked
4. Runs `claudeconfig.sh`

### What stays the same from ADR 0013

- Role-based settings/permissions merging
- `claudeconfig.sh` as the generation script
- Modular permission files in `claude/`
- `install.sh` integration

### What changes

| Before | After |
|--------|-------|
| `~/.claude` = symlink to `home/.claude/` | `~/.claude` = real directory |
| `home/.claude/CLAUDE.md` tracked in git | `claude/CLAUDE.md` tracked, symlinked in |
| `home/.claude/skills/permissions-manager/` tracked | `claude/skills/permissions-manager/` tracked, symlinked in |
| Runtime state in dotfiles worktree | Runtime state in `~/.claude/` (outside repo) |

### Alternatives Considered

1. **Selective gitignore with more carve-outs**: Keep the symlink, refine ignore rules.
   - Rejected: Increasingly fragile as Claude Code adds new runtime artifacts.

2. **Copy instead of symlink for managed files**: `claudeconfig.sh` copies CLAUDE.md instead of symlinking.
   - Rejected: Edits to `~/.claude/CLAUDE.md` wouldn't flow back to the repo.

## Consequences

### Positive

- **Clean separation**: Runtime state lives outside the repo entirely
- **No git noise**: No need for `home/.claude/*` gitignore rules
- **Session safety**: Claude Code sessions unaffected by dotfiles operations
- **Fresh installs work**: `claudeconfig.sh` creates the directory and symlinks from scratch

### Negative

- **One-time migration required**: Existing setups need to run the migration script
- **Two symlink targets**: CLAUDE.md and permissions-manager are symlinked individually (minor complexity)
- **Skills not fully managed**: Other skills in `~/.claude/skills/` (code-review, gcal, etc.) are manually created symlinks, not tracked by dotfiles
