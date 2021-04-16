#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source functions.sh

for linkable in $(find home -type f -maxdepth 1) $(find home -type d -maxdepth 1); do
  target="$HOME/$(basename $linkable)"

  if [ "$linkable" = "home" ]; then
    continue
  fi

  link "$linkable" "$target"
done

mkdir -p "$HOME/.config"
for linkable in $(find config -type f -maxdepth 1) $(find config -type d -maxdepth 1); do
  if [ "$linkable" = "config" ]; then
    continue
  fi

  target="$HOME/.config/$(basename "$linkable")"
  link "$linkable" "$target"
done


echo
echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local

if which delta > /dev/null; then
  echo "  → enabling delta for pager"
  git config --file ~/.gitconfig.local core.pager "delta --dark" 
fi

if [ "$(uname)" == Darwin ]; then
  echo "  → enabling macOS specific settings"
  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/macos" >> ~/.gitconfig.local
fi

if which fzf > /dev/null; then
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

  if [ "$(uname)" == Darwin ]; then
    echo "[include]" >> ~/.gitconfig.local
    echo "  path = ~/.gitconfig.d/vscode-macos" >> ~/.gitconfig.local
  else
    git config --file ~/.gitconfig.local mergetool.code.cmd "${code}"
  fi

  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/vscode" >> ~/.gitconfig.local
fi

if macos; then
  brew_bundle
fi

vim_plugins

echo "✅ Done"