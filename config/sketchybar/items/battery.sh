#!/usr/bin/env bash

# Hidden by default; the plugin enables drawing only when relevant.
sketchybar --add item battery right \
  --set battery \
  drawing=off \
  update_freq=120 \
  script="$PLUGIN_DIR/battery.sh" \
  --subscribe battery system_woke power_source_change
