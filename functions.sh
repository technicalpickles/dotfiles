#!/usr/bin/env bash

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

running_codespaces() {
  [ "$CODESPACES" = true ]
  return $?
}

command_available() {
  which "$1" >/dev/null 2>&1
}

fzf_available() {
  command_available fzf
}

fish_available() {
  command_available fish
}

brew_available() {
  command_available brew
}

load_brew_shellenv() {
  if test -x /opt/homebrew/bin/brew; then
    brew=/opt/homebrew/bin/brew
  elif test -x /usr/local/bin/brew; then
    brew=/usr/local/bin/brew
  fi

  if test -n "${brew}"; then
    eval "$($brew shellenv)"
  fi
}

vscode_command() {
  if command_available code-insiders; then
    code="code-insiders"
  elif command_available code; then
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
  cat Brewfile Brewfile.${DOTPICKLES_ROLE} 2>/dev/null | brew bundle --file=- | sed 's/^/  → /'
  echo
}

vim_plugins() {
  echo "⌨️️ configuring vim"
  vim +PlugInstall +qall
  echo
}

# make sure op is logged in
op_ensure_signed_in() {
  local op=$(which op)
  if ! op whoami >/dev/null 2>&1; then
    op signin
  fi
}
