#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DIR

if [[ -f .env ]]; then
  source .env
fi

if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  while true; do
    read -p "What role is this machine used for? (work or personal) " DOTPICKLES_ROLE
    case $DOTPICKLES_ROLE in
      [Ww]* ) DOTPICKLES_ROLE=work; break;;
      [Pp]* ) DOTPICKLES_ROLE=personal; break;;
      * ) echo "Please answer work or personal.";;
    esac
    export DOTPICKLES_ROLE
    echo "export DOTPICKLES_ROLE=${DOTPICKLES_ROLE}" >> .env
    source .env
  done
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

link_directory_contents home

mkdir -p "$HOME/.config"
link_directory_contents config

echo

./gitconfig.sh

if fish_available; then
  ./fish.sh
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

  # ./gh-shorthand.sh
fi


if ! running_codespaces; then
  ./vim.sh
fi

echo "✅ Done"
