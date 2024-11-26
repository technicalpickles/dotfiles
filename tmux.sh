#!/usr/bin/env bash

echo "🔳 configuring tmux"
tpm_destination="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_destination" ]]; then
    echo "🔳 cloning tpm"
    git clone https://github.com/tmux-plugins/tpm "$tpm_destination"
fi

"$tpm_destination/bin/install_plugins"

if [[ -n "$TMUX" ]]; then
    echo "🔳 reloading tmux"
    tmux source-file ~/.tmux.conf
fi
