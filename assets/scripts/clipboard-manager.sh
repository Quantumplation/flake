#!/usr/bin/env bash

ACTION="${1:-menu}"

# Sensitive patterns to exclude (regex)
SENSITIVE_PATTERNS=(
    "ghp_[a-zA-Z0-9]{36}"           # GitHub tokens
    "ghs_[a-zA-Z0-9]{36}"           # GitHub secrets
    "gho_[a-zA-Z0-9]{36}"           # GitHub OAuth

    "sk-[a-zA-Z0-9]{48}"            # OpenAI API keys
    "[A-Za-z0-9+/]{40}={0,2}"       # Generic base64 tokens (40+ chars)

    "AKIA[0-9A-Z]{16}"              # AWS Access Key ID
    "[A-Za-z0-9/+=]{40}"            # AWS Secret Access Key (40 characters)
    "aws_secret_access_key"
    "aws_access_key_id"
    "(?i)aws.*key"

    "password|passwd|secret|token|api[_-]?key"  # Common sensitive words
)

# Clipboard snippets (for quick access)
case "$ACTION" in
    "menu")
        # Get clipboard history
        history=$(cliphist list)
    
        # Color sensitive items red using Pango markup
        colored_history=""
        while IFS= read -r line; do
            is_sensitive=false
            for pattern in "${SENSITIVE_PATTERNS[@]}"; do
                if echo "$line" | grep -iE "$pattern" > /dev/null; then
                    is_sensitive=true
                    break
                fi
            done
    
            if [ "$is_sensitive" = true ]; then
                # Add red color to sensitive items
                colored_history+="<span foreground='#f38ba8'>🔒 $line</span>"$'\n'
            else
                colored_history+="$line"$'\n'
            fi
        done <<< "$history"
    
        # Show in wofi with markup enabled
        selection=$(echo "$colored_history" | wofi --dmenu --prompt "Clipboard" --height 400 --markup)
    
        if [ -n "$selection" ]; then
            # Strip Pango markup and lock icon for processing
            clean_selection=$(echo "$selection" | sed 's/<[^>]*>//g' | sed 's/^🔒 //')
    
            # Check if it's sensitive and ask for confirmation
            is_sensitive=false
            for pattern in "${SENSITIVE_PATTERNS[@]}"; do
                if echo "$clean_selection" | grep -iE "$pattern" > /dev/null; then
                    is_sensitive=true
                    break
                fi
            done
    
            if [ "$is_sensitive" = true ]; then
                # Ask for confirmation
                confirm=$(echo -e "Yes\nNo" | wofi --dmenu --prompt "⚠️  Paste sensitive content?" --height 150)
                if [ "$confirm" != "Yes" ]; then
                    notify-send "Clipboard" "🔒 Paste cancelled"
                    exit 0
                fi
            fi
    
            # Copy to clipboard and simulate paste
            echo "$clean_selection" | cliphist decode | wl-copy
            sleep 0.1
            wtype -M ctrl -P v -m ctrl -p v
        fi
        ;;
    
    "snippets")
        # Custom snippets menu
        snippets=(
            "📅 30 Minute Meeting|https://calendar.app.google/T3KuS6oMuqHU9YxV7"
            "📅 60 Minute Meeting|https://calendar.app.google/Ak7As4fQ61taQqnz9"
        )
        
        selection=$(printf '%s\n' "${snippets[@]}" | cut -d'|' -f1 | wofi --dmenu --prompt "Snippets" --height 300)
        
        if [ -n "$selection" ]; then
            # Find matching snippet and copy value
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
    
    "clear-old")
        # Clear entries older than 24 hours
        cliphist list | head -n 100 | cliphist store
        notify-send "Clipboard" "Cleared old entries"
        ;;
    
    "clear-all")
        cliphist wipe
        notify-send "Clipboard" "Cleared all clipboard history"
        ;;
    
    "filter-check")
        # Background task: periodically check and remove sensitive data
        while true; do
            current_clip=$(wl-paste 2>/dev/null)
            for pattern in "${SENSITIVE_PATTERNS[@]}"; do
                if echo "$current_clip" | grep -iE "$pattern" > /dev/null; then
                    # Wait 30 seconds, then clear
                    sleep 90
                    wl-copy --clear
                    notify-send "Clipboard" "🔒 Auto-cleared sensitive content"
                    break
                fi
            done
            sleep 10
        done
        ;;
esac
