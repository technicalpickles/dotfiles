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

if ! test -d "${HOME}/.local/share/omf/"; then
  curl -L https://get.oh-my.fish | fish
fi

rm -f ~/.config/omf/bundle
touch ~/.config/omf/bundle

theme=bobthefish
if ! test -d "${HOME}/.local/share/omf/themes/${theme}"; then
  echo theme $theme >> ~/.config/omf/bundle
fi

rm ~/.config/omf/bundle
echo package foreign-env >> ~/.config/omf/bundle
echo package z >> ~/.config/omf/bundle


for package in direnv nodenv pyenv rbenv thefuck; do
  if which "$package" >/dev/null; then
    echo package "$package" >> ~/.config/omf/bundle
  fi
done

fish -c "omf install"
fish -c "omf install $theme"
fish -c "omf install https://github.com/PatrickF1/fzf.fish"
fish -c "omf install https://github.com/zimski/ssh_agent"

echo