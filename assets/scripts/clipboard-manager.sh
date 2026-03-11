#!/usr/bin/env bash

ACTION="${1:-menu}"

case "$ACTION" in
    "menu")
        selection=$(cliphist list | wofi --dmenu --prompt "Clipboard" --height 400)

        if [ -n "$selection" ]; then
            echo "$selection" | cliphist decode | wl-copy
            sleep 0.1
            wtype -M ctrl -P v -m ctrl -p v
        fi
        ;;

    "snippets")
        snippets=(
            "📅 30 Minute Meeting|https://calendar.app.google/T3KuS6oMuqHU9YxV7"
            "📅 60 Minute Meeting|https://calendar.app.google/Ak7As4fQ61taQqnz9"
        )

        selection=$(printf '%s\n' "${snippets[@]}" | cut -d'|' -f1 | wofi --dmenu --prompt "Snippets" --height 300)

        if [ -n "$selection" ]; then
            for snippet in "${snippets[@]}"; do
                label=$(echo "$snippet" | cut -d'|' -f1)
                value=$(echo "$snippet" | cut -d'|' -f2)
                if [ "$label" = "$selection" ]; then
                    echo "$value" | wl-copy
                    notify-send "Clipboard" "Copied: $value"
                    break
                fi
            done
        fi
        ;;

    "clear-all")
        cliphist wipe
        notify-send "Clipboard" "Cleared all clipboard history"
        ;;
esac
