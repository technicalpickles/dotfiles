#!/usr/bin/env bash

# shellcheck source=./functions.sh
source ./functions.sh

echo "💥 configuring bash"
if running_macos; then
  bash_path=$(which bash)
  if [[ ! $bash_path == */homebrew/bin/bash ]]; then
    brew install bash
  fi
fi

# Clone rather than run oh-my-bash's installer: the installer moves ~/.bashrc
# aside (including the symlink to home/.bashrc that symlinks.sh just made) and
# writes its own template in its place. home/.bashrc already sets OSH and loads
# oh-my-bash, so the clone is all we need.
if [[ ! -d ~/.oh-my-bash/ ]]; then
  echo "installing oh-my-bash"
  git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git ~/.oh-my-bash
fi
