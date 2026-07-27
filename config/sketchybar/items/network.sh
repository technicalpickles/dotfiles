#!/usr/bin/env bash

# Surfaces only when something is wrong: Wi-Fi off, or Tailscale expected-up
# but actually down.
sketchybar --add item network right \
  --set network \
  drawing=off \
  update_freq=30 \
  script="$PLUGIN_DIR/network.sh" \
  --subscribe network wifi_change system_woke
