#!/usr/bin/env bash

# Shows the next meeting only when it starts within ~10 minutes.
sketchybar --add item calendar right \
  --set calendar \
  drawing=off \
  update_freq=60 \
  script="$PLUGIN_DIR/calendar.sh" \
  --subscribe calendar system_woke
