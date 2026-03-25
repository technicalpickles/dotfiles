# Safe link() Function

Make `link()` in `functions.sh` safe when the target is a real file or directory, instead of silently replacing it.

## Problem

The `link()` function has three branches:

1. Target is not a symlink: replace with symlink via `ln -Ff -s`
2. Target is a symlink pointing to the wrong place: prompt to overwrite
3. Target is a symlink pointing to the right place: no-op

Case 1 treats "nothing exists" and "real directory with user content" identically. Tools like ccstatusline create their own config directories at runtime, and `link()` silently nukes them.

There's also a nested symlink bug: if `-F` doesn't behave as expected, `ln -s source target/` creates `target/basename(source)` inside the existing directory instead of replacing it (e.g. `~/.config/fish/fish`).

## Design

### Two modes: interactive and auto-yes

The `link()` function operates in two modes:

- **Interactive (default):** prompts the user before replacing anything that isn't already correct. Requires a terminal on stdin.
- **Auto-yes (`--yes` / `-y`):** auto-answers yes to all prompts. Safe for scripts and CI. Real files/dirs get backed up before replacement; wrong symlinks get repointed silently.

Controlled by the `DOTPICKLES_YES` env var (set by script-level `--yes`/`-y` flag).

**Non-interactive without `--yes` is an error.** If stdin is not a terminal and `DOTPICKLES_YES` is not set, the script exits immediately with a message like: `"Error: not running interactively. Use --yes/-y for unattended mode."` This prevents silently skipping everything and reporting success.

### link() case flow

```
target doesn't exist          -> create symlink
target is real file/dir       -> prompt OR auto-backup-and-replace (NEW)
target is symlink, wrong dest -> prompt OR auto-replace (UPDATED)
target is symlink, correct    -> no-op
```

All replacements of real files/dirs create a backup first, regardless of mode. Wrong symlinks don't need backups (no user data at risk).

### Backup naming

Format: `target.backup.YYYYMMDD-HHMMSS` in the same parent directory.

Example: `~/.config/ccstatusline.backup.20260325-143022`

If that path already exists, append a counter: `target.backup.20260325-143022-2`, then `-3`, etc.

### Preventing nested symlinks

The new flow does `mv` first, then `ln -s` (without `-F` or `-f`, since target is gone). This structurally prevents the nested symlink bug because the target path doesn't exist when `ln` runs.

The "target doesn't exist" branch should also use plain `ln -s` (no `-Ff`) for the same reason. When the target doesn't exist, those flags are unnecessary, and removing them means `ln` will error loudly if something unexpected is there, rather than silently forcing.

The "wrong symlink" branch retains `ln -Ff -s` because the target is a known symlink, not a directory. `-F` is safe here (it replaces the symlink itself) and needed to avoid the prompt-then-fail pattern.

### Script-level --yes flag and interactivity guard

`symlinks.sh` and `install.sh` parse `--yes`/`-y` and export `DOTPICKLES_YES=1`. After flag parsing, check interactivity:

```bash
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi
```

This guard lives in the scripts, not in `link()` or `confirm()`. The `confirm()` helper doesn't need a non-interactive branch at all since it will never be reached without a tty or `--yes`.

### Target implementation

```bash
# Ask a y/N question. Returns 0 for yes, 1 for no.
# In auto-yes mode, always returns 0. Scripts guard against
# non-interactive use at startup, so this always has a tty or --yes.
confirm() {
  local prompt="$1"
  if [ "${DOTPICKLES_YES:-}" = "1" ]; then
    return 0
  fi
  read -p "$prompt " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"
  local source="${DIR}/${linkable}"

  if [ -L "$target" ]; then
    # Target is a symlink
    if [ "$(readlink "$target")" = "$source" ]; then
      echo "🔗 $display_target -> already linked"
    elif confirm "🔗 $display_target -> linked to $(readlink "$target"). Repoint to ${linkable}?"; then
      echo "🔗 $display_target -> linking from $linkable"
      ln -Ff -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped (wrong symlink)"
    fi
  elif [ -e "$target" ]; then
    # Target exists as real file or directory
    local filetype="file"
    [ -d "$target" ] && filetype="directory"

    if confirm "🔗 $display_target -> exists as $filetype. Replace with symlink to ${linkable}?"; then
      local backup
      backup="$(backup_path "$target")"
      echo "🔗 $display_target -> backing up to ${backup##*/}"
      mv "$target" "$backup"
      echo "🔗 $display_target -> linking from $linkable"
      ln -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped ($filetype exists)"
    fi
  else
    # Target doesn't exist
    echo "🔗 $display_target -> linking from $linkable"
    ln -s "$source" "$target"
  fi
}

backup_path() {
  local target="$1"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup="${target}.backup.${timestamp}"
  local counter=2
  while [ -e "$backup" ]; do
    backup="${target}.backup.${timestamp}-${counter}"
    counter=$((counter + 1))
  done
  echo "$backup"
}
```

## Files changed

- `functions.sh`: `link()` rewritten, new `confirm()` and `backup_path()` helpers
- `symlinks.sh`: parse `--yes`/`-y`, export `DOTPICKLES_YES=1`
- `install.sh`: parse `--yes`/`-y`, export `DOTPICKLES_YES=1`

## Out of scope

- Refactoring `claudeconfig.sh` to use the shared `link()` (separate bean)
- Changes to the skip list or `link_directory_contents`

## Verification

1. Run `symlinks.sh` with a real directory at a target path, confirm it prompts
2. Run `symlinks.sh` with a wrong symlink, confirm it prompts
3. Run `symlinks.sh --yes` with a real directory, confirm it backs up and replaces
4. Run `symlinks.sh --yes` with a wrong symlink, confirm it repoints without backup
5. Run `symlinks.sh` when everything is already correctly symlinked, confirm no-op
6. Pipe input to `symlinks.sh` (non-interactive, no `--yes`), confirm it exits with error
7. Confirm no nested symlinks are created in any scenario
