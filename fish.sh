#!/usr/bin/env bash

# shellcheck source=./functions.sh
source ./functions.sh

echo "🐟 configuring fish"
fish_path=$(which fish)
if test -f /etc/shells && ! grep -q "$fish_path" /etc/shells; then
  sudo bash -c "which fish >> /etc/shells"
fi

if running_macos; then
  if ! dscl . -read /Users/$USER UserShell | grep -q "$fish_path"; then
    chsh -s "$fish_path"
  fi
fi

curl -sL https://git.io/fisher | source && fisher update

echo