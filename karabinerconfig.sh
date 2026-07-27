#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source "$DIR/functions.sh"

# Karabiner is a home-role-only tool (Brewfile.home), and this fix is
# specifically for its wake-from-sleep reactivation delay -- see
# doc/adr/0045-sudoers.d-templates-for-launchagent-root-actions.md.
role="${DOTPICKLES_ROLE:-home}"
if [ "$role" != "home" ]; then
  echo "⌨️  role '$role' isn't home, skipping karabiner-wake-fix setup"
  exit 0
fi

if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
  echo "⌨️  Karabiner-Elements not installed, skipping karabiner-wake-fix setup"
  exit 0
fi

echo "⌨️  setting up karabiner-wake-fix"

# Restart daemon on wake needs root, and LaunchAgents have no terminal to
# prompt for a password. Install a scoped NOPASSWD sudoers rule for exactly
# that command. Must be a real file (root-owned, mode 440), not a symlink --
# sudo refuses sudoers.d entries that aren't.
sudoers_source="$DIR/config/sudoers.d/karabiner-wake-fix"
sudoers_target="/etc/sudoers.d/karabiner-wake-fix"
if sudo cmp -s "$sudoers_source" "$sudoers_target" 2> /dev/null; then
  echo "  → $sudoers_target already up to date"
else
  sudo install -m 0440 -o root -g wheel "$sudoers_source" "$sudoers_target"
  if sudo visudo -c > /dev/null; then
    echo "  → installed $sudoers_target"
  else
    echo "  → ⚠️  $sudoers_target failed visudo validation, removing" >&2
    sudo rm -f "$sudoers_target"
    exit 1
  fi
fi

link "LaunchAgents/com.technicalpickles.karabiner-wake-fix.plist" \
  "$HOME/Library/LaunchAgents/com.technicalpickles.karabiner-wake-fix.plist"

echo "  → load it with: ./launchagents.sh load com.technicalpickles.karabiner-wake-fix"
