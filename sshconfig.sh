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

# Symlink role-specific 1Password SSH agent allowlist.
# 1Password reads ~/.config/1Password/ssh/agent.toml (capital P). Without an
# allowlist, every key in the unlocked vault is offered to ssh on every
# connection. config/1password/agent.toml.<role> defines which items are
# offered. See ADR 0033.
op_role="${DOTPICKLES_ROLE:-personal}"
op_source="config/1password/agent.toml.${op_role}"
op_target="$HOME/.config/1Password/ssh/agent.toml"
op_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ -S "$op_socket" ]; then
  if [ -f "$DIR/$op_source" ]; then
    echo "🔑 setting up 1Password SSH agent allowlist (role: $op_role)"
    mkdir -p "$HOME/.config/1Password/ssh"
    link "$op_source" "$op_target"
  else
    echo "🔑 no 1Password agent.toml for role '$op_role', skipping (expected $op_source)"
  fi
else
  echo "🔑 1Password agent socket not found, skipping agent.toml setup"
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
