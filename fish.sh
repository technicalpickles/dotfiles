#!/usr/bin/env bash

# shellcheck source=./functions.sh
source ./functions.sh

if ! which fish > /dev/null 2> /dev/null; then
  echo "missing fish :("
  exit 1
fi

echo "🐟 configuring fish"
fish_path=$(which fish)
if test -f /etc/shells && ! grep -q "$fish_path" /etc/shells; then
  sudo bash -c "which fish >> /etc/shells"
fi

if running_macos; then
  if ! dscl . -read "$HOME" UserShell | grep -q "$fish_path"; then
    chsh -s "$fish_path"
  fi
fi

if ! fish -c "type fisher >/dev/null 2>/dev/null"; then
  echo "installing fisher"
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

plugins=(
  jethrokuan/z
  jorgebucaran/autopair.fish
)

if command_available fzf; then
  plugins+=(PatrickF1/fzf.fish)
fi

if command_available direnv; then
  plugins+=(halostatue/fish-direnv)
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

# Fisher creates ~/.config/fish/ as a real directory, which clobbers the
# dotfiles symlink. Merge dotfiles fish config into the fisher-managed dir.
dotfiles_fish="$DIR/config/fish"
fish_config="$HOME/.config/fish"

if [ -d "$fish_config" ] && [ ! -L "$fish_config" ]; then
  # Remove stale nested symlink if present (config/fish linked inside itself)
  rm -f "$fish_config/fish"

  # Symlink conf.d files from dotfiles
  for f in "$dotfiles_fish"/conf.d/*; do
    [ -f "$f" ] && ln -sf "$f" "$fish_config/conf.d/"
  done

  # Symlink config.fish from dotfiles
  [ -f "$dotfiles_fish/config.fish" ] && ln -sf "$dotfiles_fish/config.fish" "$fish_config/config.fish"

  # Symlink fish_plugins from dotfiles
  [ -f "$dotfiles_fish/fish_plugins" ] && ln -sf "$dotfiles_fish/fish_plugins" "$fish_config/fish_plugins"
fi

echo
