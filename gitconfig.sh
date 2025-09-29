#!/usr/bin/env bash

set -e

# shellcheck source=./functions.sh
source functions.sh

echo "🔨 rebuilding ~/.gitconfig.local"
rm -f ~/.gitconfig.local
rm -f ~/.gitconfig.d/1password

mkdir -p ~/.gitconfig.d

if [ -d ~/workspace ]; then
  echo "  → enabling maintenance for repositories"
  for git_dir in $HOME/workspace/*/.git; do
    repo_dir=$(dirname "$git_dir")
    git config --file ~/.gitconfig.local --add maintenance.repo "$repo_dir"
  done
fi

if command_available delta; then
  echo "  → enabling delta for pager"
  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/delta
fi

if command_available gh; then
  echo "  → enabling gh credential helper"
  gh_path=$(which gh)
  for remote in https://github.com https://gist.github.com; do
    git config --file ~/.gitconfig.local "credential.$remote.helper" "!$gh_path auth git-credential"
  done
fi

if running_macos; then
  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/macos
fi

signing=false
case "$DOTPICKLES_ROLE" in
  personal)
    echo "  → using personal identify for git"
    git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/personal-identity

    if running_macos && test -d '/Applications/1Password.app/'; then
      echo "  → enabling 1password ssh key signing"
      signing=true

      op_ensure_signed_in

      git config --file ~/.gitconfig.local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
      signing_key=$(op item list --tags 'ssh signing','home' --format=json | op item get - --fields 'public key')
      if [[ -n "$signing_key" ]]; then
        git config --file ~/.gitconfig.local user.signingkey "$signing_key"
      else
        echo "uh oh, couldn't find an SSH key in 1password to use" >&2
        exit 1
      fi
    fi
    ;;
  work)
    echo " → using work identify for git"
    git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/work-identity

    echo "  → enabling work ssh key signing"
    signing=true

    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
      git config --file ~/.gitconfig.local user.signingkey "$HOME/.ssh/id_ed25519.pub"
    fi
    ;;
  *)
    echo "Unexpected role: $DOTPICKLES_ROLE"
    exit 1
    ;;
esac

if [ "$signing" = true ]; then
  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/signing
fi

if fzf_available; then
  echo "  → enabling fzf specific settings"

  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/fzf
fi

if command_available git-duet; then
  echo "  → enabling git-duet specific settings"
  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/duet
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
