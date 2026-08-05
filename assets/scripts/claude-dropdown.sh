#!/usr/bin/env bash
# Toggle the Claude dashboard: a floating ghostty anchored top-right under
# the waybar module, notification-drawer style. Geometry, pinning, and the
# slide-in animation come from title-matched windowrules in
# packages/hyprland/windows.nix (inline exec rules don't apply reliably with
# gtk-single-instance ghostty: the daemon, not the exec'd PID, maps the window).
DASH_TITLE="ClaudeDashboard"

window_addr=$(hyprctl clients -j | jq -r ".[] | select(.title == \"$DASH_TITLE\") | .address" | head -1) || true

if [ -n "${window_addr:-}" ]; then
    # Toggle off by asking the dashboard to exit rather than force-closing the
    # ghostty surface: a self-exiting process lets ghostty close the window
    # without its confirm-close-surface prompt. Fall back to closewindow if the
    # process is somehow already gone but the window lingers.
    if ! pkill -TERM -f '/bin/claude-dashboard$' 2>/dev/null; then
        hyprctl dispatch closewindow "address:$window_addr" || true
    fi
else
    hyprctl dispatch exec "ghostty --title=$DASH_TITLE --shell-integration-features=cursor,sudo -e claude-dashboard" || true
fi
