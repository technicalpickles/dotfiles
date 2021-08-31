#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DIR

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
  ./gh-shorthand.sh
fi


# if running_macos; then
#   if !brew_available; then
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#   fi
#   brew_bundle
#   ~/.macos
# fi


# if ! running_codespaces; then
#   vim_plugins
# fi

echo "✅ Done"