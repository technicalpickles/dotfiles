#!/usr/bin/env bash

# Volume only flashes briefly when changed; otherwise hidden.
sketchybar --add item volume right \
  --set volume \
  drawing=off \
  script="$PLUGIN_DIR/volume.sh" \
  --subscribe volume volume_change
