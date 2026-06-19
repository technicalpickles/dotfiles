#!/usr/bin/env bash

# Show battery only when on battery power, OR when below 40% regardless of
# charging state. Hidden when plugged in and healthy.

source "$CONFIG_DIR/colors.sh"

batt=$(pmset -g batt)
percent=$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
power=$(printf '%s' "$batt" | grep -q "AC Power" && echo AC || echo BATTERY)

if [[ -z "$percent" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

show=0
color="$LABEL_COLOR"

if [[ "$power" == "BATTERY" ]]; then
  show=1
  if ((percent < 20)); then
    color="$ALERT_COLOR"
  elif ((percent < 40)); then
    color="$WARN_COLOR"
  fi
elif ((percent < 40)); then
  show=1
  color="$WARN_COLOR"
fi

if ((show)); then
  prefix="BAT"
  [[ "$power" == "AC" ]] && prefix="CHG"
  sketchybar --set "$NAME" \
    drawing=on \
    label="${prefix} ${percent}%" \
    label.color="$color"
else
  sketchybar --set "$NAME" drawing=off
fi
