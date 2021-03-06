#!/usr/bin/env bash

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

running_codespaces() {
  [ "$CODESPACES" = true ]
  return $?
}

fzf_available() {
  which fzf > /dev/null
  return $?
}

fish_available() {
  which fish > /dev/null
  return $?
}

vscode_command() {
  if which code-insiders > /dev/null; then
    code="code-insiders"
  elif which code > /dev/null; then
    code="code"
  fi

  echo "$code"
}

find_targets() {
  local directory="$1"
  find "$directory" -maxdepth 1
}

link_directory_contents() {
  local directory="$1"
  for linkable in $(find_targets "${directory}"); do
    if [ "$linkable" = "config" -o "${linkable}" = "home" ]; then
      continue
    fi

    if [ "$directory" = "home" ]; then
      target="$HOME/$(basename "$linkable")"
    elif [ "${directory}" = "config" ]; then
      target="$HOME/.config/$(basename "$linkable")"
    else
      echo "don't know where to put ${directory} links"
      return 1
    fi
    
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
  elif [ "$(readlink "$target")" != "${DIR}/${linkable}" ]; then
    echo "🔗 $display_target → already linked to $(readlink ${target})"
    read -p "Overwrite it to link to ${DIR}/${linkable}? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "🔗 $display_target → linking from $linkable"
      ln -Ff -s "$DIR/$linkable" "$target"
    fi
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