#!/usr/bin/env bash
# Verbose version of snap-back for debugging

main() {
  echo "=== Starting snap-back (verbose mode) ==="

  # Get all windows
  windows=$(hyprctl clients -j)

  # Count moved windows
  moved=0

  # Associate windows with their target workspaces
  declare -A workspace_windows

  echo ""
  echo "=== First pass: Moving windows to correct workspaces ==="

  # First pass: Move windows to correct workspaces
  while IFS='|' read -r class workspace address; do
    # Check if this class has a preferred workspace
    preferred_workspace="${WORKSPACE_MAP[$class]}"

    # Also try pattern matching for class names
    if [[ -z "$preferred_workspace" ]]; then
      for pattern in "${!WORKSPACE_MAP[@]}"; do
        if [[ "$class" =~ ^${pattern}$ ]]; then
          preferred_workspace="${WORKSPACE_MAP[$pattern]}"
          break
        fi
      done
    fi

    # Move if in wrong workspace
    if [[ -n "$preferred_workspace" ]]; then
      if [[ "$workspace" != "$preferred_workspace" ]]; then
        echo "  Moving $class from workspace $workspace to $preferred_workspace"
        hyprctl dispatch movetoworkspacesilent "$preferred_workspace,address:$address"
        ((moved++))
      else
        echo "  $class already in workspace $preferred_workspace (correct)"
      fi

      # Track this window for layout application
      window_pair="$class:$address"
      if [[ -z "${workspace_windows[$preferred_workspace]}" ]]; then
        workspace_windows["$preferred_workspace"]="$window_pair"
      else
        workspace_windows["$preferred_workspace"]="${workspace_windows[$preferred_workspace]} $window_pair"
      fi
    fi
  done < <(echo "$windows" | jq -r '.[] | "\(.class)|\(.workspace.id)|\(.address)"')

  echo ""
  echo "=== Second pass: Applying dwindle layouts ==="
  echo "=== Re-querying windows after moves ==="

  # Re-query windows after moving them
  windows=$(hyprctl clients -j)

  # Second pass: Apply layouts to workspaces that have them
  for workspace in "${!LAYOUT_CONFIG[@]}"; do
    layout_json="${LAYOUT_CONFIG[$workspace]}"
    window_list="${workspace_windows[$workspace]}"

    echo ""
    echo "Workspace $workspace:"
    echo "  Layout: $(echo "$layout_json" | jq -r '.direction')"
    echo "  Windows: $window_list"

    if [[ -z "$window_list" ]]; then
      echo "  (No windows to layout)"
      continue
    fi

    # Parse layout config
    direction=$(echo "$layout_json" | jq -r '.direction')

    # Apply layout based on direction
    if [[ "$direction" == "horizontal" ]]; then
      apply_horizontal_layout "$layout_json" "$window_list" "$windows"
    elif [[ "$direction" == "vertical" ]]; then
      apply_vertical_layout "$layout_json" "$window_list" "$windows"
    fi
  done

  echo ""
  echo "=== Done ==="

  # Send notification
  if command -v notify-send &> /dev/null; then
    if [[ $moved -gt 0 ]]; then
      notify-send "Workspace Snap" "Restored $moved window(s) to preferred workspaces" -t 2000
    else
      notify-send "Workspace Snap" "All windows already in correct workspaces ✓" -t 2000
    fi
  fi
}

apply_horizontal_layout() {
  local layout_json="$1"
  local window_list="$2"
  local windows_json="$3"

  echo "  Applying horizontal dwindle layout..."

  # Create associative array of class -> address
  declare -A window_addresses
  for window_pair in $window_list; do
    IFS=':' read -r class address <<< "$window_pair"
    window_addresses["$class"]="$address"
  done

  # Get ordered list of classes
  mapfile -t ordered_classes < <(echo "$layout_json" | jq -r '.order[]')

  echo "  Desired order: ${ordered_classes[@]}"

  if [[ ${#ordered_classes[@]} -ne 2 ]]; then
    echo "  (Only 2-window layouts supported)"
    return
  fi

  local first_class="${ordered_classes[0]}"
  local second_class="${ordered_classes[1]}"
  local first_address="${window_addresses[$first_class]}"
  local second_address="${window_addresses[$second_class]}"

  if [[ -z "$first_address" ]] || [[ -z "$second_address" ]]; then
    echo "  ERROR: One or both windows not found"
    echo "    first_class=$first_class, first_address=$first_address"
    echo "    second_class=$second_class, second_address=$second_address"
    return
  fi

  echo "  First window: $first_class ($first_address)"
  echo "  Second window: $second_class ($second_address)"

  # Focus the first window
  echo "  Focusing first window..."
  hyprctl dispatch focuswindow address:$first_address

  # Get position info
  first_info=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$first_address\")")
  second_info=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$second_address\")")

  first_x=$(echo "$first_info" | jq -r '.at[0]')
  second_x=$(echo "$second_info" | jq -r '.at[0]')
  first_y=$(echo "$first_info" | jq -r '.at[1]')
  second_y=$(echo "$second_info" | jq -r '.at[1]')

  echo "  Current positions: first_x=$first_x, second_x=$second_x, first_y=$first_y, second_y=$second_y"

  # Check if windows are side-by-side (horizontal) or stacked (vertical)
  is_horizontal=$([[ $first_y == $second_y ]] && echo "true" || echo "false")
  echo "  Current orientation: horizontal=$is_horizontal (want horizontal=true)"

  # If windows are vertical but we want horizontal, toggle split
  if [[ "$is_horizontal" == "false" ]]; then
    echo "  TOGGLING SPLIT: Windows are stacked, need them side-by-side"
    echo "  Running: hyprctl dispatch togglesplit"
    hyprctl dispatch togglesplit
    sleep 0.1
    # Re-query
    first_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$first_address\")")
    second_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$second_address\")")
    first_x=$(echo "$first_info" | jq -r '.at[0]')
    second_x=$(echo "$second_info" | jq -r '.at[0]')
    echo "  After toggle: first_x=$first_x, second_x=$second_x"
  fi

  echo "  Checking left-right order..."
  # Check if need to swap
  if [[ $second_x -le $first_x ]]; then
    echo "  SWAPPING: Second window ($second_class) is left of first ($first_class)"
    echo "  Running: hyprctl dispatch swapwindow address:$second_address"
    hyprctl dispatch swapwindow address:$second_address
    sleep 0.1
  else
    echo "  No swap needed (already in correct order)"
  fi

  # Re-query after potential swap
  echo "  Re-querying window positions..."
  first_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$first_address\")")
  second_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$second_address\")")

  # Get sizes
  first_width=$(echo "$first_info" | jq -r '.size[0]')
  second_width=$(echo "$second_info" | jq -r '.size[0]')
  total_width=$((first_width + second_width))

  first_percent=$(echo "$layout_json" | jq -r --arg class "$first_class" '.sizes[$class]')
  desired_first_width=$((total_width * first_percent / 100))
  delta=$((desired_first_width - first_width))

  echo "  Sizing: current_width=$first_width, desired_width=$desired_first_width, delta=$delta"

  if [[ $delta -gt 10 ]] || [[ $delta -lt -10 ]]; then
    echo "  RESIZING: Adjusting by $delta pixels horizontally"
    echo "  Running: hyprctl dispatch resizeactive $delta 0"
    hyprctl dispatch resizeactive $delta 0
  else
    echo "  No resize needed (within 10px tolerance)"
  fi
}

apply_vertical_layout() {
  local layout_json="$1"
  local window_list="$2"
  local windows_json="$3"

  echo "  Applying vertical dwindle layout..."

  # Create associative array of class -> address
  declare -A window_addresses
  for window_pair in $window_list; do
    IFS=':' read -r class address <<< "$window_pair"
    window_addresses["$class"]="$address"
  done

  # Get ordered list of classes
  mapfile -t ordered_classes < <(echo "$layout_json" | jq -r '.order[]')

  echo "  Desired order: ${ordered_classes[@]}"

  if [[ ${#ordered_classes[@]} -ne 2 ]]; then
    echo "  (Only 2-window layouts supported)"
    return
  fi

  local first_class="${ordered_classes[0]}"
  local second_class="${ordered_classes[1]}"
  local first_address="${window_addresses[$first_class]}"
  local second_address="${window_addresses[$second_class]}"

  if [[ -z "$first_address" ]] || [[ -z "$second_address" ]]; then
    echo "  ERROR: One or both windows not found"
    echo "    first_class=$first_class, first_address=$first_address"
    echo "    second_class=$second_class, second_address=$second_address"
    return
  fi

  echo "  First window: $first_class ($first_address)"
  echo "  Second window: $second_class ($second_address)"

  # Focus the first window
  echo "  Focusing first window..."
  hyprctl dispatch focuswindow address:$first_address

  # Get position info
  first_info=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$first_address\")")
  second_info=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$second_address\")")

  first_y=$(echo "$first_info" | jq -r '.at[1]')
  second_y=$(echo "$second_info" | jq -r '.at[1]')
  first_x=$(echo "$first_info" | jq -r '.at[0]')
  second_x=$(echo "$second_info" | jq -r '.at[0]')

  echo "  Current positions: first_x=$first_x, second_x=$second_x, first_y=$first_y, second_y=$second_y"

  # Check if windows are side-by-side (horizontal) or stacked (vertical)
  is_horizontal=$([[ $first_y == $second_y ]] && echo "true" || echo "false")
  echo "  Current orientation: horizontal=$is_horizontal (want horizontal=false)"

  # If windows are horizontal but we want vertical, toggle split
  if [[ "$is_horizontal" == "true" ]]; then
    echo "  TOGGLING SPLIT: Windows are side-by-side, need them stacked"
    echo "  Running: hyprctl dispatch togglesplit"
    hyprctl dispatch togglesplit
    sleep 0.1
    # Re-query
    first_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$first_address\")")
    second_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$second_address\")")
    first_y=$(echo "$first_info" | jq -r '.at[1]')
    second_y=$(echo "$second_info" | jq -r '.at[1]')
    echo "  After toggle: first_y=$first_y, second_y=$second_y"
  fi

  echo "  Checking top-bottom order..."
  # Check if need to swap
  if [[ $second_y -le $first_y ]]; then
    echo "  SWAPPING: Second window ($second_class) is above first ($first_class)"
    echo "  Running: hyprctl dispatch swapwindow address:$second_address"
    hyprctl dispatch swapwindow address:$second_address
    sleep 0.1
  else
    echo "  No swap needed (already in correct order)"
  fi

  # Re-query after potential swap
  echo "  Re-querying window positions..."
  first_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$first_address\")")
  second_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$second_address\")")

  # Get sizes
  first_height=$(echo "$first_info" | jq -r '.size[1]')
  second_height=$(echo "$second_info" | jq -r '.size[1]')
  total_height=$((first_height + second_height))

  first_percent=$(echo "$layout_json" | jq -r --arg class "$first_class" '.sizes[$class]')
  desired_first_height=$((total_height * first_percent / 100))
  delta=$((desired_first_height - first_height))

  echo "  Sizing: current_height=$first_height, desired_height=$desired_first_height, delta=$delta"

  if [[ $delta -gt 10 ]] || [[ $delta -lt -10 ]]; then
    echo "  RESIZING: Adjusting by $delta pixels vertically"
    echo "  Running: hyprctl dispatch resizeactive 0 $delta"
    hyprctl dispatch resizeactive 0 $delta
  else
    echo "  No resize needed (within 10px tolerance)"
  fi
}
