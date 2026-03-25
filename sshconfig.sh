#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source "$DIR/functions.sh"

echo "🔑 setting up ~/.ssh/config"

mkdir -p ~/.ssh/config.d
chmod 700 ~/.ssh/config.d

# Symlink versioned fragments
for fragment in "$DIR/ssh/config.d/"*; do
  basename=$(basename "$fragment")
  link "ssh/config.d/$basename" "$HOME/.ssh/config.d/$basename"
done

# Generate colima fragment if colima is installed
if command_available colima; then
  echo "  → enabling colima SSH config"
  echo "Include ~/.colima/ssh_config" > ~/.ssh/config.d/colima
fi

# Ensure ~/.ssh/config starts with Include
include_line="Include ~/.ssh/config.d/*"
if [ ! -f ~/.ssh/config ]; then
  echo "$include_line" > ~/.ssh/config
  chmod 600 ~/.ssh/config
  echo "  → created ~/.ssh/config with Include"
elif ! grep -qF "$include_line" ~/.ssh/config; then
  tmp=$(mktemp)
  {
    echo "$include_line"
    echo
    cat ~/.ssh/config
  } > "$tmp"
  mv "$tmp" ~/.ssh/config
  chmod 600 ~/.ssh/config
  echo "  → prepended Include to ~/.ssh/config"
else
  echo "  → ~/.ssh/config already has Include"
fi
