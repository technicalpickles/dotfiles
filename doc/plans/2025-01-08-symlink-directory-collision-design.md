# Fix Symlink Directory Collision in Dotfiles Installer

## Problem

When symlinking config directories (like `~/.config/fish`), the `link()` function in `functions.sh` fails silently if the target already exists as a **directory** (not a symlink).

### Current Behavior

The `link()` function checks:

```bash
if [ ! -L "$target" ]; then
    ln -Ff -s "$DIR/$linkable" "$target"
```

If `$target` is a regular directory (not a symlink), `[ ! -L "$target" ]` returns true, and `ln -Ff -s` creates the symlink **inside** the directory rather than replacing it.

### Observed Failure

In devcontainers with persistent home volumes:

1. Fish creates `~/.config/fish/` directory on first interactive shell
2. `setup-dotfiles` runs and calls `link_directory_contents config`
3. `link config/fish ~/.config/fish` is called
4. Since `~/.config/fish` exists as a directory, `ln -Ff -s` creates `~/.config/fish/fish` → `~/.dotfiles/config/fish`
5. Fish continues using the default `~/.config/fish/config.fish` instead of dotfiles config

Result: Fish config is not applied. User sees default fish prompt instead of starship.

### Why This Happens Now

Previously, dotfiles setup ran during Docker image build when `~/.config/fish` didn't exist. With persistent home volumes, the volume is mounted at `/home/vscode` **before** post-create runs, and fish may have already created its config directory.

## Solution

Modify `link()` to detect and handle existing directories that should be replaced with symlinks.

### Option A: Backup and Replace (Recommended)

```bash
link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"

  # Handle existing directory that's not a symlink
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    echo "🔗 $display_target → backing up existing directory"
    mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
  fi

  if [ ! -L "$target" ]; then
    echo "🔗 $display_target → linking from $linkable"
    ln -Ff -s "$DIR/$linkable" "$target"
  elif [ "$(readlink "$target")" != "${DIR}/${linkable}" ]; then
    echo "🔗 $display_target → already linked to $(readlink "${target}")"
    read -p "Overwrite it to link to ${DIR}/${linkable}? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "🔗 $display_target → linking from $linkable"
      ln -Ff -s "$DIR/$linkable" "$target"
    fi
  else
    echo "🔗 $display_target → already linked"
  fi
}
```

**Pros:**

- Safe: preserves any user modifications
- Recoverable: backup can be inspected/restored
- Works for both interactive and non-interactive (DOCKER_BUILD) contexts

**Cons:**

- Accumulates backup directories over time
- May preserve stale data unnecessarily

### Option B: Merge and Replace

For config directories specifically, merge contents before replacing:

```bash
link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"

  # Handle existing directory that's not a symlink
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    # Check if it's a default/empty directory we can safely remove
    local file_count
    file_count=$(find "$target" -type f | wc -l)
    if [ "$file_count" -eq 0 ]; then
      echo "🔗 $display_target → removing empty directory"
      rmdir "$target" 2> /dev/null || rm -rf "$target"
    else
      echo "🔗 $display_target → backing up directory with $file_count files"
      mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
    fi
  fi
  # ... rest unchanged
}
```

**Pros:**

- Only backs up when there's actual content
- Cleaner for empty default directories

**Cons:**

- More complex logic
- Risk of data loss if "empty" check is wrong

### Option C: Force Replace in Non-Interactive Mode

Only force replace during `DOCKER_BUILD=true` or non-interactive contexts:

```bash
link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"

  # In non-interactive mode, force replace existing directories
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    if [ -n "$DOCKER_BUILD" ] || [ ! -t 0 ]; then
      echo "🔗 $display_target → removing existing directory (non-interactive)"
      rm -rf "$target"
    else
      echo "⚠️  $display_target exists as directory, not symlink"
      read -p "Remove and replace with symlink? " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$target"
      else
        echo "   Skipping $display_target"
        return 0
      fi
    fi
  fi
  # ... rest unchanged
}
```

**Pros:**

- Prompts in interactive mode
- Automatic in build/CI contexts

**Cons:**

- Different behavior in different contexts
- May lose data without explicit consent in non-interactive

## Recommendation

**Option A (Backup and Replace)** is the safest choice. It:

- Never loses data
- Works consistently in all contexts
- Makes the change visible (user sees backup directory if they need it)
- Can be cleaned up manually or via a separate cleanup script

## Implementation

### Files to Modify

- `functions.sh`: Update `link()` function

### Testing

1. Create a test directory at a symlink target location
2. Run `./symlinks.sh`
3. Verify:
   - Original directory is backed up
   - Symlink is created correctly
   - Linked content is accessible

### Rollout

1. Test locally on macOS
2. Test in devcontainer (rebuild without persistent volume first)
3. Test in devcontainer with persistent volume (the problem case)
