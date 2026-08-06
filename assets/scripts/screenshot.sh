#!/usr/bin/env bash
# Screenshot: slurp (drag-select) -> grim (capture region) -> swappy (annotate).
#
#   ctrl+shift+4   drag a region, annotate it, Ctrl+C to copy and dismiss
#   Escape         cancel (during select, or in the annotator)
#   Ctrl+S         also save to ~/Captures/{year}-{month}/
#
# swappy's early_exit=true (see the config in home.nix) makes it quit right
# after copy/save, rather than lingering until dismissed.
#
# Toolkit note: satty and flameshot were both tried here and neither works on
# this machine. satty (GTK4) starts, receives the image on stdin, then blocks in
# unix_wait_for_peer and never maps a window — unaffected by renderer, portal or
# scaling overrides. flameshot (Qt6) maps but renders the 2560x1600 native grab
# against a 1.6-scaled screen, so it comes up massively zoomed. swappy is GTK3
# and maps correctly at a sane size, so it is what we use.

set -euo pipefail

# slurp exits non-zero when the selection is cancelled with Escape; that is a
# normal outcome, not an error, so swallow it rather than tripping errexit.
region=$(slurp -d) || exit 0
[ -n "$region" ] || exit 0

mkdir -p "$HOME/Captures/$(date +%Y-%m)"

grim -g "$region" - | swappy -f -
