#!/usr/bin/env bash

DIR="${DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# shellcheck source=./functions.sh
source "$DIR/functions.sh"

if ! which fish > /dev/null 2> /dev/null; then
  echo "missing fish :("
  exit 1
fi

echo "🐟 configuring fish"
fish_path=$(which fish)

if test -f /etc/shells && ! grep -q "$fish_path" /etc/shells; then
  echo "  → adding $fish_path to /etc/shells"
  if echo "$fish_path" | sudo tee -a /etc/shells > /dev/null; then
    echo "  ✅ added to /etc/shells"
  else
    echo "  ❌ failed to add to /etc/shells — run manually: echo $fish_path | sudo tee -a /etc/shells"
  fi
else
  echo "  ✅ $fish_path already in /etc/shells"
fi

if running_macos; then
  current_shell=$(dscl . -read "$HOME" UserShell | awk '{print $2}')
  if [[ "$current_shell" != "$fish_path" ]]; then
    echo "  → changing login shell from $current_shell to $fish_path"
    if chsh -s "$fish_path"; then
      echo "  ✅ login shell changed — open a new terminal to use fish"
    else
      echo "  ❌ chsh failed — run manually: chsh -s $fish_path"
    fi
  else
    echo "  ✅ login shell already set to $fish_path"
  fi
fi

# link_directory_contents symlinks ~/.config/fish → dotfiles/config/fish.
# Fisher would write into the dotfiles repo through that symlink, so replace
# it with a real directory before fisher runs, then merge dotfiles conf back in.
dotfiles_fish="$DIR/config/fish"
fish_config="$HOME/.config/fish"

if [ -L "$fish_config" ]; then
  rm "$fish_config"
  mkdir -p "$fish_config" "$fish_config/conf.d" "$fish_config/functions" "$fish_config/completions"
fi

# Symlink config.fish and fish_plugins first (fisher needs fish_plugins to know what to install)
if [ -d "$fish_config" ]; then
  [ -f "$dotfiles_fish/config.fish" ] && ln -sf "$dotfiles_fish/config.fish" "$fish_config/config.fish"
  [ -f "$dotfiles_fish/fish_plugins" ] && ln -sf "$dotfiles_fish/fish_plugins" "$fish_config/fish_plugins"
fi

# Install fisher if missing, then sync plugins from fish_plugins file
if ! fish -c "type fisher >/dev/null 2>/dev/null"; then
  echo "installing fisher"
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" < /dev/null
fi

echo "syncing plugins from fish_plugins:"
cat "$fish_config/fish_plugins"
fish -c "fisher update" < /dev/null

# Symlink conf.d and functions AFTER fisher update, so fisher doesn't overwrite them
if [ -d "$fish_config" ] && [ -d "$dotfiles_fish/conf.d" ]; then
  for f in "$dotfiles_fish"/conf.d/*; do
    [ -f "$f" ] && ln -sf "$f" "$fish_config/conf.d/"
  done

  for f in "$dotfiles_fish"/functions/*; do
    [ -f "$f" ] && ln -sf "$f" "$fish_config/functions/"
  done
fi

echo
