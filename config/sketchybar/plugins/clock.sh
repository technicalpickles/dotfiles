#!/usr/bin/env bash

# Classic Mac clock: short weekday + day + 24-hour time.
sketchybar --set "$NAME" label="$(date '+%a %-d  %H:%M')"
