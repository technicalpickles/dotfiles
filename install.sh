#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
source ./functions.sh

if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  DOTPICKLES_ROLE=$(detect_role)
fi
export DOTPICKLES_ROLE
echo "role: $DOTPICKLES_ROLE"

if [[ "$DOTPICKLES_ROLE" = "noop" ]]; then
  exit 0
fi

if running_macos; then
  # Prevent sleeping during script execution, as long as the machine is on AC power
  caffeinate -s -w $$ &
fi

# only setup submodules if running in a git repo. doesn't apply to devcontainer which copies files in
if [ -d .git ]; then
  git submodule init
  git submodule update || {
    echo "Warning: Some submodules failed to initialize (this is non-fatal)"
    true # Ensure we don't exit with error code
  }
fi

./symlinks.sh

echo

./gitconfig.sh
./miseconfig.sh

# Setup Claude Code configuration
if command_available claude; then
  echo "Configuring Claude Code..."
  bash "$DIR/claudeconfig.sh"
else
  echo "Claude Code not installed, skipping configuration"
fi

if running_macos; then
  load_brew_shellenv

  if ! brew_available; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_shellenv
  fi

  brew_bundle

  echo "🍎 configuring macOS defaults"
  ~/.macos
  echo

  echo "🔐 configuring SSH to use keychain"
  ssh-add --apple-load-keychain

  # Setup /workspace symlink for work environments
  if [[ "$DOTPICKLES_ROLE" = "work" ]]; then
    setup_synthetic_workspace
  fi

  # ./gh-shorthand.sh
fi

if ! running_codespaces; then
  #  ./vim.sh
  ./tmux.sh
  ./fish.sh
  ./bash.sh
fi

echo "✅ Done"
