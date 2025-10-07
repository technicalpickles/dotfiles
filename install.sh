#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

if [[ -f .env ]]; then
  source .env
fi

if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  if which hostnamectl > /dev/null 2>&1; then
    hostname=$(hostnamectl hostname)
  else
    hostname=$(hostname)
  fi
  if [[ "$hostname" =~ ^josh-nichols- ]]; then
    DOTPICKLES_ROLE="work"
  else
    DOTPICKLES_ROLE="personal"
  fi
fi

echo "role: $DOTPICKLES_ROLE"

# shellcheck source=./functions.sh
source ./functions.sh

if running_macos; then
  # Prevent sleeping during script execution, as long as the machine is on AC power
  caffeinate -s -w $$ &
fi

git submodule init
git submodule update

./symlinks.sh

echo

./gitconfig.sh

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

  # ./gh-shorthand.sh
fi

if ! running_codespaces; then
  #  ./vim.sh
  ./tmux.sh
  ./fish.sh
  ./bash.sh
fi

echo "✅ Done"
