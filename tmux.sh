#!/usr/bin/env bash

echo "🔳 configuring tmux"
tpm_destination="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_destination" ]]; then
  echo "🔳 cloning tpm"
  git clone https://github.com/tmux-plugins/tpm "$tpm_destination"
fi

echo "🔳 installing tmux plugins"
"$tpm_destination/bin/install_plugins"

if tmux info &> /dev/null; then
  echo "🔳 reloading tmux config"
  tmux source ~/.tmux.conf
fi
