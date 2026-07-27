#!/usr/bin/env bash

# $INFO is the new app name on front_app_switched events.
if [[ "$SENDER" == "front_app_switched" ]]; then
  sketchybar --set "$NAME" label="$INFO"
fi
