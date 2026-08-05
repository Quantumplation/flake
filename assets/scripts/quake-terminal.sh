#!/usr/bin/env bash
# Toggle quake-style dropdown terminal via Hyprland special workspace
# Spawns a ghostty on first use, then just toggles visibility

QUAKE_TITLE="QuakeTerminal"

# Check if a quake terminal window exists anywhere
window_exists=$(hyprctl clients -j | jq -r ".[] | select(.title == \"$QUAKE_TITLE\") | .address" | head -1) || true

if [ -z "${window_exists:-}" ]; then
    # First use — spawn with inline rules, then move to special workspace
    hyprctl dispatch exec "[float;size 100% 50%;move 0 0]" "ghostty --title=$QUAKE_TITLE --shell-integration-features=cursor,sudo" || true
    sleep 0.5
    hyprctl dispatch movetoworkspacesilent "special:quake,title:$QUAKE_TITLE" || true
fi

hyprctl dispatch togglespecialworkspace quake || true
