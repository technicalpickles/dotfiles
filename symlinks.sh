#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes|-y) export DOTPICKLES_YES=1 ;;
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
