#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DIR

# shellcheck source=somefile
source functions.sh

git submodule init
git submodule update

link_directory_contents home

mkdir -p "$HOME/.config"
link_directory_contents config

echo
echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local

if which delta > /dev/null; then
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

if which code-insiders > /dev/null; then
  code="code-insiders"
elif which code > /dev/null; then
  code="code"
fi

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

# if running_macos; then
#   brew_bundle
#   ~/.macos
# fi

# vim_plugins

echo "✅ Done"