#!/usr/bin/env bash
# Swap windows between current workspace and a prompted target workspace

# Get current workspace
current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

# Prompt for target workspace using wofi
target_ws=$(echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9\n10" | wofi --dmenu --prompt "Swap with workspace:")

# Validate input
if [[ -z "$target_ws" ]] || ! [[ "$target_ws" =~ ^[0-9]+$ ]]; then
    notify-send "Swap Workspaces" "Invalid workspace number"
    exit 1
fi

# Don't swap with self
if [[ "$current_ws" == "$target_ws" ]]; then
    notify-send "Swap Workspaces" "Already on workspace $target_ws"
    exit 0
fi

# Get window addresses on current workspace
current_windows=$(hyprctl clients -j | jq -r --argjson ws "$current_ws" '.[] | select(.workspace.id == $ws) | .address')

# Get window addresses on target workspace
target_windows=$(hyprctl clients -j | jq -r --argjson ws "$target_ws" '.[] | select(.workspace.id == $ws) | .address')

# Move current workspace windows to target
for addr in $current_windows; do
    hyprctl dispatch movetoworkspacesilent "$target_ws,address:$addr"
done

# Move target workspace windows to current
for addr in $target_windows; do
    hyprctl dispatch movetoworkspacesilent "$current_ws,address:$addr"
done

notify-send "Swap Workspaces" "Swapped workspace $current_ws with $target_ws"
