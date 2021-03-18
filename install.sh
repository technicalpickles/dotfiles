#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for linkable in $(find home -type f -maxdepth 1) $(find home -type d -maxdepth 1); do
  target="$HOME/$(basename $linkable)"
  display_target="${target/$HOME/~}"

  if [ "$linkable" = "home" ]; then
    continue
  fi

  if [ ! -L "$target" ]; then
    echo "🔗 $display_target → linking from $linkable."
    ln -Ff -s "$DIR/$linkable" "$target"
  else
    echo "🔗 $display_target → already linked"
  fi
done

echo
echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local

if which -s delta; then
  echo "  → enabling delta for pager"
  git config --file ~/.gitconfig.local core.pager "delta --dark" 
fi

if [ "$(uname)" == Darwin ]; then
  echo "  → enabling macOS specific settings"
  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/macos" >> ~/.gitconfig.local
fi

if which -s fzf; then
  echo "  → enabling fzf specific settings"

  echo "[include]" >> ~/.gitconfig.local
  echo "  path = ~/.gitconfig.d/fzf" >> ~/.gitconfig.local
fi


if which -s code-insiders; then
  code="code-insiders"
elif which -s code; then
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

echo "✅ Done"