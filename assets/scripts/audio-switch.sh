#!/usr/bin/env bash

# Audio Device Switcher
# Supports cycling through devices or wofi selection

MODE="${1:-wofi}"

# Devices to skip (add patterns here, case-insensitive)
SKIP_PATTERNS=("HDMI")

# Get list of audio sinks
get_sinks() {
    local all_sinks
    # Strip │, *, and whitespace, keep just "ID. Name"
    all_sinks=$(wpctl status | awk '/Sinks:/,/Sources:/ {print}' | grep -E "│.*[0-9]+\." | sed 's/.*│[[:space:]]*\*\?[[:space:]]*//')

    # Filter out unwanted devices
    local filtered=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi

        local skip=false
        for pattern in "${SKIP_PATTERNS[@]}"; do
            if echo "$line" | grep -qi "$pattern"; then
                skip=true
                break
            fi
        done

        if [ "$skip" = false ]; then
            filtered+="$line"$'\n'
	fi
    done <<< "$all_sinks"
    echo "$filtered"
}

# Get current default sink ID
get_current_sink() {
    wpctl status | awk '/Sinks:/,/Sources:/ {print}' | grep '\*' | grep -oP '[0-9]+' | head -1
}

# Get sink name from ID
get_sink_name() {
    wpctl status | awk '/Sinks:/,/Sources:/ {print}' | grep "│.*$1\." | sed 's/.*│[[:space:]]*\*\?[[:space:]]*//' | sed 's/^[0-9]*\. //' | sed 's/ \[.*\]$//'
}

# Set default sink
set_sink() {
    wpctl set-default "$1"
    local sink_name
    sink_name=$(get_sink_name "$1")
    notify-send "Audio Output" "Switched to: $sink_name" -t 2000
}

if [ "$MODE" = "cycle" ]; then
    mapfile -t sink_ids < <(get_sinks | grep -oP '^[0-9]+')

    if [ ${#sink_ids[@]} -eq 0 ]; then
        notify-send "Audio Output" "No audio devices found" -t 2000
        exit 1
    fi

    current=$(get_current_sink)
    found_current=false
    next_sink=""

    for sink in "${sink_ids[@]}"; do
        if [ "$found_current" = true ]; then
            next_sink="$sink"
            break
        fi
        if [ "$sink" = "$current" ]; then
            found_current=true
        fi
    done

    if [ -z "$next_sink" ]; then
        next_sink="${sink_ids[0]}"
    fi

    set_sink "$next_sink"

elif [ "$MODE" = "wofi" ] || [ "$MODE" = "select" ]; then
    sinks=$(get_sinks)

    if [ -z "$sinks" ]; then
        notify-send "Audio Output" "No audio devices found" -t 2000
        exit 1
    fi

    current=$(get_current_sink)
    formatted_list=""

    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi

        id=$(echo "$line" | grep -oP '^[0-9]+')
        name=$(echo "$line" | sed 's/^[0-9]*\. //' | sed 's/ \[.*\]$//')

        if [ "$id" = "$current" ]; then
            formatted_list+="✓ $name|$id\n"
        else
            formatted_list+="  $name|$id\n"
        fi
    done <<< "$sinks"

    selected=$(echo -e "$formatted_list" | wofi --dmenu --prompt "Select Audio Output" | cut -d'|' -f2)

    if [ -n "$selected" ]; then
        set_sink "$selected"
    fi

elif [ "$MODE" = "list" ]; then
    echo "Available audio devices:"
    current=$(get_current_sink)

    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi

        id=$(echo "$line" | grep -oP '^[0-9]+')
        name=$(echo "$line" | sed 's/^[0-9]*\. //' | sed 's/ \[.*\]$//')

        if [ "$id" = "$current" ]; then
            echo "✓ $name (ID: $id)"
        else
            echo "  $name (ID: $id)"
        fi
    done <<< "$(get_sinks)"

else
    cat << 'EOF'
Audio Device Switcher

Usage: audio-switch [mode]

Modes:
  wofi    Show device selector menu (default)
  cycle   Cycle to next audio device
  list    List available devices

Examples:
  audio-switch          # Show wofi menu
  audio-switch wofi     # Show wofi menu
  audio-switch cycle    # Cycle to next device
  audio-switch list     # List all devices

EOF
fi

