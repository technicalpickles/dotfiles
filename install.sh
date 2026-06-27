#!/usr/bin/env bash

set -eo pipefail

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes | -y) export DOTPICKLES_YES=1 ;;
  esac
done

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

# Ensure ~/.pickles points to this repo, even if cloned elsewhere (e.g. devcontainers)
if [[ "$DIR" != "$HOME/.pickles" ]] && [[ ! -e "$HOME/.pickles" ]]; then
  ln -s "$DIR" "$HOME/.pickles"
  echo "🔗 Symlinked ~/.pickles -> $DIR"
fi

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
# Sourcing functions.sh detects and exports DOTPICKLES_ROLE if unset (respecting
# any value from the environment or .env above). See functions.sh / ADR 0035.
source ./functions.sh
echo "role: $DOTPICKLES_ROLE"

# Guard: non-interactive without --yes is an error
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi

if running_macos; then
  # Prevent sleeping during script execution, as long as the machine is on AC power
  caffeinate -s -w $$ &
fi

if running_macos; then
  load_brew_shellenv

  if ! brew_available; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_shellenv
  fi

  brew_bundle
fi

git submodule init
git submodule update

link_directory_contents home

mkdir -p "$HOME/.config"
./miseconfig.sh
link_directory_contents config

echo

./gitconfig.sh
./sshconfig.sh
./taskrc.sh

if running_macos; then
  echo "🍎 configuring macOS defaults"
  ~/.macos
  echo

  echo "🔐 configuring SSH to use keychain"
  ssh-add --apple-load-keychain

  # ./gh-shorthand.sh
fi

if ! running_codespaces; then
  #  ./vim.sh
  ./tmux.sh
  ./fish.sh
  ./bash.sh
  ./skills.sh
fi

echo "✅ Done"
