#!/usr/bin/env bash

# Classic-Mac-leaning palette: near-black bar, light text, no pills.
# Colors are 0xAARRGGBB.

export BAR_COLOR=0xff1d1d1f  # near-black, like macOS dark menu bar
export ICON_COLOR=0xffe5e5e7 # primary text/icon
export LABEL_COLOR=0xffe5e5e7
export DIM_COLOR=0xff8a8a8e # secondary, e.g. seconds, weekday

export ALERT_COLOR=0xfff7768e # battery low, vpn down
export WARN_COLOR=0xffe0af68  # battery medium-low, soon-meeting
export OK_COLOR=0xff9ece6a    # rarely used; reserved for affirmative state

# No pills by default. Set per-item if you want a background.
export ITEM_BG=0x00000000
