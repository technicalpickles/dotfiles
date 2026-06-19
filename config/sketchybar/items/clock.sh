#!/usr/bin/env bash

sketchybar --add item clock right \
  --set clock \
  update_freq=10 \
  icon.drawing=off \
  script="$PLUGIN_DIR/clock.sh" \
  click_script="open -a 'Google Calendar'"
