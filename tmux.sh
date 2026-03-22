#!/usr/bin/env bash

echo "🔳 configuring tmux"
tpm_destination="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_destination" ]]; then
  echo "🔳 cloning tpm"
  git clone https://github.com/tmux-plugins/tpm "$tpm_destination"
fi

echo "🔳 reloading/reinstalling tmux"
tmux source ~/.tmux.conf 2> /dev/null || true
