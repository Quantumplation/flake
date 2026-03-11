#!/usr/bin/env bash
# Screenshot wrapper that saves to ~/Captures/{year}-{month}/

output_dir="$HOME/Captures/$(date +%Y-%m)"
mkdir -p "$output_dir"

hyprshot -o "$output_dir" "$@"
