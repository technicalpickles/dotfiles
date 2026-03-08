#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
source ./functions.sh

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
