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

if running_macos; then
  git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/macos
fi

signing=false
case "$DOTPICKLES_ROLE" in
  home | container | claude-code-remote | coi-host)
    # home is the personal-machine identity. container, claude-code-remote, and
    # coi-host reuse it as a basic identity; the 1Password signing block below is
    # macOS-only so it's a no-op on Linux containers / the cloud runner (where
    # commits go through the GitHub integration anyway) / the COI incus host VM.
    echo "  → using home identity for git"
    git config --file ~/.gitconfig.local --add include.path ~/.gitconfig.d/home-identity

    if [ "$DOTPICKLES_ROLE" = "home" ] && command_available gh; then
      echo "  → rewriting SSH github.com remotes to HTTPS (home role only)"
      git config --file ~/.gitconfig.local "url.https://github.com/.insteadOf" "git@github.com:"
    fi

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

if command_available gh; then
  # This must run LAST. /opt/homebrew/etc/gitconfig (Homebrew's system-level
  # config, always read before ~/.gitconfig and everything it includes) sets a
  # bare, unscoped `credential.helper = osxkeychain`. Git tries helpers for a
  # URL in file-read order, so that system-level entry is always first in line
  # -- no ordering earlier in this script can put gh ahead of it. The empty
  # `--replace-all ... ""` is git's documented reset: it clears every
  # credential.helper entry accumulated so far for that URL (system-level
  # osxkeychain included), so the `!gh auth git-credential` added right after
  # it is the *only* helper left for github.com/gist.github.com. Without this,
  # osxkeychain silently answers `git credential fill` first, bypassing gh's
  # hardened Secret Gate entirely (confirmed via GIT_TRACE=1: only
  # `git-credential-osxkeychain get` ran, gh was never invoked) -- and each
  # successful auth re-caches a credential in osxkeychain via `store`, which
  # is what makes the leak self-healing/recurring even after manually
  # deleting the stale Keychain item.
  echo "  → enabling gh credential helper (reset, so it wins over osxkeychain)"
  gh_path=$(which gh)
  for remote in https://github.com https://gist.github.com; do
    git config --file ~/.gitconfig.local --replace-all "credential.$remote.helper" ""
    git config --file ~/.gitconfig.local --add "credential.$remote.helper" "!$gh_path auth git-credential"
  done
fi
