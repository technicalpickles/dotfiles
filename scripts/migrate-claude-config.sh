#!/usr/bin/env bash
set -e

# One-time migration: replace ~/.claude symlink with a real directory.
#
# Prerequisites:
#   1. Stop all Claude Code sessions gracefully (note --resume commands)
#   2. Run this script from the dotfiles repo root
#
# What it does:
#   1. Verifies ~/.claude is a symlink (no-op if already a real directory)
#   2. Moves the symlink target's contents to a real ~/.claude directory
#   3. Removes stale files that will be re-symlinked
#   4. Runs claudeconfig.sh to set up symlinks and regenerate settings

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

claude_path="$HOME/.claude"

if [ ! -L "$claude_path" ]; then
  echo "~/.claude is not a symlink. Nothing to migrate."
  echo "Run ./claudeconfig.sh to ensure symlinks and settings are up to date."
  exit 0
fi

target=$(readlink "$claude_path")
echo "~/.claude is a symlink to: $target"

# Sanity check: make sure the target exists and has content
if [ ! -d "$target" ]; then
  echo "Error: symlink target does not exist or is not a directory"
  exit 1
fi

echo ""
echo "This will:"
echo "  1. Remove the ~/.claude symlink"
echo "  2. Move contents from $target to ~/.claude (same filesystem, instant)"
echo "  3. Run claudeconfig.sh to recreate managed symlinks"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Replacing symlink with real directory..."
rm "$claude_path"
mv "$target" "$claude_path"

# Remove files that claudeconfig.sh will re-symlink
rm -f "$claude_path/CLAUDE.md"
rm -rf "$claude_path/skills/permissions-manager"

echo "Running claudeconfig.sh..."
"$DIR/claudeconfig.sh"

echo ""
echo "Migration complete. ~/.claude is now a real directory."
echo "Restart your Claude Code sessions."
