# 28. Safe Symlink Function

Date: 2026-03-25

## Status

Accepted

## Context

The `link()` function in `functions.sh` is used by `symlinks.sh` and `install.sh` to create symlinks from dotfiles source to their target locations (`~/`, `~/.config/`, etc.).

The original implementation had two problems:

1. **Silent data loss.** If the target was a real file or directory (not a symlink), `link()` used `ln -Ff -s` to silently replace it. Tools like ccstatusline create their own config directories at runtime with user customizations. Running `symlinks.sh` would nuke those without warning.

2. **Nested symlink bug.** If the target was an existing directory and `-F` didn't behave as expected, `ln -s source target/` would create a symlink *inside* the directory (e.g. `~/.config/fish/fish`) instead of replacing it. This is a well-known `ln` footgun.

The function also had no way to run non-interactively, making it unsuitable for CI or scripted installs.

## Decision

Rewrite `link()` with four explicit cases and two new helpers:

**Cases:**
- Target doesn't exist: create symlink (plain `ln -s`, no flags)
- Target is a correct symlink: no-op
- Target is a wrong symlink: prompt to repoint (or auto-repoint with `--yes`)
- Target is a real file or directory: prompt to backup and replace (or auto with `--yes`)

**Helpers:**
- `confirm()` centralizes prompt logic. Returns yes immediately in auto-yes mode, prompts interactively otherwise.
- `backup_path()` generates timestamped backup names (`target.backup.20260325-143022`) with collision counter.

**Interactivity modes:**
- Interactive (default): prompts for anything that isn't already correct
- Auto-yes (`--yes`/`-y`): auto-answers yes to all prompts, safe for scripts
- Non-interactive without `--yes`: script exits with error immediately

The nested symlink bug is prevented structurally: real files/dirs are `mv`'d out of the way before `ln -s` runs, so the target never exists when the symlink is created. The "doesn't exist" case uses plain `ln -s` without `-Ff` flags, so it will error loudly if something unexpected is at the path.

### Alternatives Considered

1. **Warn and skip (like claudeconfig.sh does)**
   - Simpler, no backup logic needed
   - Rejected: requires manual cleanup, annoying on repeated runs

2. **Separate safe_link() wrapper**
   - Leaves old link() for callers that want force behavior
   - Rejected: no callers want the old behavior, just adds confusion

## Consequences

### Positive

- Real files/directories are backed up before replacement, never silently lost
- Nested symlinks are structurally impossible
- `--yes` flag enables scripted/CI usage
- Non-interactive without `--yes` fails fast instead of silently doing nothing
- `confirm()` is reusable by other scripts (e.g. future claudeconfig.sh refactor)

### Negative

- Backup files accumulate in `~/.config/` and `~/` over time (manual cleanup needed)
- Interactive mode requires a terminal, which changes behavior for anyone piping to the script
