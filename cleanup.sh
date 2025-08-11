#!/usr/bin/env bash

set -ex

brew cleanup --prune=all

yarn cache clean --all
uv cache prune

if [[ -d ~/Library/Caches/com.spotify.client/ ]]; then
  osascript -e 'quit app "Spotify"'
  sleep 1
  trash ~/Library/Caches/com.spotify.client/
fi
