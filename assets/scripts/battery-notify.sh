#!/usr/bin/env bash
# Battery notification daemon - sends warnings at low battery levels
# Works alongside UPower which handles the actual hibernate action

BATTERY_PATH="/sys/class/power_supply/BAT1"
LOW_THRESHOLD=20        # First warning
CRITICAL_THRESHOLD=15   # Urgent warning
ACTION_THRESHOLD=10     # Final warning before hibernate

WARNED_LOW=false
WARNED_CRITICAL=false
WARNED_ACTION=false

while true; do
    if [[ -f "$BATTERY_PATH/capacity" ]]; then
        capacity=$(cat "$BATTERY_PATH/capacity")
        status=$(cat "$BATTERY_PATH/status")

        # Only warn when discharging
        if [[ "$status" == "Discharging" ]]; then
            if [[ $capacity -le $ACTION_THRESHOLD ]] && [[ "$WARNED_ACTION" == "false" ]]; then
                notify-send -u critical "HIBERNATING NOW: ${capacity}%" \
                    "System is hibernating to save your work!" \
                    -i battery-empty -t 0
                WARNED_ACTION=true
            elif [[ $capacity -le $CRITICAL_THRESHOLD ]] && [[ "$WARNED_CRITICAL" == "false" ]]; then
                notify-send -u critical "Battery Critical: ${capacity}%" \
                    "System will hibernate at 10%. Plug in NOW!" \
                    -i battery-empty -t 0
                WARNED_CRITICAL=true
            elif [[ $capacity -le $LOW_THRESHOLD ]] && [[ "$WARNED_LOW" == "false" ]]; then
                notify-send -u normal "Battery Low: ${capacity}%" \
                    "Consider plugging in your charger" \
                    -i battery-low -t 10000
                WARNED_LOW=true
            fi

            # Poll faster when battery is low
            if [[ $capacity -le $CRITICAL_THRESHOLD ]]; then
                sleep 15
            elif [[ $capacity -le $LOW_THRESHOLD ]]; then
                sleep 30
            else
                sleep 60
            fi
        else
            # Reset warnings when charging
            WARNED_LOW=false
            WARNED_CRITICAL=false
            WARNED_ACTION=false
            sleep 60
        fi
    else
        sleep 60
    fi
done
