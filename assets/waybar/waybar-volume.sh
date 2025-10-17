#!/usr/bin/env bash

# Get current volume and mute status
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
vol_percent=$(echo "$volume" | awk '{print int($2 * 100)}')
is_muted=$(echo "$volume" | grep -o "MUTED" || echo "")

# Get current sink name
current_sink=$(wpctl status | awk '/Sinks:/,/Sources:/ {print}' | grep '\*' | sed 's/.*│[[:space:]]*\*[[:space:]]*//' | sed 's/^[0-9]*\. //' | sed 's/ \[.*\]$//')

# Shorten device name for display
short_name="$current_sink"
if echo "$current_sink" | grep -qi "rode"; then
    short_name="RODE"
elif echo "$current_sink" | grep -qi "starship\|matisse"; then
    short_name="Speakers"
elif echo "$current_sink" | grep -qi "headphone\|headset"; then
    short_name="Headphones"
fi

# Choose icon based on volume level and mute status
if [ -n "$is_muted" ]; then
    icon="󰝟"
    class="muted"
elif [ "$vol_percent" -ge 70 ]; then
    icon="󰕾"
    class="high"
elif [ "$vol_percent" -ge 30 ]; then
    icon="󰖀"
    class="medium"
else
    icon="󰕿"
    class="low"
fi

# Output JSON for waybar (single line!)
printf '{"text":"%s %s%%","tooltip":"%s\\nVolume: %s%%%s","class":"%s","percentage":%s}\n' \
    "$icon" "$vol_percent" "$short_name" "$vol_percent" "${is_muted:+\\n(Muted)}" "$class" "$vol_percent"

