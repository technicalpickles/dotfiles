#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DIR

# shellcheck source=./functions.sh
source ./functions.sh

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


# if running_macos; then
#   brew_bundle
#   ~/.macos
# fi

# if ! running_codespaces; then
#   vim_plugins
# fi

echo "✅ Done"