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

### link() case flow

Split case 1 into two branches:

```
target doesn't exist          -> create symlink
target is real file/dir       -> backup-and-replace OR prompt (NEW)
target is symlink, wrong dest -> prompt to overwrite (unchanged)
target is symlink, correct    -> no-op (unchanged)
```

### Real file/dir behavior

Controlled by `DOTPICKLES_BACKUP` env var:

- **Not set (default, interactive):** prompt the user. "~/.config/foo exists as directory (not a symlink). Replace with symlink to config/foo? [y/N]". On "y", move target to backup, then symlink.
- **Set to 1 (`--backup` flag):** automatically move target to backup, then symlink. No prompt.

### Backup naming

Format: `target.backup.YYYYMMDD-HHMMSS` in the same parent directory.

Example: `~/.config/ccstatusline.backup.20260325-143022`

If that path already exists, append a counter: `target.backup.20260325-143022-2`, then `-3`, etc.

### Preventing nested symlinks

The new flow does `mv` first, then `ln -s` (without `-F` or `-f`, since target is gone). This structurally prevents the nested symlink bug because the target path doesn't exist when `ln` runs.

The "target doesn't exist" branch should also use plain `ln -s` (no `-Ff`) for the same reason. When the target doesn't exist, those flags are unnecessary, and removing them means `ln` will error loudly if something unexpected is there, rather than silently forcing.

The "wrong symlink" branch retains `ln -Ff -s` because the target is a known symlink, not a directory. `-F` is safe here (it replaces the symlink itself) and needed to avoid the prompt-then-fail pattern.

### Script-level --backup flag

`symlinks.sh` and `install.sh` parse `--backup` and export `DOTPICKLES_BACKUP=1`. The `link()` function reads this env var. No changes to `link_directory_contents`, `find_targets`, or callers.

### Non-interactive shells

When stdin is not a terminal (piped input, CI), the interactive prompts would hang or fail silently. In non-interactive contexts, `link()` defaults to skipping (no replacement) and prints a warning. Use `--backup` for unattended runs.

### Target implementation

```bash
link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"
  local source="${DIR}/${linkable}"

  if [ -L "$target" ]; then
    # Target is a symlink
    if [ "$(readlink "$target")" = "$source" ]; then
      echo "🔗 $display_target -> already linked"
    else
      echo "🔗 $display_target -> already linked to $(readlink "$target")"
      read -p "Overwrite it to link to ${source}? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔗 $display_target -> linking from $linkable"
        ln -Ff -s "$source" "$target"
      fi
    fi
  elif [ -e "$target" ]; then
    # Target exists as real file or directory
    local filetype="file"
    [ -d "$target" ] && filetype="directory"

    if [ "${DOTPICKLES_BACKUP:-}" = "1" ]; then
      local backup
      backup="$(backup_path "$target")"
      echo "🔗 $display_target -> backing up $filetype to ${backup##*/}"
      mv "$target" "$backup"
      echo "🔗 $display_target -> linking from $linkable"
      ln -s "$source" "$target"
    elif [ -t 0 ]; then
      echo "🔗 $display_target -> exists as $filetype (not a symlink)"
      read -p "Replace with symlink to ${linkable}? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        local backup
        backup="$(backup_path "$target")"
        echo "🔗 $display_target -> backing up to ${backup##*/}"
        mv "$target" "$backup"
        echo "🔗 $display_target -> linking from $linkable"
        ln -s "$source" "$target"
      fi
    else
      echo "⚠ $display_target exists as $filetype, skipping (use --backup for unattended)"
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

- `functions.sh`: `link()` function, roughly 10-15 lines of new logic
- `symlinks.sh`: parse `--backup`, export env var
- `install.sh`: parse `--backup`, export env var

## Out of scope

- Refactoring `claudeconfig.sh` to use the shared `link()` (separate bean)
- Changes to the skip list or `link_directory_contents`

## Verification

1. Run `symlinks.sh` with a real directory at a target path, confirm it prompts
2. Run `symlinks.sh --backup` with a real directory, confirm it backs up and replaces
3. Run `symlinks.sh` when everything is already correctly symlinked, confirm no-op
4. Confirm no nested symlinks are created in any scenario
