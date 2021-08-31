#!/usr/bin/env bash

set -e

# shellcheck source=./functions.sh
source functions.sh

echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local

if command_available delta; then
  echo "  → enabling delta for pager"
  git config --file ~/.gitconfig.local core.pager "delta --dark" 
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
    echo "  path = ~/.gitconfig.d/vscode-running_macos" >> ~/.gitconfig.local
  else
    git config --file ~/.gitconfig.local mergetool.code.cmd "${code}"
  fi

  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/vscode" >> ~/.gitconfig.local
fi