#!/usr/bin/env bash
# Count windows that are not in their preferred workspace OR need layout fixes
# Outputs JSON for waybar

count_misplaced() {
  local windows_json=$(hyprctl clients -j)
  local misplaced=0
  local total=0

  # Track windows per workspace to check layouts
  declare -A workspace_windows

  while read -r window_info; do
    local class=$(echo "$window_info" | jq -r '.class')
    local address=$(echo "$window_info" | jq -r '.address')
    local current_ws=$(echo "$window_info" | jq -r '.workspace.id')

    # Check if this class has a preferred workspace
    local preferred_workspace=""

    # Direct match
    if [[ -n "${WORKSPACE_MAP[$class]}" ]]; then
      preferred_workspace="${WORKSPACE_MAP[$class]}"
    else
      # Pattern matching
      for pattern in "${!WORKSPACE_MAP[@]}"; do
        if [[ "$class" =~ ^${pattern}$ ]]; then
          preferred_workspace="${WORKSPACE_MAP[$pattern]}"
          break
        fi
      done
    fi

    if [[ -n "$preferred_workspace" ]]; then
      total=$((total + 1))
      if [[ "$current_ws" != "$preferred_workspace" ]]; then
        misplaced=$((misplaced + 1))
      else
        # Window is on correct workspace, track it for layout checking
        local window_pair="$class:$address"
        if [[ -z "${workspace_windows[$current_ws]}" ]]; then
          workspace_windows["$current_ws"]="$window_pair"
        else
          workspace_windows["$current_ws"]+=" $window_pair"
        fi
      fi
    fi
  done < <(echo "$windows_json" | jq -c '.[]')

  # Check if any workspaces need layout fixes
  for workspace in "${!workspace_windows[@]}"; do
    # Check if this workspace has a layout config
    local layout_json="${LAYOUT_CONFIG[$workspace]}"

    if [[ -z "$layout_json" ]] || [[ "$layout_json" == "null" ]]; then
      continue
    fi

    local window_list="${workspace_windows[$workspace]}"

    # Parse window list
    declare -A window_addresses
    for window_pair in $window_list; do
      IFS=':' read -r class address <<< "$window_pair"
      window_addresses["$class"]="$address"
    done

    # Get ordered classes
    mapfile -t ordered_classes < <(echo "$layout_json" | jq -r '.order[]')

    if [[ ${#ordered_classes[@]} -lt 2 ]]; then
      continue
    fi

    local first_class="${ordered_classes[0]}"
    local second_class="${ordered_classes[1]}"
    local first_address="${window_addresses[$first_class]}"
    local second_address="${window_addresses[$second_class]}"

    if [[ -z "$first_address" ]] || [[ -z "$second_address" ]]; then
      continue
    fi

    # Get current positions
    local first_x=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$first_address\") | .at[0]")
    local first_y=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$first_address\") | .at[1]")
    local second_x=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$second_address\") | .at[0]")
    local second_y=$(echo "$windows_json" | jq -r ".[] | select(.address == \"$second_address\") | .at[1]")

    # Skip if we couldn't get positions
    if [[ -z "$first_x" ]] || [[ -z "$first_y" ]] || [[ -z "$second_x" ]] || [[ -z "$second_y" ]]; then
      continue
    fi

    # Get expected direction
    local direction=$(echo "$layout_json" | jq -r '.direction // "horizontal"')

    # Debug: uncomment to see what's being checked
    echo "Checking workspace $workspace: $direction layout" >&2
    echo "  first ($first_class): x=$first_x y=$first_y" >&2
    echo "  second ($second_class): x=$second_x y=$second_y" >&2

    # Check if orientation is wrong
    if [[ "$direction" == "horizontal" ]]; then
      # Should be side-by-side (same Y)
      if [[ "$first_y" != "$second_y" ]]; then
        misplaced=$((misplaced + 1))
        continue
      fi
      # Check order (first should be left of second)
      if [[ $second_x -lt $first_x ]]; then
        misplaced=$((misplaced + 1))
        continue
      fi
    elif [[ "$direction" == "vertical" ]]; then
      # Should be top-bottom (same X)
      if [[ "$first_x" != "$second_x" ]]; then
        misplaced=$((misplaced + 1))
        continue
      fi
      # Check order (first should be above second)
      if [[ $second_y -lt $first_y ]]; then
        misplaced=$((misplaced + 1))
        continue
      fi
    fi
  done

  # Output JSON for waybar
  if [[ $misplaced -eq 0 ]]; then
    echo "{\"text\": \"\", \"alt\": \"default\", \"tooltip\": \"All windows organized\", \"class\": \"organized\"}"
  else
    echo "{\"text\": \"$misplaced\", \"alt\": \"misplaced\", \"tooltip\": \"$misplaced window(s) need organizing - click to snap back\", \"class\": \"misplaced\"}"
  fi
}
