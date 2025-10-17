#!/usr/bin/env bash

# Count clipboard items
count=$(cliphist list | wc -l)

# Get most recent item preview (first 50 chars)
recent=$(cliphist list | head -n1 | cut -c1-50 2>/dev/null || echo "")

if [ -z "$recent" ]; then
    recent="Empty"
fi

# Check if current clipboard is sensitive (with error handling)
current=$(wl-paste 2>/dev/null || echo "")

# Limit clipboard check to first 1000 chars to avoid crashes
current_trimmed=$(echo "$current" | head -c 1000)

if echo "$current_trimmed" | grep -iE "password|token|secret|key|AKIA" > /dev/null 2>&1; then
    class="sensitive"
    tooltip="🔒 Sensitive content in clipboard"
elif [ "$count" -eq 0 ]; then
    class="empty"
    tooltip="No clipboard history"
else
    class="has-items"
    # Escape tooltip for JSON safety
    tooltip_text=$(echo "Recent: ${recent}..." | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    tooltip="${tooltip_text}\\nTotal items: ${count}"
fi

printf '{"text":"📋","tooltip":"%s","class":"%s"}\n' "$tooltip" "$class"
