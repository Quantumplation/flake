#!/usr/bin/env bash
# Debug script to show layout configurations

main() {
  echo "=== LAYOUT CONFIGURATIONS ==="
  for workspace in "${!LAYOUT_CONFIG[@]}"; do
    layout_json="${LAYOUT_CONFIG[$workspace]}"
    echo ""
    echo "Workspace $workspace:"
    echo "  Raw JSON: $layout_json"
    echo "  Direction: $(echo "$layout_json" | jq -r '.direction')"
    echo "  Order: $(echo "$layout_json" | jq -r '.order | join(" → ")')"
    echo "  Sizes:"
    echo "$layout_json" | jq -r '.sizes | to_entries[] | "    \(.key): \(.value)%"'
  done

  if [[ ${#LAYOUT_CONFIG[@]} -eq 0 ]]; then
    echo "  (No layouts configured)"
  fi
}
