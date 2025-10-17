#!/usr/bin/env bash

HISTORY_FILE="$HOME/.cache/waybar-system-history"
MAX_HISTORY=10  # Keep more history for tooltip
DISPLAY_HISTORY=3  # Only show last 3 in main bar

# Sparkline characters (8 levels)
SPARK_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Get current CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')

# Get current memory usage
mem_info=$(free | grep Mem)
mem_used=$(echo "$mem_info" | awk '{print $3}')
mem_total=$(echo "$mem_info" | awk '{print $2}')
mem_percent=$(awk "BEGIN {printf \"%.0f\", ($mem_used/$mem_total)*100}")

# Read history file
if [ -f "$HISTORY_FILE" ]; then
    history=$(cat "$HISTORY_FILE")
else
    history=""
fi

# Append current values and keep only last MAX_HISTORY entries
new_entry="${cpu_usage},${mem_percent}"
if [ -n "$history" ]; then
    history="${history}"$'\n'"${new_entry}"
else
    history="${new_entry}"
fi

# Keep only last MAX_HISTORY lines
history=$(echo "$history" | tail -n $MAX_HISTORY)
echo "$history" > "$HISTORY_FILE"

# Generate sparklines for display (last 3)
cpu_sparkline_display=""
mem_sparkline_display=""

display_data=$(echo "$history" | tail -n $DISPLAY_HISTORY)

while IFS=',' read -r cpu mem; do
    cpu_index=$((cpu * 7 / 100))
    [ "$cpu_index" -gt 7 ] && cpu_index=7
    cpu_sparkline_display="${cpu_sparkline_display}${SPARK_CHARS[$cpu_index]}"

    mem_index=$((mem * 7 / 100))
    [ "$mem_index" -gt 7 ] && mem_index=7
    mem_sparkline_display="${mem_sparkline_display}${SPARK_CHARS[$mem_index]}"
done <<< "$display_data"

# Generate sparklines for tooltip (full history)
cpu_sparkline_full=""
mem_sparkline_full=""

while IFS=',' read -r cpu mem; do
    cpu_index=$((cpu * 7 / 100))
    [ "$cpu_index" -gt 7 ] && cpu_index=7
    cpu_sparkline_full="${cpu_sparkline_full}${SPARK_CHARS[$cpu_index]}"

    mem_index=$((mem * 7 / 100))
    [ "$mem_index" -gt 7 ] && mem_index=7
    mem_sparkline_full="${mem_sparkline_full}${SPARK_CHARS[$mem_index]}"
done <<< "$history"

# Determine overall status
if [ "$cpu_usage" -ge 80 ] || [ "$mem_percent" -ge 80 ]; then
    class="critical"
elif [ "$cpu_usage" -ge 50 ] || [ "$mem_percent" -ge 60 ]; then
    class="warning"
else
    class="good"
fi

# Format text - just sparklines (icons come from waybar config)
text=" ${cpu_sparkline_display}  ${mem_sparkline_display}"

# Tooltip with full sparklines and percentages
tooltip=" CPU: ${cpu_sparkline_full} ${cpu_usage}%\\n RAM: ${mem_sparkline_full} ${mem_percent}%"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"

