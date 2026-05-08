#!/bin/bash
# Update dotfile symlinks from workspace/dotfiles to gt/repos/dotfiles/worktrees/main

set -e

OLD_BASE="$HOME/workspace/dotfiles"
NEW_BASE="$HOME/gt/repos/dotfiles/worktrees/main"

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "=== DRY RUN MODE ==="
fi

# Find symlinks pointing to old location (excluding backup directories)
find_symlinks() {
  find "$HOME" -maxdepth 2 -type l 2> /dev/null | while read link; do
    # Skip backup directories
    if echo "$link" | grep -q "\.backup\."; then
      continue
    fi

    target=$(readlink "$link" 2> /dev/null)
    if echo "$target" | grep -q "workspace/dotfiles"; then
      echo "$link"
    fi
  done
}

update_symlink() {
  local link="$1"
  local old_target=$(readlink "$link")
  local new_target=$(echo "$old_target" | sed 's|workspace/dotfiles|gt/repos/dotfiles/worktrees/main|')

  # Verify new target exists
  if [[ ! -e "$new_target" ]]; then
    echo "WARNING: Target does not exist: $new_target"
    echo "  Skipping: $link"
    return 1
  fi

  if $DRY_RUN; then
    echo "Would update: $link"
    echo "  From: $old_target"
    echo "  To:   $new_target"
  else
    rm "$link"
    ln -s "$new_target" "$link"
    echo "Updated: $link -> $new_target"
  fi
}

echo "Finding symlinks pointing to $OLD_BASE..."
echo ""

symlinks=$(find_symlinks)
count=$(echo "$symlinks" | grep -c . || echo 0)

echo "Found $count symlinks to update"
echo ""

if [[ "$count" -eq 0 ]]; then
  echo "Nothing to do!"
  exit 0
fi

for link in $symlinks; do
  update_symlink "$link" || true
done

echo ""
if $DRY_RUN; then
  echo "Run without --dry-run to apply changes"
else
  echo "Done! Symlinks updated."
fi
