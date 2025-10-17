#!/usr/bin/env bash

# GitHub token from SOPS
# Path is deterministic based on secret name in packages/sops.nix
TOKEN_FILE="/run/secrets/github/notifications"

# Check if token file exists
if [ ! -f "$TOKEN_FILE" ]; then
    printf '{"text":"","tooltip":"GitHub: No token configured\\nSecret not found at %s","class":"error"}\n' "$TOKEN_FILE"
    exit 0
fi

# Read token from file
GITHUB_TOKEN=$(cat "$TOKEN_FILE")

if [ -z "$GITHUB_TOKEN" ]; then
    printf '{"text":"","tooltip":"GitHub: Token file is empty","class":"error"}\n'
    exit 0
fi

# Cache file to track previous count
CACHE_FILE="$HOME/.cache/waybar-github-count"

# Fetch notifications
response=$(curl -s -m 5 \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/notifications" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$response" ]; then
    printf '{"text":"","tooltip":"GitHub: API unavailable","class":"error"}\n'
    exit 0
fi

# Count notifications
count=$(echo "$response" | grep -o '"id":' | wc -l)

# Read previous count
prev_count=0
if [ -f "$CACHE_FILE" ]; then
    prev_count=$(cat "$CACHE_FILE")
fi

# Save current count
echo "$count" > "$CACHE_FILE"

# Send notification if count increased
if [ "$count" -gt "$prev_count" ] && [ "$prev_count" -gt 0 ]; then
    new_count=$((count - prev_count))
    notify-send "GitHub" "You have $new_count new notification(s)" -t 5000 -u normal
fi

# Format output
if [ "$count" -eq 0 ]; then
    text="󰊤"  # GitHub icon, dimmed via CSS
    tooltip="GitHub: No notifications"
    class="none"
else
    text="󰊤 $count"  # GitHub icon with count
    tooltip="GitHub: $count notification(s)"
    class="has-notifications"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"

