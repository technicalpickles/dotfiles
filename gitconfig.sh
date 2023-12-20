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

if running_macos; then
  echo "  → enabling running_macos specific settings"

  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/running_macos

  if test -d '/Applications/1Password.app/'; then
    signing_key=$(op item list  --tags "ssh signing","$DOTPICKLES_ROLE" --format=json | op item get - --fields 'public key')
    if [[ -n "$signing_key" ]]; then
      echo "  → enabling 1password ssh key signing"
      op_ensure_signed_in

      git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/1password

      git config --file ~/.gitconfig.local gpg.format ssh
      git config --file ~/.gitconfig.local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
      git config --file ~/.gitconfig.local commit.gpgsign true

      signing_key=$(op item list  --tags 'ssh signing','work' --format=json | op item get - --fields 'public key')
      if [[ -n "$signing_key" ]]; then
        git config --file ~/.gitconfig.local user.signingkey "$signing_key"
      else
        echo "uh oh, couldn't find an SSH key in 1password to use" >&2
        exit 1
      fi
    else
      echo "  → skipping 1password ssh key signing, couldn't find singing key for ${DOTPICKLES_ROLE}" >&2
    fi
  fi
fi

if fzf_available; then
  echo "  → enabling fzf specific settings"

  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/fzf
fi

code=$(vscode_command)
if [ -n "${code}" ]; then
  echo "  → enabling vscode specific settings"

  if running_macos; then
    git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/vscode-macos
  else
    git config --file ~/.gitconfig.local mergetool.code.cmd "${code}"
  fi

  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/vscode
fi
