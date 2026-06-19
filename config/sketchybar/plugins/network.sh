#!/usr/bin/env bash

# Surface conditions:
#   - Wi-Fi off / not associated  -> "WIFI OFF" alert
#   - Tailscale CLI says state != Running and prefs are loadable -> "VPN OFF" alert
# Otherwise hidden. We don't show "everything's fine" — that's noise.
#
# Why scripted instead of an alias for Tailscale: aliases are display-only
# (see items/aliases.sh header). For state we actually want to see at a
# glance, a scripted item with a text label beats a mirrored icon because
# it can show a meaningful word ("VPN OFF") and color (alert red), and it
# can hide itself completely when the state is fine. The alias would be
# always visible and only convey "Tailscale is a thing that exists."

source "$CONFIG_DIR/colors.sh"

wifi_state="ok"
ssid=$(networksetup -getairportnetwork en0 2> /dev/null | awk -F': ' '/Current Wi-Fi Network/ {print $2}')
if [[ -z "$ssid" ]]; then
  power=$(networksetup -getairportpower en0 2> /dev/null | awk '{print $NF}')
  if [[ "$power" == "Off" ]]; then
    wifi_state="off"
  else
    # Wi-Fi on but not associated. Could be wired-only; only flag if no en0/en* IPv4 either.
    if ! ifconfig 2> /dev/null | grep -E '^\s*inet ' | grep -vq '127.0.0.1'; then
      wifi_state="disconnected"
    fi
  fi
fi

vpn_state="unknown"
ts_status=$(tailscale status --json 2> /dev/null)
if [[ -n "$ts_status" ]]; then
  state=$(printf '%s' "$ts_status" | /usr/local/bin/jq -r '.BackendState // empty' 2> /dev/null)
  case "$state" in
    Running) vpn_state="up" ;;
    Stopped | NeedsLogin | NoState) vpn_state="down" ;;
    *) vpn_state="unknown" ;;
  esac
fi

label=""
color="$LABEL_COLOR"

if [[ "$wifi_state" != "ok" ]]; then
  label="WIFI ${wifi_state^^}"
  color="$ALERT_COLOR"
elif [[ "$vpn_state" == "down" ]]; then
  label="VPN OFF"
  color="$WARN_COLOR"
fi

if [[ -n "$label" ]]; then
  sketchybar --set "$NAME" drawing=on label="$label" label.color="$color"
else
  sketchybar --set "$NAME" drawing=off
fi
