#!/usr/bin/env bash
# Restore windows to their preferred workspaces and apply dwindle layouts
# Dwindle-aware version using layoutmsg and splitratio

# Color output for debugging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[snapback]${NC} $1" >&2
}

warn() {
  echo -e "${YELLOW}[snapback]${NC} $1" >&2
}

error() {
  echo -e "${RED}[snapback]${NC} $1" >&2
}

# Move windows to their preferred workspaces
move_to_workspaces() {
  local windows_json="$1"
  local moved=0

  # Track windows per workspace for layout application
  declare -gA workspace_windows

  while read -r window_info; do
    local class=$(echo "$window_info" | jq -r '.class')
    local address=$(echo "$window_info" | jq -r '.address')
    local current_ws=$(echo "$window_info" | jq -r '.workspace.id')
    local title=$(echo "$window_info" | jq -r '.title')

    # Check if this class has a preferred workspace
    local preferred_workspace=""

    # Direct match first
    if [[ -n "${WORKSPACE_MAP[$class]}" ]]; then
      preferred_workspace="${WORKSPACE_MAP[$class]}"
    else
      # Pattern matching for class names
      for pattern in "${!WORKSPACE_MAP[@]}"; do
        if [[ "$class" =~ ^${pattern}$ ]]; then
          preferred_workspace="${WORKSPACE_MAP[$pattern]}"
          break
        fi
      done
    fi

    if [[ -n "$preferred_workspace" ]]; then
      # Move if in wrong workspace
      if [[ "$current_ws" != "$preferred_workspace" ]]; then
        log "Moving $class to workspace $preferred_workspace"
        hyprctl dispatch movetoworkspacesilent "$preferred_workspace,address:$address" > /dev/null
        moved=$((moved + 1))
      fi

      # Track for layout application
      local window_pair="$class:$address"
      if [[ -z "${workspace_windows[$preferred_workspace]}" ]]; then
        workspace_windows["$preferred_workspace"]="$window_pair"
      else
        workspace_windows["$preferred_workspace"]+=" $window_pair"
      fi
    else
      # This window doesn't belong to any configured workspace
      # Move to workspace 4 (overflow) if not already there
      if [[ "$current_ws" != "4" ]]; then
        warn "Moving orphan window ($class: $title) to workspace 4"
        hyprctl dispatch movetoworkspacesilent "4,address:$address" > /dev/null
        moved=$((moved + 1))
      fi
    fi
  done < <(echo "$windows_json" | jq -c '.[]')

  log "Moved $moved windows"
}

# Apply horizontal layout (side-by-side) using dwindle
apply_horizontal_layout() {
  local workspace="$1"
  local layout_json="$2"
  local window_list="$3"

  log "Applying horizontal (side-by-side) layout to workspace $workspace"

  # Parse window list into associative array
  declare -A window_addresses
  for window_pair in $window_list; do
    IFS=':' read -r class address <<< "$window_pair"
    window_addresses["$class"]="$address"
  done

  # Get ordered classes from layout config
  mapfile -t ordered_classes < <(echo "$layout_json" | jq -r '.order[]')

  local num_windows=${#ordered_classes[@]}

  if [[ $num_windows -eq 0 ]]; then
    warn "No windows to layout"
    return
  fi

  # Focus the workspace (only if not already there)
  local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
  if [[ "$current_ws" != "$workspace" ]]; then
    hyprctl dispatch workspace "$workspace" > /dev/null
    sleep 0.05  # Wait for workspace switch before querying windows
  fi

  # Get the first two windows
  local first_class="${ordered_classes[0]}"
  local first_address="${window_addresses[$first_class]}"

  if [[ -z "$first_address" ]]; then
    warn "First window not found: $first_class"
    return
  fi

  if [[ $num_windows -ge 2 ]]; then
    local second_class="${ordered_classes[1]}"
    local second_address="${window_addresses[$second_class]}"

    if [[ -n "$second_address" ]]; then
      # Get current positions to check if we need to swap
      local windows_current=$(hyprctl clients -j)
      local first_x=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$first_address\") | .at[0]")
      local second_x=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$second_address\") | .at[0]")
      local first_y=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$first_address\") | .at[1]")
      local second_y=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$second_address\") | .at[1]")

      log "Window positions: first=($first_x,$first_y), second=($second_x,$second_y)"

      # Build batch command to apply all changes without animations
      local batch_cmd="keyword animations:enabled false"
      local needs_operations=false

      # Check if they're currently top-bottom (same X position)
      if [[ $first_x -eq $second_x ]]; then
        log "Windows are top-bottom, need to toggle to horizontal"
        batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address ; dispatch togglesplit"
        needs_operations=true
      fi

      # If second is to the left of first, swap them
      if [[ $second_x -lt $first_x ]]; then
        log "Swapping windows to correct order"
        if [[ "$needs_operations" == false ]]; then
          batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address"
        fi
        batch_cmd="$batch_cmd ; dispatch swapwindow address:$second_address"
        needs_operations=true
      fi

      # Apply the splitratio
      local splitratio=$(echo "$layout_json" | jq -r '.splitratio // 1.0')
      log "Setting splitratio to $splitratio"

      if [[ "$needs_operations" == false ]]; then
        batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address"
      fi
      batch_cmd="$batch_cmd ; dispatch splitratio exact $splitratio"

      # Re-enable animations
      batch_cmd="$batch_cmd ; keyword animations:enabled true"

      # Execute all layout changes in one batch
      hyprctl --batch "$batch_cmd" > /dev/null 2>&1
    fi
  else
    # Single window, just focus it
    hyprctl dispatch focuswindow "address:$first_address" > /dev/null
  fi

  log "Horizontal layout applied"
}

# Apply vertical layout (top-bottom) using dwindle
apply_vertical_layout() {
  local workspace="$1"
  local layout_json="$2"
  local window_list="$3"

  log "Applying vertical (top-bottom) layout to workspace $workspace"

  # Parse window list
  declare -A window_addresses
  for window_pair in $window_list; do
    IFS=':' read -r class address <<< "$window_pair"
    window_addresses["$class"]="$address"
  done

  # Get ordered classes
  mapfile -t ordered_classes < <(echo "$layout_json" | jq -r '.order[]')

  local num_windows=${#ordered_classes[@]}

  if [[ $num_windows -eq 0 ]]; then
    return
  fi

  # Focus workspace (only if not already there)
  local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
  if [[ "$current_ws" != "$workspace" ]]; then
    hyprctl dispatch workspace "$workspace" > /dev/null
    sleep 0.05  # Wait for workspace switch before querying windows
  fi

  # Get windows
  local first_class="${ordered_classes[0]}"
  local first_address="${window_addresses[$first_class]}"

  if [[ -z "$first_address" ]]; then
    warn "First window not found: $first_class"
    return
  fi

  if [[ $num_windows -ge 2 ]]; then
    local second_class="${ordered_classes[1]}"
    local second_address="${window_addresses[$second_class]}"

    if [[ -n "$second_address" ]]; then
      # Check current positions (y-axis for vertical)
      local windows_current=$(hyprctl clients -j)
      local first_y=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$first_address\") | .at[1]")
      local second_y=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$second_address\") | .at[1]")
      local first_x=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$first_address\") | .at[0]")
      local second_x=$(echo "$windows_current" | jq -r ".[] | select(.address == \"$second_address\") | .at[0]")

      log "Window positions: first=($first_x,$first_y), second=($second_x,$second_y)"

      # Build batch command to apply all changes without animations
      local batch_cmd="keyword animations:enabled false"
      local needs_operations=false

      # Check if they're currently side-by-side (same Y position)
      if [[ $first_y -eq $second_y ]]; then
        log "Windows are side-by-side, need to toggle to vertical"
        batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address ; dispatch togglesplit"
        needs_operations=true
      fi

      # If second is above first, swap
      if [[ $second_y -lt $first_y ]]; then
        log "Swapping windows to correct vertical order"
        if [[ "$needs_operations" == false ]]; then
          batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address"
        fi
        batch_cmd="$batch_cmd ; dispatch swapwindow address:$second_address"
        needs_operations=true
      fi

      # Apply the splitratio
      local splitratio=$(echo "$layout_json" | jq -r '.splitratio // 1.0')
      log "Setting splitratio to $splitratio"

      if [[ "$needs_operations" == false ]]; then
        batch_cmd="$batch_cmd ; dispatch focuswindow address:$first_address"
      fi
      batch_cmd="$batch_cmd ; dispatch splitratio exact $splitratio"

      # Re-enable animations
      batch_cmd="$batch_cmd ; keyword animations:enabled true"

      # Execute all layout changes in one batch
      hyprctl --batch "$batch_cmd" > /dev/null 2>&1
    fi
  else
    # Single window, just focus it
    hyprctl dispatch focuswindow "address:$first_address" > /dev/null
  fi

  log "Vertical layout applied"
}

# Apply layouts to all workspaces
apply_layouts() {
  log "Applying layouts..."

  # Get current workspace to do it last (minimize visible flickering)
  local current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')

  # Collect workspaces to process
  local other_workspaces=()
  local has_current_workspace=false

  for workspace in "${!workspace_windows[@]}"; do
    if [[ "$workspace" == "$current_workspace" ]]; then
      has_current_workspace=true
    else
      other_workspaces+=("$workspace")
    fi
  done

  # Process other workspaces first (user won't see these)
  for workspace in "${other_workspaces[@]}"; do
    local window_list="${workspace_windows[$workspace]}"
    local layout_json="${LAYOUT_CONFIG[$workspace]}"

    if [[ -z "$layout_json" ]] || [[ "$layout_json" == "null" ]]; then
      log "Workspace $workspace: no layout configured, skipping"
      continue
    fi

    local direction=$(echo "$layout_json" | jq -r '.direction // "horizontal"')
    log "Workspace $workspace: direction=$direction"

    if [[ "$direction" == "horizontal" ]]; then
      apply_horizontal_layout "$workspace" "$layout_json" "$window_list"
    elif [[ "$direction" == "vertical" ]]; then
      apply_vertical_layout "$workspace" "$layout_json" "$window_list"
    else
      warn "Unknown layout direction: $direction"
    fi
  done

  # Process current workspace last (minimize visible disruption)
  if [[ "$has_current_workspace" == true ]]; then
    local window_list="${workspace_windows[$current_workspace]}"
    local layout_json="${LAYOUT_CONFIG[$current_workspace]}"

    if [[ -n "$layout_json" ]] && [[ "$layout_json" != "null" ]]; then
      local direction=$(echo "$layout_json" | jq -r '.direction // "horizontal"')
      log "Workspace $current_workspace (current): direction=$direction"

      if [[ "$direction" == "horizontal" ]]; then
        apply_horizontal_layout "$current_workspace" "$layout_json" "$window_list"
      elif [[ "$direction" == "vertical" ]]; then
        apply_vertical_layout "$current_workspace" "$layout_json" "$window_list"
      fi
    fi
  fi
}

main() {
  log "Starting snap-back..."

  # Save current state before any changes
  local original_window=$(hyprctl activewindow -j | jq -r '.address')
  local original_workspace=$(hyprctl activewindow -j | jq -r '.workspace.id')

  # Save which workspaces are visible on each monitor
  declare -A monitor_workspaces
  while read -r monitor_info; do
    local monitor_id=$(echo "$monitor_info" | jq -r '.id')
    local active_ws=$(echo "$monitor_info" | jq -r '.activeWorkspace.id')
    monitor_workspaces["$monitor_id"]="$active_ws"
  done < <(hyprctl monitors -j | jq -c '.[]')

  log "Saved state: workspace $original_workspace, window $original_window"

  # Get all windows
  local windows_json=$(hyprctl clients -j)

  # Check if any windows need to be moved or layouts need fixing
  local needs_changes=false

  # Track windows per workspace for layout checking
  declare -A check_workspace_windows

  while read -r window_info; do
    local class=$(echo "$window_info" | jq -r '.class')
    local address=$(echo "$window_info" | jq -r '.address')
    local current_ws=$(echo "$window_info" | jq -r '.workspace.id')

    # Check if this class has a preferred workspace
    local preferred_workspace=""
    if [[ -n "${WORKSPACE_MAP[$class]}" ]]; then
      preferred_workspace="${WORKSPACE_MAP[$class]}"
    else
      for pattern in "${!WORKSPACE_MAP[@]}"; do
        if [[ "$class" =~ ^${pattern}$ ]]; then
          preferred_workspace="${WORKSPACE_MAP[$pattern]}"
          break
        fi
      done
    fi

    # If window is in wrong workspace, we need to do work
    if [[ -n "$preferred_workspace" ]] && [[ "$current_ws" != "$preferred_workspace" ]]; then
      needs_changes=true
      break
    fi

    # Check for orphan windows (not in workspace 4)
    if [[ -z "$preferred_workspace" ]] && [[ "$current_ws" != "4" ]]; then
      needs_changes=true
      break
    fi

    # Track windows on correct workspace for layout checking
    if [[ -n "$preferred_workspace" ]] && [[ "$current_ws" == "$preferred_workspace" ]]; then
      local window_pair="$class:$address"
      if [[ -z "${check_workspace_windows[$current_ws]}" ]]; then
        check_workspace_windows["$current_ws"]="$window_pair"
      else
        check_workspace_windows["$current_ws"]+=" $window_pair"
      fi
    fi
  done < <(echo "$windows_json" | jq -c '.[]')

  # If we haven't found workspace issues, check for layout issues
  if [[ "$needs_changes" == false ]]; then
    for workspace in "${!check_workspace_windows[@]}"; do
      local layout_json="${LAYOUT_CONFIG[$workspace]}"

      if [[ -z "$layout_json" ]] || [[ "$layout_json" == "null" ]]; then
        continue
      fi

      local window_list="${check_workspace_windows[$workspace]}"

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

      # Check if orientation or order is wrong
      if [[ "$direction" == "horizontal" ]]; then
        # Should be side-by-side (same Y)
        if [[ "$first_y" != "$second_y" ]]; then
          log "Workspace $workspace needs layout fix: wrong orientation"
          needs_changes=true
          break
        fi
        # Check order (first should be left of second)
        if [[ $second_x -lt $first_x ]]; then
          log "Workspace $workspace needs layout fix: wrong order"
          needs_changes=true
          break
        fi
      elif [[ "$direction" == "vertical" ]]; then
        # Should be top-bottom (same X)
        if [[ "$first_x" != "$second_x" ]]; then
          log "Workspace $workspace needs layout fix: wrong orientation"
          needs_changes=true
          break
        fi
        # Check order (first should be above second)
        if [[ $second_y -lt $first_y ]]; then
          log "Workspace $workspace needs layout fix: wrong order"
          needs_changes=true
          break
        fi
      fi
    done
  fi

  if [[ "$needs_changes" == false ]]; then
    log "All windows already organized correctly - nothing to do!"
    return 0
  fi

  # Move windows to correct workspaces
  move_to_workspaces "$windows_json"

  # Apply layouts
  apply_layouts

  # Small delay to let things settle before reading state
  sleep 0.1

  # Check if the focused window moved to a different workspace
  local window_moved=false
  local new_window_workspace="$original_workspace"

  if [[ -n "$original_window" ]] && [[ "$original_window" != "null" ]]; then
    # Get current workspace of the originally focused window
    new_window_workspace=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$original_window\") | .workspace.id")

    if [[ -n "$new_window_workspace" ]] && [[ "$new_window_workspace" != "null" ]]; then
      if [[ "$new_window_workspace" != "$original_workspace" ]]; then
        window_moved=true
      fi
    fi
  fi

  if [[ "$window_moved" == true ]]; then
    # Focused window moved - follow it
    log "Following focused window to workspace $new_window_workspace"
    hyprctl dispatch focuswindow "address:$original_window" > /dev/null 2>&1
    sleep 0.05  # Need to wait to read monitor info

    # Get which monitor is now showing the focused window
    local focused_monitor=$(hyprctl activewindow -j | jq -r '.monitor')

    # Restore OTHER monitors to their original workspaces
    for monitor_id in "${!monitor_workspaces[@]}"; do
      if [[ "$monitor_id" != "$focused_monitor" ]]; then
        local target_ws="${monitor_workspaces[$monitor_id]}"
        local current_ws=$(hyprctl monitors -j | jq -r ".[] | select(.id == $monitor_id) | .activeWorkspace.id")

        if [[ "$current_ws" != "$target_ws" ]]; then
          log "Restoring workspace $target_ws on monitor $monitor_id"
          hyprctl dispatch focusmonitor "$monitor_id" > /dev/null 2>&1
          hyprctl dispatch workspace "$target_ws" > /dev/null 2>&1
        fi
      fi
    done

    # Re-focus the original window to ensure it stays focused
    hyprctl dispatch focuswindow "address:$original_window" > /dev/null 2>&1

  else
    # Focused window didn't move - restore all workspaces to original
    log "Restoring workspace visibility (no movement)"

    # Focus the original window first
    if [[ -n "$original_window" ]] && [[ "$original_window" != "null" ]]; then
      hyprctl dispatch focuswindow "address:$original_window" > /dev/null 2>&1
    fi

    # Restore each monitor to its original workspace
    for monitor_id in "${!monitor_workspaces[@]}"; do
      local target_ws="${monitor_workspaces[$monitor_id]}"
      local current_ws=$(hyprctl monitors -j | jq -r ".[] | select(.id == $monitor_id) | .activeWorkspace.id")

      if [[ "$current_ws" != "$target_ws" ]]; then
        log "Restoring workspace $target_ws on monitor $monitor_id"
        hyprctl dispatch focusmonitor "$monitor_id" > /dev/null 2>&1
        hyprctl dispatch workspace "$target_ws" > /dev/null 2>&1
      fi
    done

    # Re-focus the original window
    if [[ -n "$original_window" ]] && [[ "$original_window" != "null" ]]; then
      hyprctl dispatch focuswindow "address:$original_window" > /dev/null 2>&1
    fi
  fi

  log "Snap-back complete!"
}
