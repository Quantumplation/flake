#!/usr/bin/env bash

LIGHT_IP="192.168.12.114"
LIGHT_PORT="9123"

# Try to get light status
response=$(curl -s -m 2 "http://${LIGHT_IP}:${LIGHT_PORT}/elgato/lights" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$response" ]; then
    # Light is off or unreachable
    printf '{"text":"󰛨","tooltip":"Key Light: Off/Unreachable","class":"off"}\n'
    exit 0
fi

# Parse JSON response
on=$(echo "$response" | grep -o '"on":[0-9]' | cut -d':' -f2)
brightness=$(echo "$response" | grep -o '"brightness":[0-9]*' | cut -d':' -f2)
temp=$(echo "$response" | grep -o '"temperature":[0-9]*' | cut -d':' -f2)

# Convert temperature value to Kelvin (approximate)
kelvin=$((1000000 / temp))

# Round to nearest 50
kelvin=$(( (kelvin + 25) / 50 * 50 ))

if [ "$on" = "1" ]; then
    # Choose icon based on brightness
    if [ "$brightness" -ge 75 ]; then
        icon="󰛨"
    elif [ "$brightness" -ge 50 ]; then
        icon="󱩖"
    elif [ "$brightness" -ge 25 ]; then
        icon="󱩕"
    else
        icon="󱩔"
    fi
    
    class="on"
    text="$icon $brightness%"
    tooltip="Key Light: On\\nBrightness: $brightness%\\nTemp: ${kelvin}K"
else
    icon="󰛨"
    class="off"
    text="$icon"
    tooltip="Key Light: Off"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
    "$text" "$tooltip" "$class" "$brightness"
