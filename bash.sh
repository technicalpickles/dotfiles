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

if [[ ! -d ~/.oh-my-bash/ ]]; then
  echo "installing oh-my-bash"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
fi
