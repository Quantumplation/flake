#!/usr/bin/env bash
# Capture a thought to the inbox.
# wofi prompt prefilled with primary selection (Wayland highlight-to-select),
# with recent captures listed below for context. POSTs to $INBOX_URL; on
# failure queues locally so captures are never lost.

set -euo pipefail

INBOX_URL="${INBOX_URL:-http://goldwasser:8765/capture}"
QUEUE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/inbox"
QUEUE_FILE="$QUEUE_DIR/queue.tsv"
RECENT_LIMIT=10
# Sentinel doubles as the default-highlighted item when there's no prefill,
# so a stray Enter doesn't re-capture the most recent entry.
SENTINEL="✏️  Type a new capture..."
mkdir -p "$QUEUE_DIR"

# Primary selection is the highlight-to-select buffer — fresh by definition.
prefill=""
if raw=$(wl-paste --primary --no-newline 2>/dev/null); then
    if [[ -n "$raw" && "${#raw}" -lt 500 && "$raw" != *$'\n'* ]]; then
        prefill="$raw"
    fi
fi

declare -a items
if [[ -n "$prefill" ]]; then
    items+=("$prefill")
else
    items+=("$SENTINEL")
fi

if [[ -s "$QUEUE_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == "$prefill" ]] && continue
        items+=("$line")
    done < <(tail -n "$RECENT_LIMIT" "$QUEUE_FILE" | tac | cut -f3-)
fi

height=80
if (( ${#items[@]} > 1 )); then
    height=$(( 80 + (${#items[@]} - 1) * 32 ))
    (( height > 420 )) && height=420
fi

content=$(printf '%s\n' "${items[@]}" | wofi \
    --dmenu \
    --prompt "Capture" \
    --width 720 \
    --height "$height" \
    --insensitive \
    || true)

[[ "$content" == "$SENTINEL" ]] && exit 0

content=$(printf '%s' "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
[[ -z "$content" ]] && exit 0

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
host=$(hostname)

payload=$(jq -nc \
    --arg t "$ts" \
    --arg h "$host" \
    --arg c "$content" \
    '{timestamp:$t, source:$h, content:$c}')

if curl --silent --show-error --fail --max-time 3 \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        "$INBOX_URL" >/dev/null 2>&1; then
    notify-send -t 2000 -a inbox "Captured" "$content"
else
    printf '%s\t%s\t%s\n' "$ts" "$host" "${content//$'\t'/ }" >> "$QUEUE_FILE"
    qcount=$(wc -l < "$QUEUE_FILE" | tr -d ' ')
    notify-send -t 3000 -a inbox -u normal \
        "Captured (queued, $qcount pending)" \
        "Server unreachable — will sync later.
$content"
fi
