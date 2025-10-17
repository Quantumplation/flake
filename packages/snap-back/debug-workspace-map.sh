#!/usr/bin/env bash
# Debug script to see what's happening with workspace matching

main() {
  echo "=== WORKSPACE MAP ==="
  for key in "${!WORKSPACE_MAP[@]}"; do
    echo "  '$key' -> workspace ${WORKSPACE_MAP[$key]}"
  done
  echo ""
  
  echo "=== CURRENT WINDOWS ==="
  hyprctl clients -j | jq -r '.[] | "\(.class) -> workspace \(.workspace.id)"' | while read line; do
    echo "  $line"
  done
  echo ""
  
  echo "=== MATCHING LOGIC ==="
  hyprctl clients -j | jq -r '.[] | "\(.class)|\(.workspace.id)"' | while IFS='|' read -r class workspace; do
    preferred_workspace="${WORKSPACE_MAP[$class]}"
    
    # Also try pattern matching
    if [[ -z "$preferred_workspace" ]]; then
      for pattern in "${!WORKSPACE_MAP[@]}"; do
        if [[ "$class" =~ ^${pattern}$ ]]; then
          preferred_workspace="${WORKSPACE_MAP[$pattern]}"
          echo "  '$class' matches pattern '$pattern' -> workspace $preferred_workspace"
          break
        fi
      done
    else
      echo "  '$class' exact match -> workspace $preferred_workspace"
    fi
    
    if [[ -z "$preferred_workspace" ]]; then
      echo "  '$class' -> NO MATCH (will be ignored)"
    elif [[ "$workspace" != "$preferred_workspace" ]]; then
      echo "  '$class' -> MISPLACED! Currently in $workspace, should be in $preferred_workspace"
    else
      echo "  '$class' -> correct (workspace $workspace)"
    fi
  done
}
