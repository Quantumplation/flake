#!/usr/bin/env bash
# Waybar module: Claude Code session counts, driven entirely by the state
# files claude-session-hook maintains in ~/.cache/claude-dashboard/.
# Shows "<icon> <working>" plus an alert segment when sessions await a
# response. Refreshed by signal 9 (sent by the hook) + a slow poll that
# prunes files left behind by crashed sessions.

CACHE_DIR="$HOME/.cache/claude-dashboard"
mkdir -p "$CACHE_DIR"
now=$(date +%s)

shopt -s nullglob
declare -A best_ts best_file
for f in "$CACHE_DIR"/*.json; do
  line=$(jq -r '"\(.pid // 0)\t\(.timestamp // 0)"' "$f" 2>/dev/null) || { rm -f "$f"; continue; }
  IFS=$'\t' read -r pid ts <<<"$line"
  # session gone (crash / SessionEnd hook never fired)
  if [ "${pid:-0}" -gt 0 ] 2>/dev/null && ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$f"
    continue
  fi
  # unidentifiable and ancient
  if [ $((now - ${ts:-0})) -gt 172800 ]; then
    rm -f "$f"
    continue
  fi
  # one entry per claude process: /resume starts a new session_id on the
  # same PID, keep only the newest file
  key="$pid"
  [ "${pid:-0}" -eq 0 ] 2>/dev/null && key="file:$f"
  if [ -n "${best_ts[$key]:-}" ]; then
    if [ "${ts:-0}" -le "${best_ts[$key]}" ]; then
      rm -f "$f"
      continue
    fi
    rm -f "${best_file[$key]}"
  fi
  best_ts[$key]=$ts
  best_file[$key]=$f
done

files=()
for k in "${!best_file[@]}"; do files+=("${best_file[$k]}"); done

if [ ${#files[@]} -eq 0 ]; then
  printf '{"text":"","tooltip":"No Claude sessions","class":"none","alt":"none"}\n'
  exit 0
fi

jq -s -c --arg home "$HOME" '
  def rank: {permission: 0, attention: 1, waiting: 2, working: 3, done: 4, idle: 5}[.status] // 6;
  sort_by(rank) |
  def statuslabel:
    { working: "working",
      permission: "needs approval",
      waiting: "awaiting next prompt",
      attention: "needs attention",
      done: "turn finished",
      idle: "idle"
    }[.status] // .status;
  def line:
    (if (.label // "") != "" then .label else ((.cwd // "?") | sub("^\($home)"; "~")) end) as $name |
    "\($name): \(statuslabel)"
    + (if (.deferred // false) then " (deferred)" else "" end)
    + (if (.summary // "") != "" then " — \(.tool // "?"): \(.summary | .[0:120])" else "" end);

  (map(select(.status == "working")) | length) as $working |
  # deferred approvals still count as awaiting, but stop the urgent pulse
  (map(select(.status == "permission" and ((.deferred // false) | not))) | length) as $perm |
  (map(select(.status == "permission" or .status == "waiting"
              or .status == "attention" or .status == "done")) | length) as $await |
  ( if $perm > 0 then "permission"
    elif $await > 0 then "awaiting"
    elif $working > 0 then "working"
    else "idle" end ) as $class |
  { text: ("󰚩 \($working)" + (if $await > 0 then "  󰀦 \($await)" else "" end)),
    tooltip: ("Claude sessions: \(length)\n" + (map("  " + line) | join("\n"))),
    class: $class,
    alt: $class }
' "${files[@]}"
