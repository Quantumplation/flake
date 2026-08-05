# Quick-capture into the todo app (https://goldwasser.tailea870.ts.net).
#   todo-capture             → wofi prompt, pre-filled with the primary selection
#   todo-capture --selection → zero-UI: capture the highlighted text directly
# The `todo` CLI handles auth + offline queueing (~/.local/state/todo/queue.jsonl),
# so captures are never lost when goldwasser is unreachable.
# `todo` is installed imperatively at ~/.local/bin (built from ~/proj/todo).
export PATH="$HOME/.local/bin:$PATH"

# Primary selection is the highlight-to-select buffer — fresh by definition.
prefill=""
if raw=$(wl-paste --primary --no-newline 2>/dev/null); then
    if [[ -n "$raw" && "${#raw}" -lt 500 && "$raw" != *$'\n'* ]]; then
        prefill="$raw"
    fi
fi

if [[ "${1:-}" == "--selection" ]]; then
    text="$prefill"
    if [[ -z "$text" ]]; then
        notify-send -t 2000 -a todo "todo" "nothing selected"
        exit 0
    fi
else
    # --exec-search: Enter submits the search-box text (prefilled, editable)
    text=$(: | wofi \
        --dmenu \
        --exec-search \
        --prompt "add todo" \
        --search "$prefill" \
        --width 720 \
        --height 80 \
        || true)
    text=$(printf '%s' "$text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$text" ]] && exit 0
fi

if out=$("$HOME/.local/bin/todo" add --source hotkey "$text" 2>&1); then
    notify-send -t 2000 -a todo "todo" "$out"
else
    notify-send -t 4000 -a todo -u critical "todo capture failed" "$out"
fi
