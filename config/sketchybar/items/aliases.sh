#!/usr/bin/env bash

# Mirror native macOS menu bar items inside sketchybar.
#
# ============================================================================
# IMPORTANT: ALIASES ARE DISPLAY-ONLY.
# ============================================================================
# This was the dealbreaker for the original goal. Aliases render the visual
# of a native NSStatusItem via Screen Recording, but they do NOT forward
# clicks to the underlying item. Clicking does nothing.
#
# Confirmed by the maintainer:
#   https://github.com/FelixKratz/SketchyBar/issues/510
# Click forwarding would require a separate Accessibility-API binary the
# maintainer has built but not published. Granting Accessibility permission
# to sketchybar does NOT help -- there is no code path that uses it.
#
# So this file's items work as state indicators (you can see if Tailscale is
# connected, if 1Password is locked, if Dropbox is syncing) but they cannot
# replace the click-driven Bartender experience. For interactivity, the
# native menu bar (top-edge hover when auto-hidden) is still required.
#
# If you revisit: consider dropping aliases entirely and surfacing the same
# state via scripted items (e.g., network.sh already shows Tailscale state
# without needing the alias).
#
# ============================================================================
# Mechanics
# ============================================================================
# Requires Screen Recording permission for sketchybar. Names come from:
#   sketchybar --query default_menu_items
# Some names include per-machine UUIDs (1Password, some Raycast extensions),
# so we discover those dynamically at config load instead of hardcoding.
#
# Add order is right-to-left within the bar's right region. First added
# becomes the rightmost alias.

source "$CONFIG_DIR/colors.sh"

add_alias() {
  local name="$1"
  [[ -z "$name" ]] && return 0
  sketchybar --add alias "$name" right \
    --set "$name" \
    icon.padding_left=2 \
    icon.padding_right=2 \
    label.drawing=off \
    background.color="$ITEM_BG" \
    background.height=22 > /dev/null 2>&1 \
    || echo "sketchybar: alias '$name' not present" >&2
}

# System: rightmost cluster (closest to conditional alerts).
add_alias "Spotlight,Item-0"
add_alias "Control Center,BentoBox"

# Apps with useful popovers.
add_alias "Tailscale,Item-0"

# 1Password's status item is named "1Password,<uuid>". Discover it.
ONEPW_NAME=$(sketchybar --query default_menu_items 2> /dev/null \
  | /usr/local/bin/jq -r '.[]' 2> /dev/null \
  | grep -m1 '^1Password,' || true)
add_alias "$ONEPW_NAME"

# Background tools (set-and-forget; surface only because they sometimes have
# meaningful state or you occasionally click in).
add_alias "superwhisper,Item-0"
add_alias "Hammerspoon,Item-0"
add_alias "Karabiner-Menu,Item-0"
add_alias "HazelHelper,Item-0"
add_alias "MacBreakZ 5,Item-0"
add_alias "Google Drive,Item-0"
add_alias "Dropbox,Item-0"
