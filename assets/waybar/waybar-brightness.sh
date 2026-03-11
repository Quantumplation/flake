#!/usr/bin/env bash

# Get current brightness percentage
brightness=$(brightnessctl info | grep -oP '\(\K[0-9]+(?=%\))')

# Choose icon based on brightness level
if [ "$brightness" -ge 80 ]; then
    icon="󰃠"
    class="high"
elif [ "$brightness" -ge 50 ]; then
    icon="󰃟"
    class="medium"
elif [ "$brightness" -ge 20 ]; then
    icon="󰃞"
    class="low"
else
    icon="󰃝"
    class="dim"
fi

# Output JSON for waybar
printf '{"text":"%s %s%%","tooltip":"Brightness: %s%%","class":"%s","percentage":%s}\n' \
    "$icon" "$brightness" "$brightness" "$class" "$brightness"
