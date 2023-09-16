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

if ! fish -c "type fisher >/dev/null"; then
  echo "installing fisher"
  fish -c "curl -sL https://git.io/fisher | source && fisher update"
fi

plugins=(
  jorgebucaran/fisher
  IlanCosman/tide@v5
  jethrokuan/z
  jorgebucaran/autopair.fish
  gazorby/fish-abbreviation-tips
)

if command_available fzf; then
  plugins+=(PatrickF1/fzf.fish)
fi

if command_available direnv; then
  plugins+=(halostatue/fish-direnv)
fi

if ! [ "$DOTPICKLES_ROLE" = "work" ]; then
  plugins+=(jtomaszewski/fish-asdf@patch-1)
fi

echo "previous plugins:"
if [ -f ~/.config/fish/fish_plugins ]; then
  cat < ~/.config/fish/fish_plugins
fi

rm -f ~/.config/fish/fish_plugins

echo

echo "rebuilding list of plugins"
for plugin in "${plugins[@]}"; do
  echo "$plugin"
  fish -c "fisher install $plugin"
done


echo
