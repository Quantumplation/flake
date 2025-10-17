#!/usr/bin/env bash

# Elgato Key Light Control Script
# Configure your light's IP address here
LIGHT_IP="192.168.12.114"
LIGHT_PORT="9123"
API_URL="http://${LIGHT_IP}:${LIGHT_PORT}/elgato/lights"

# Function to convert Kelvin to Elgato temperature value
# Formula: temp_value = 1000000 / kelvin
kelvin_to_temp() {
    echo $((1000000 / $1))
}

# Function to get current light state
get_state() {
    curl -s "$API_URL"
}

# Function to set light state
set_state() {
    local on=$1
    local brightness=$2
    local temperature=$3
    
    curl -s -X PUT "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"numberOfLights\":1,\"lights\":[{\"on\":${on},\"brightness\":${brightness},\"temperature\":${temperature}}]}" \
        > /dev/null
}

# Get current state for commands that need it
current_state=$(get_state)
current_on=$(echo "$current_state" | grep -o '"on":[0-9]' | cut -d':' -f2)
current_brightness=$(echo "$current_state" | grep -o '"brightness":[0-9]*' | cut -d':' -f2)
current_temp=$(echo "$current_state" | grep -o '"temperature":[0-9]*' | cut -d':' -f2)

case "$1" in
    on)
        # Turn on with current or default settings
        brightness=${2:-${current_brightness:-50}}
        temp=${3:-${current_temp:-222}}
        set_state 1 "$brightness" "$temp"
        echo "Light turned on (brightness: $brightness, temp: $temp)"
        ;;
    
    off)
        set_state 0 "$current_brightness" "$current_temp"
        echo "Light turned off"
        ;;
    
    toggle)
        if [ "$current_on" = "1" ]; then
            set_state 0 "$current_brightness" "$current_temp"
            echo "Light turned off"
        else
            set_state 1 "${current_brightness:-50}" "${current_temp:-222}"
            echo "Light turned on"
        fi
        ;;
    
    brightness|bright|b)
        brightness=${2:-50}
        if [ "$brightness" -lt 3 ] || [ "$brightness" -gt 100 ]; then
            echo "Error: Brightness must be between 3 and 100"
            exit 1
        fi
        set_state "${current_on:-1}" "$brightness" "${current_temp:-222}"
        echo "Brightness set to $brightness%"
        ;;
    
    brighter|+)
        new_brightness=$((current_brightness + ${2:-10}))
        [ "$new_brightness" -gt 100 ] && new_brightness=100
        set_state "${current_on:-1}" "$new_brightness" "${current_temp:-222}"
        echo "Brightness increased to $new_brightness%"
        ;;
    
    dimmer|-)
        new_brightness=$((current_brightness - ${2:-10}))
        [ "$new_brightness" -lt 3 ] && new_brightness=3
        set_state "${current_on:-1}" "$new_brightness" "${current_temp:-222}"
        echo "Brightness decreased to $new_brightness%"
        ;;
    
    temperature|temp|t)
        kelvin=${2:-4500}
        if [ "$kelvin" -lt 2900 ] || [ "$kelvin" -gt 7000 ]; then
            echo "Error: Temperature must be between 2900K and 7000K"
            exit 1
        fi
        temp_value=$(kelvin_to_temp "$kelvin")
        set_state "${current_on:-1}" "${current_brightness:-50}" "$temp_value"
        echo "Temperature set to ${kelvin}K"
        ;;
    
    warmer|w)
        # Decrease temp value = higher Kelvin = cooler
        # So "warmer" means increase temp value = lower Kelvin
        new_temp=$((current_temp + ${2:-15}))
        [ "$new_temp" -gt 344 ] && new_temp=344  # 2900K limit
        set_state "${current_on:-1}" "${current_brightness:-50}" "$new_temp"
        approx_kelvin=$((1000000 / new_temp))
        echo "Temperature warmer (~${approx_kelvin}K)"
        ;;
    
    cooler|c)
        # Increase Kelvin = decrease temp value
        new_temp=$((current_temp - ${2:-15}))
        [ "$new_temp" -lt 143 ] && new_temp=143  # 7000K limit
        set_state "${current_on:-1}" "${current_brightness:-50}" "$new_temp"
        approx_kelvin=$((1000000 / new_temp))
        echo "Temperature cooler (~${approx_kelvin}K)"
        ;;
    
    status|s)
        echo "Current light state:"
        echo "$current_state" | jq '.' 2>/dev/null || echo "$current_state"
        if [ "$current_on" = "1" ]; then
            approx_kelvin=$((1000000 / current_temp))
            echo ""
            echo "Status: ON"
            echo "Brightness: ${current_brightness}%"
            echo "Temperature: ~${approx_kelvin}K"
        else
            echo ""
            echo "Status: OFF"
        fi
        ;;
    
    preset)
        case "$2" in
            recording|rec)
                set_state 1 75 222  # 4500K, 75% brightness
                echo "Preset: Recording (75%, 4500K)"
                ;;
            meeting|meet)
                set_state 1 50 200  # 5000K, 50% brightness
                echo "Preset: Meeting (50%, 5000K)"
                ;;
            evening|night)
                set_state 1 30 300  # 3333K, 30% brightness
                echo "Preset: Evening (30%, warm)"
                ;;
            daytime|day)
                set_state 1 80 182  # 5500K, 80% brightness
                echo "Preset: Daytime (80%, 5500K)"
                ;;
            *)
                echo "Available presets: recording, meeting, evening, daytime"
                exit 1
                ;;
        esac
        ;;
    
    help|--help|-h|"")
        cat << EOF
Elgato Key Light Control

Usage: keylight <command> [options]

Commands:
  on [brightness] [temp]  Turn light on (optional: set brightness & temp value)
  off                     Turn light off
  toggle                  Toggle light on/off
  
  brightness <3-100>      Set brightness (also: bright, b)
  brighter [amount]       Increase brightness (default: +10)
  dimmer [amount]         Decrease brightness (default: -10)
  
  temperature <2900-7000> Set color temperature in Kelvin (also: temp, t)
  warmer [amount]         Make temperature warmer (default: 15)
  cooler [amount]         Make temperature cooler (default: 15)
  
  preset <name>           Apply preset (recording, meeting, evening, daytime)
  status                  Show current light state (also: s)
  
Examples:
  keylight on                    # Turn on with current/default settings
  keylight on 75 4500            # Turn on at 75% brightness, 4500K
  keylight brightness 50         # Set to 50% brightness
  keylight temp 5500             # Set to 5500K (cool daylight)
  keylight brighter              # Increase brightness by 10%
  keylight toggle                # Toggle on/off
  keylight preset recording      # Use recording preset

Temperature Guide:
  2900K - Warm (sunset, candlelight)
  4500K - Neutral (balanced)
  5500K - Cool (daylight)
  7000K - Very cool (overcast day)

EOF
        ;;
    
    *)
        echo "Unknown command: $1"
        echo "Run 'keylight help' for usage information"
        exit 1
        ;;
esac
