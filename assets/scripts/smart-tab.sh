#!/usr/bin/env bash
# Smart tab switcher for Hyprland
# - In fullscreen/monocle mode: cycle through windows on current workspace (keeping monocle)
# - Otherwise: switch to next/previous workspace

direction="${1:-next}"

# Get current window info
window_info=$(hyprctl activewindow -j)
fullscreen=$(echo "$window_info" | jq -r '.fullscreen')

# fullscreen values: 0 = not fullscreen, 1 = maximized/monocle, 2 = true fullscreen
if [[ "$fullscreen" != "0" ]]; then
    # In fullscreen/monocle mode - cycle windows and keep monocle mode
    fullscreen_mode="$fullscreen"

    # First, exit fullscreen on current window
    hyprctl dispatch fullscreen 0

    # Cycle to next/prev window
    if [[ "$direction" == "prev" ]]; then
        hyprctl dispatch cyclenext prev
    else
        hyprctl dispatch cyclenext
    fi

    # Put the new window into the same fullscreen mode
    hyprctl dispatch fullscreen "$fullscreen_mode"
else
    # Not fullscreen - switch workspaces
    if [[ "$direction" == "prev" ]]; then
        hyprctl dispatch workspace e-1
    else
        hyprctl dispatch workspace e+1
    fi
fi
