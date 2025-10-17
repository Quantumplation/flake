#!/usr/bin/env bash

# This script is used to find the next workspace ID in the focused monitor

# Get the focused workspace and monitor
focusedWorkspace=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}' | head -n 1 | sed 's/.*\([0-9]\)$/\1/')
focusedMonitor=$(hyprctl activeworkspace | grep "monitorID" | awk '{print $2}')

# Get the workspaces ID in the focused monitor
mapfile -t workspaces < <(hyprctl workspaces | grep -B1 "monitorID: $focusedMonitor" | grep 'workspace ID' | awk '{print $3}' | sed -e 's|[^0-9]||g' -e '/^[[:space:]]*$/d' -e 's/^1\([0-9]\)$/\1/' -e 's/^1\([1-9][0-9]\)$/\1/')

# Find the index of current_workspace in the workspace array
index=1
for ((i=0; i<${#workspaces[@]}; i++)); do
    if [[ "${workspaces[i]}" == "$focusedWorkspace" ]]; then
        index=$i
        break
    fi
done

# Calculate the index of the next workspace
next_index=$(( (index + 1) % ${#workspaces[@]} ))

# Echo the next workspace ID
echo "${workspaces[next_index]}"
