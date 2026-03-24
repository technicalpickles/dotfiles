#!/usr/bin/env bash

set -eo pipefail

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

if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  if hostname=$(hostnamectl hostname 2> /dev/null); then
    :
  else
    hostname=$(hostname)
  fi
  if [[ "$hostname" =~ ^josh-nichols- ]]; then
    DOTPICKLES_ROLE="work"
  else
    DOTPICKLES_ROLE="personal"
  fi
fi

export DOTPICKLES_ROLE
echo "role: $DOTPICKLES_ROLE"

# shellcheck source=./functions.sh
source ./functions.sh

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
link_directory_contents config

echo

./gitconfig.sh
./sshconfig.sh

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
fi


echo "✅ Done"
