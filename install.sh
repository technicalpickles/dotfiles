#!/usr/bin/env bash

set -eo pipefail

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes | -y) export DOTPICKLES_YES=1 ;;
  esac
done

# Automated container builds (DOCKER_BUILD, same signal functions.sh uses to
# detect the "container" role) imply --yes: there's no tty to prompt on, and
# no human around to answer confirm()'s y/N questions in functions.sh.
if [ -n "${DOCKER_BUILD:-}" ]; then
  export DOTPICKLES_YES=1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

# Ensure ~/.pickles points to this repo, even if cloned elsewhere (e.g. devcontainers)
if [[ "$DIR" != "$HOME/.pickles" ]] && [[ ! -e "$HOME/.pickles" ]]; then
  ln -s "$DIR" "$HOME/.pickles"
  echo "🔗 Symlinked ~/.pickles -> $DIR"
fi

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
# Sourcing functions.sh detects and exports DOTPICKLES_ROLE if unset (respecting
# any value from the environment or .env above). See functions.sh / ADR 0035.
source ./functions.sh
echo "role: $DOTPICKLES_ROLE"

# Guard: non-interactive without --yes is an error
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi

if running_macos; then
  # Prevent sleeping during script execution, as long as the machine is on AC power
  caffeinate -s -w $$ &
fi

if running_macos; then
  load_brew_shellenv

  if ! brew_available; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_shellenv
  fi

  brew_bundle
fi

git submodule init
git submodule update

link_directory_contents home

mkdir -p "$HOME/.config"
./miseconfig.sh
link_directory_contents config

echo

./gitconfig.sh
./sshconfig.sh
./taskrc.sh

if running_macos; then
  echo "🍎 configuring macOS defaults"
  ~/.macos
  echo

  echo "🔐 configuring SSH to use keychain"
  ssh-add --apple-load-keychain

  # ./gh-shorthand.sh
fi

# Runs after gitconfig.sh/sshconfig.sh (agent git identity fragments and the
# 1Password SSH agent allowlist need to already be in place) and after the
# macOS keychain ssh-add above (so a live SSH key check has keys to find).
# Guarded because claudeconfig.sh hard-exits without claude/jq, and this repo
# installs on machines that have neither (e.g. a fresh coi-host VM before
# Claude Code is installed). SKIP_SSH_CHECK is read directly from the
# environment by claudeconfig.sh, so SKIP_SSH_CHECK=1 ./install.sh reaches it
# without any extra plumbing here.
if command_available claude && command_available jq; then
  echo "🤖 configuring Claude Code"
  ./claudeconfig.sh
else
  missing=()
  command_available claude || missing+=(claude)
  command_available jq || missing+=(jq)
  echo "⏭  skipping claudeconfig.sh (missing: ${missing[*]})"
  echo "   run later with: DOTPICKLES_ROLE=$DOTPICKLES_ROLE ./claudeconfig.sh"
fi

echo

if ! running_codespaces; then
  #  ./vim.sh
  ./tmux.sh
  ./fish.sh
  ./bash.sh
  ./skills.sh
fi

echo "✅ Done"
