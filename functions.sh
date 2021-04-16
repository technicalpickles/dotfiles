#!/usr/bin/env bash

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

fzf_available() {
  which fzf > /dev/null
  return $?
}


find_targets() {
  local directory="$1"
  find "$directory" -maxdepth 1
}

link_directory_contents() {
  local directory="$1"
  for linkable in $(find_targets "${directory}"); do
    if [ "$linkable" = "config" ]; then
      continue
    fi

    target="$HOME/.config/$(basename "$linkable")"
    link "$linkable" "$target"
  done
}

link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"

  if [ ! -L "$target" ]; then
    echo "🔗 $display_target → linking from $linkable"
    ln -Ff -s "$DIR/$linkable" "$target"
  else
    echo "🔗 $display_target → already linked"
  fi
}

brew_bundle() {
  echo "🍻 running brew bundle"
  brew bundle | sed 's/^/  → /'
  echo
}

vim_plugins() {
  vim +PlugInstall +qall
}