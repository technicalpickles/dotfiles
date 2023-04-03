#!/usr/bin/env bash

set -e

# shellcheck source=./functions.sh
source functions.sh

echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local
rm -f ~/.gitconfig.d/1password

op_ensure_signed_in

if [ -d ~/workspace ]; then
  echo "  → enabling maintenance for repositories"
  for git_dir in $HOME/workspace/*/.git; do
    repo_dir=$(dirname "$git_dir")
    git config --file ~/.gitconfig.local --add maintenance.repo "$repo_dir"
  done
fi

if command_available delta; then
  echo "  → enabling delta for pager"
  git config --file ~/.gitconfig.local core.pager "delta --dark" 
fi

if command_available gpg; then
  # https://gist.github.com/danieleggert/b029d44d4a54b328c0bac65d46ba4c65
  
  echo "  → enabling gpg"
  git config --file ~/.gitconfig.local gpg.program `which gpg`

  if gpg --list-keys | grep -q C9A25EB8; then
    git config --file ~/.gitconfig.local user.signingkey "C9A25EB8" 
    git config --file ~/.gitconfig.local commit.gpgsign true
  fi

  if gpg --list-keys | grep -q F446606B90EA1DB1; then
    git config --file ~/.gitconfig.local user.signingkey "F446606B90EA1DB1" 
    git config --file ~/.gitconfig.local commit.gpgsign true
  fi
fi

if running_macos; then
  echo "  → enabling running_macos specific settings"
  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/running_macos" >> ~/.gitconfig.local
fi

if fzf_available; then
  echo "  → enabling fzf specific settings"

  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/fzf" >> ~/.gitconfig.local
fi

code=$(vscode_command)
if [ -n "${code}" ]; then
  echo "  → enabling vscode specific settings"

  if running_macos; then
    echo "[include]" >> ~/.gitconfig.local
    echo "  path = ~/.gitconfig.d/vscode-macos" >> ~/.gitconfig.local
  else
    git config --file ~/.gitconfig.local mergetool.code.cmd "${code}"
  fi

  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/vscode" >> ~/.gitconfig.local
fi