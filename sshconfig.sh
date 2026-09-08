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
op_role="${DOTPICKLES_ROLE:-home}"
op_source="config/1password/agent.toml.${op_role}"
op_target="$HOME/.config/1Password/ssh/agent.toml"
# Gate on 1Password being installed (its app container dir), not running. The
# agent socket only exists once 1Password is launched with the SSH agent
# enabled, which is usually false during install -- so gating on the socket
# silently skipped the allowlist on exactly the fresh-install runs that need
# it. 1Password reads agent.toml whenever it next starts, so the symlink is
# safe to create ahead of the agent coming up. See ADR 0033.
op_app_dir="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password"
if [ -d "$op_app_dir" ]; then
  if [ -f "$DIR/$op_source" ]; then
    echo "🔑 setting up 1Password SSH agent allowlist (role: $op_role)"
    mkdir -p "$HOME/.config/1Password/ssh"
    link "$op_source" "$op_target"
  else
    echo "🔑 no 1Password agent.toml for role '$op_role', skipping (expected $op_source)"
  fi
else
  echo "🔑 1Password not installed, skipping agent.toml setup"
fi

# Sync ~/.ssh/authorized_keys from 1Password (home role only -- work laptops
# shouldn't accept inbound SSH from personal keys). Lets this machine be
# SSH'd into (e.g. over Tailscale) without hand-copying pubkeys. See
# config/ssh/authorized_keys.home for the item list and why it's separate
# from the 1Password agent allowlist above.
if running_home_role; then
  ak_source="$DIR/config/ssh/authorized_keys.home"
  if [ -f "$ak_source" ] && command_available op; then
    echo "🔑 syncing ~/.ssh/authorized_keys from 1Password (role: home)"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    while IFS= read -r item; do
      [ -z "$item" ] && continue
      case "$item" in \#*) continue ;; esac
      # Uses 1Password's desktop-app biometric integration, not `op signin`
      # -- `op whoami` reports signed-out even when this works fine, so
      # don't gate on it, just let a failed fetch skip that one item.
      pubkey=$(op item get "$item" --vault Personal --fields "public key" 2> /dev/null)
      if [ -z "$pubkey" ]; then
        echo "  → could not fetch '$item' from 1Password, skipping"
        continue
      fi
      fingerprint=$(echo "$pubkey" | cut -d' ' -f2)
      if grep -qF "$fingerprint" ~/.ssh/authorized_keys 2> /dev/null; then
        echo "  → $item already authorized"
      else
        echo "$pubkey $item (1Password)" >> ~/.ssh/authorized_keys
        echo "  → added $item"
      fi
    done < "$ak_source"
  fi

  # Remote Login (macOS's SSH server) can only be toggled interactively in
  # System Settings, so just detect and nudge rather than trying to set it.
  if running_macos && ! timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/22" 2> /dev/null; then
    echo "⚠️  Remote Login doesn't look enabled -- turn it on manually:"
    echo "    System Settings → General → Sharing → Remote Login"
  fi
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
