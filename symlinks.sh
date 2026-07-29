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

# Detect ~/Library/LaunchAgents symlinks that are dangling because their repo
# plist moved (e.g. a platform-gating move like LaunchAgents/foo.plist ->
# LaunchAgents/arm64-macos/foo.plist). Repoint them and force launchd to
# reload, since launchd runs an already-loaded job from memory and won't
# notice the plist moved until the next full re-scan (reboot) -- and per bean
# gt-ap4x, that re-scan can silently fail on a still-dangling symlink.
repoint_dangling_launchagents() {
  local agents_dir="$HOME/Library/LaunchAgents"
  [ -d "$agents_dir" ] || return 0

  for target in "$agents_dir"/*.plist; do
    [ -e "$target" ] && continue # not dangling (valid symlink, real file, or no match)
    [ -L "$target" ] || continue # unmatched glob literal / not a symlink at all

    local name current_repo_path
    name="$(basename "$target")"

    current_repo_path="$(find "$DIR/LaunchAgents" -maxdepth 1 -name "$name" -type f)"
    if [ -z "$current_repo_path" ] && running_arm64_macos; then
      current_repo_path="$(find "$DIR/LaunchAgents/arm64-macos" -maxdepth 1 -name "$name" -type f)"
    fi

    if [ -z "$current_repo_path" ]; then
      echo "⚠️  $target -> dangling, no applicable repo plist found (skipping)"
      continue
    fi

    local relative="${current_repo_path#"$DIR"/}"
    echo "🔧 $target -> dangling, repo plist now at $relative"
    link "$relative" "$target"

    if [ "$(readlink "$target")" = "$current_repo_path" ]; then
      echo "🔄 reloading $name"
      launchctl unload "$target" 2> /dev/null || true
      launchctl load "$target" 2> /dev/null || true
    fi
  done
}

# Link LaunchAgents if on macOS
if running_macos; then
  mkdir -p "$HOME/Library/LaunchAgents"
  repoint_dangling_launchagents
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
