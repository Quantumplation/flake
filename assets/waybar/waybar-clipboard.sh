#!/usr/bin/env bash

# Count clipboard items
count=$(cliphist list | wc -l)

if [ "$count" -eq 0 ]; then
    tooltip="No clipboard history"
    class="empty"
else
    recent=$(cliphist list | head -n1 | cut -c1-50 2>/dev/null || echo "")
    tooltip_text=$(echo "Recent: ${recent}..." | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    tooltip="${tooltip_text}\\nTotal items: ${count}"
    class="has-items"
fi

printf '{"text":"📋","tooltip":"%s","class":"%s"}\n' "$tooltip" "$class"
