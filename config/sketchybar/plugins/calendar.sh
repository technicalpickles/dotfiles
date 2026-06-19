#!/usr/bin/env bash

# Surface the next meeting only if it starts within MEETING_SOON_MIN minutes,
# OR if a meeting is currently happening. Otherwise hidden.
#
# Uses icalBuddy. If you change account/calendar selection, edit the args below.

source "$CONFIG_DIR/colors.sh"

ICAL=/usr/local/bin/icalBuddy
MEETING_SOON_MIN=10
TRUNCATE=28

if [[ ! -x "$ICAL" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Pull today's events in a parseable format. -nc strips section headers,
# -nrd kills the relative-date header, -b "" removes leading bullets.
events=$("$ICAL" \
  -nc -nrd -b "" \
  -iep "title,datetime" \
  -po "datetime,title" \
  -df "%Y-%m-%dT%H:%M" \
  -tf "%Y-%m-%dT%H:%M" \
  eventsToday 2> /dev/null)

if [[ -z "$events" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

now_epoch=$(date +%s)

# icalBuddy emits roughly:
#   2026-05-08T14:00 - 2026-05-08T14:30
#       Standup
# We grep for the start timestamp + the next non-empty line as the title.
next_start=""
next_title=""
prev_line=""
while IFS= read -r line; do
  if [[ "$prev_line" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2})[[:space:]]-[[:space:]]([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}) ]]; then
    start="${BASH_REMATCH[1]}"
    end="${BASH_REMATCH[2]}"
    title=$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
    [[ -z "$title" ]] && {
      prev_line="$line"
      continue
    }

    start_epoch=$(date -j -f "%Y-%m-%dT%H:%M" "$start" +%s 2> /dev/null)
    end_epoch=$(date -j -f "%Y-%m-%dT%H:%M" "$end" +%s 2> /dev/null)
    [[ -z "$start_epoch" || -z "$end_epoch" ]] && {
      prev_line="$line"
      continue
    }

    if ((now_epoch >= start_epoch && now_epoch < end_epoch)); then
      next_start="$start_epoch"
      next_title="$title"
      break
    fi

    if ((start_epoch > now_epoch)); then
      next_start="$start_epoch"
      next_title="$title"
      break
    fi
  fi
  prev_line="$line"
done <<< "$events"

if [[ -z "$next_start" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

minutes_until=$(((next_start - now_epoch) / 60))

if ((minutes_until < 0)); then
  prefix="NOW"
  color="$ALERT_COLOR"
elif ((minutes_until <= MEETING_SOON_MIN)); then
  prefix="${minutes_until}m"
  color="$WARN_COLOR"
else
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

short_title="$next_title"
if ((${#short_title} > TRUNCATE)); then
  short_title="${short_title:0:TRUNCATE}…"
fi

sketchybar --set "$NAME" \
  drawing=on \
  label="${prefix}  ${short_title}" \
  label.color="$color"
