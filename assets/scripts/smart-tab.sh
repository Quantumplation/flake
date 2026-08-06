#!/usr/bin/env bash
# Cycle windows on current workspace, preserving fullscreen/monocle state

direction="${1:-next}"

# Get current window info
window_info=$(hyprctl activewindow -j)
fullscreen=$(echo "$window_info" | jq -r '.fullscreen')

# fullscreen values: 0 = not fullscreen, 1 = maximized/monocle, 2 = true fullscreen
if [[ "$fullscreen" != "0" ]]; then
    hyprctl dispatch fullscreen 0
    if [[ "$direction" == "prev" ]]; then
        hyprctl dispatch cyclenext prev
    else
        hyprctl dispatch cyclenext
    fi
    hyprctl dispatch fullscreen "$fullscreen"
else
    if [[ "$direction" == "prev" ]]; then
        hyprctl dispatch cyclenext prev
    else
        hyprctl dispatch cyclenext
    fi
fi
