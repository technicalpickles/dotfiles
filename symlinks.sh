#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes | -y) export DOTPICKLES_YES=1 ;;
  esac
done

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
source ./functions.sh

# Guard: non-interactive without --yes is an error
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi

link_directory_contents home

mkdir -p "$HOME/.config"
link_directory_contents config

# herdr: link only config.toml, not the directory. herdr keeps live unix
# sockets, session.json, and logs alongside it in ~/.config/herdr; a directory
# symlink would put that runtime state in the repo, where `git clean -xfd`
# would eat the live session.
mkdir -p "$HOME/.config/herdr"
link config/herdr/config.toml "$HOME/.config/herdr/config.toml"

# Link LaunchAgents if on macOS
if running_macos; then
  mkdir -p "$HOME/Library/LaunchAgents"
  echo "🚀 linking LaunchAgents"
  for agent in LaunchAgents/*.plist; do
    if [ -f "$agent" ]; then
      target="$HOME/Library/LaunchAgents/$(basename "$agent")"
      link "$agent" "$target"
    fi
  done
fi

# Link arm64-only LaunchAgents (e.g. agents that hard-code /opt/homebrew)
if running_arm64_macos; then
  echo "🚀 linking arm64-macos LaunchAgents"
  for agent in LaunchAgents/arm64-macos/*.plist; do
    if [ -f "$agent" ]; then
      target="$HOME/Library/LaunchAgents/$(basename "$agent")"
      link "$agent" "$target"
    fi
  done
fi

# Link home-role-only LaunchAgents (e.g. personal-account sync jobs)
if running_macos && running_home_role; then
  echo "🚀 linking home-role LaunchAgents"
  for agent in LaunchAgents/home/*.plist; do
    if [ -f "$agent" ]; then
      target="$HOME/Library/LaunchAgents/$(basename "$agent")"
      link "$agent" "$target"
    fi
  done
fi
