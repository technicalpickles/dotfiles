#!/usr/bin/env bash

# On volume_change, $INFO is the new volume (0-100).
# Show briefly, then hide after a few seconds so the bar stays quiet.

if [[ "$SENDER" != "volume_change" ]]; then
  exit 0
fi

vol="$INFO"
label="VOL ${vol}%"
[[ "$vol" -eq 0 ]] && label="MUTE"

sketchybar --set "$NAME" drawing=on label="$label"

# Hide again after 2.5s. The trigger is fire-and-forget; if another change
# arrives first it just resets the visible label.
(sleep 2.5 && sketchybar --set "$NAME" drawing=off) &
disown
