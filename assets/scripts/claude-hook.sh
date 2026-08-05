#!/usr/bin/env bash
# Claude Code hook: maintain one JSON state file per session in
# ~/.cache/claude-dashboard/, consumed by waybar-claude.sh and claude-dashboard.
# Registered in ~/.claude/settings.json for: SessionStart, UserPromptSubmit,
# PreToolUse, PostToolUse, Notification, Stop, SessionEnd.
#
# Statuses: idle -> working -> permission/waiting/attention -> done
# The hyprland window address is captured at SessionStart/UserPromptSubmit:
# the focused window at those moments is the terminal this session lives in
# (ghostty is single-instance, so PID-based mapping is impossible).
#
# Wrapped in a function so set -e from writeShellApplication never kills us.
_run_hook() {
set +e
CACHE_DIR="$HOME/.cache/claude-dashboard"
mkdir -p "$CACHE_DIR"

event=$(cat)

session_id=$(jq -r '.session_id // empty' <<<"$event" 2>/dev/null) || true
[ -z "${session_id:-}" ] && return 0
hook_event=$(jq -r '.hook_event_name // "unknown"' <<<"$event" 2>/dev/null) || true
state_file="$CACHE_DIR/${session_id}.json"

if [ "$hook_event" = "SessionEnd" ]; then
  rm -f "$state_file"
  pkill -RTMIN+9 waybar 2>/dev/null || true
  return 0
fi

old='{}'
if [ -f "$state_file" ]; then
  old=$(cat "$state_file" 2>/dev/null) || old='{}'
  [ -z "$old" ] && old='{}'
fi
old_status=$(jq -r '.status // ""' <<<"$old" 2>/dev/null) || true

# Claude PID: walk up the process tree (the hook runs as a descendant).
# Only computed once per session; reused from the state file afterwards.
claude_pid=$(jq -r '.pid // 0' <<<"$old" 2>/dev/null) || true
if ! [ "${claude_pid:-0}" -gt 0 ] 2>/dev/null; then
  claude_pid=""
  check_pid=$PPID
  for _ in 1 2 3 4 5; do
    check_comm=$(ps -p "$check_pid" -o comm= 2>/dev/null | tr -d ' ') || true
    # comm is ".claude-unwrapp" on NixOS (wrapper, truncated to 15 chars)
    case "$check_comm" in
      claude|*claude-unwrap*|.claude-wrapped)
        claude_pid="$check_pid"
        break
        ;;
    esac
    check_pid=$(ps -p "$check_pid" -o ppid= 2>/dev/null | tr -d ' ') || true
    [ -z "$check_pid" ] && break
  done
  claude_pid="${claude_pid:-0}"
fi

cwd=$(jq -r '.cwd // empty' <<<"$event" 2>/dev/null) || true
if [ -z "${cwd:-}" ]; then
  cwd=$(jq -r '.cwd // "unknown"' <<<"$old" 2>/dev/null) || cwd="unknown"
fi

# Window address: refresh whenever the user is provably typing in this
# session's window; otherwise carry the previous value forward. Only accept
# terminal windows — the hook runs a beat after the event, and if the user
# has already alt-tabbed away we'd capture (and later send approval
# keystrokes into!) something like Signal.
addr=$(jq -r '.window // empty' <<<"$old" 2>/dev/null) || true
case "$hook_event" in
  SessionStart|UserPromptSubmit)
    if command -v hyprctl >/dev/null 2>&1; then
      a=$(hyprctl activewindow -j 2>/dev/null | jq -r '
        select((.class // "") | test("ghostty|kitty|alacritty|foot|wezterm|[Tt]erm")) |
        .address // empty') || true
      [ -n "${a:-}" ] && addr="$a"
    fi
    ;;
esac

# tool_input -> one-line human summary (tabs/newlines stripped: the dashboard
# reads these fields over TSV)
# Pull the agent's most recent reasoning (last assistant text block) from the
# session transcript, so the approval card can show *why* it wants to run the
# command. Done here rather than in the dashboard to keep large JSONL parsing
# out of the render loop.
extract_context() {
  local tp="$1"
  [ -n "$tp" ] && [ -f "$tp" ] || return 0
  tac "$tp" 2>/dev/null | jq -r '
    select(.type == "assistant") | (.message.content // []) |
    if type == "array" then (map(select(.type == "text") | .text) | join(" ")) else "" end |
    select(length > 0)
  ' 2>/dev/null | head -1 | gsub_ws | head -c 800
}
# jq isn't available as a shell builtin; fake gsub_ws with tr for the pipe above
gsub_ws() { tr '\n\t' '  ' | tr -s ' '; }

# The session's AI-generated title, which Claude also sets as the terminal
# title (and thus the hyprland window title). Lets the dashboard recover a
# window association by title-match when the captured address goes stale
# (window closed+reopened → new address, but a background agent never
# re-submits a prompt to trigger re-capture).
extract_title() {
  local tp="$1"
  [ -n "$tp" ] && [ -f "$tp" ] || return 0
  # no gsub_ws here: it turns the trailing newline into a space, which would
  # break the dashboard's endswith() title match. $() strips the newline.
  grep '"ai-title"' "$tp" 2>/dev/null | tail -1 |
    jq -r '.aiTitle // empty | gsub("[\\n\\t]+"; " ")' 2>/dev/null | head -c 200
}

summarize() {
  jq -r '
    .tool_input // {} |
    ( if type == "object" then
        .command // .file_path // .pattern // .prompt // .url //
        (.description // tostring)
      else tostring end ) |
    gsub("[\n\t]+"; " ") | .[0:2000]
  ' <<<"$1" 2>/dev/null | head -c 4000
}

status="${old_status:-idle}"
tool=""
summary=""
message=""
context=$(jq -r '.context // empty' <<<"$old" 2>/dev/null) || true
title=$(jq -r '.title // empty' <<<"$old" 2>/dev/null) || true
# user-assigned label (set by claude-label via the SUPER+SHIFT+Q hotkey);
# purely carried forward here so hook rewrites don't wipe it
label=$(jq -r '.label // empty' <<<"$old" 2>/dev/null) || true
transcript=$(jq -r '.transcript_path // empty' <<<"$event" 2>/dev/null) || true

# refresh the title on low-frequency events only (grep scans the whole
# transcript; avoid doing it on every PreToolUse)
case "$hook_event" in
  SessionStart|UserPromptSubmit|PermissionRequest|Stop)
    t=$(extract_title "$transcript")
    [ -n "$t" ] && title="$t"
    ;;
esac

case "$hook_event" in
  SessionStart)
    status="idle"
    ;;
  UserPromptSubmit)
    status="working"
    ;;
  PreToolUse|PostToolUse)
    status="working"
    tool=$(jq -r '.tool_name // empty' <<<"$event" 2>/dev/null) || true
    summary=$(summarize "$event")
    ;;
  PermissionRequest)
    # fires the moment the permission dialog renders (the Notification
    # "needs your permission" event lags it by ~6s)
    status="permission"
    tool=$(jq -r '.tool_name // empty' <<<"$event" 2>/dev/null) || true
    summary=$(summarize "$event")
    message="awaiting approval"
    context=$(extract_context "$transcript")
    ;;
  Notification)
    message=$(jq -r '.message // empty | gsub("[\n\t]+"; " ")' <<<"$event" 2>/dev/null) || true
    case "$message" in
      *permission*)              status="permission" ;;
      *"waiting for your input"*) status="waiting" ;;
      *)                         status="attention" ;;
    esac
    # keep the pending tool captured by the preceding PreToolUse
    tool=$(jq -r '.tool // empty' <<<"$old" 2>/dev/null) || true
    summary=$(jq -r '.summary // empty' <<<"$old" 2>/dev/null) || true
    ;;
  Stop)
    status="done"
    ;;
esac

# "deferred" (set by the dashboard's Defer button) survives only while the
# same permission request is pending; any other transition clears it, so the
# session's next request re-enters the approval queue.
deferred=false
if [ "$status" = "permission" ] && [ "$old_status" = "permission" ]; then
  old_deferred=$(jq -r '.deferred // false' <<<"$old" 2>/dev/null) || true
  [ "${old_deferred:-}" = "true" ] && deferred=true
fi

tmp="${state_file}.tmp.$$"
jq -n \
  --arg sid "$session_id" \
  --arg pid "${claude_pid:-0}" \
  --arg cwd "$cwd" \
  --arg status "$status" \
  --arg tool "${tool:-}" \
  --arg summary "${summary:-}" \
  --arg message "${message:-}" \
  --arg window "${addr:-}" \
  --argjson deferred "$deferred" \
  --arg context "${context:-}" \
  --arg title "${title:-}" \
  --arg label "${label:-}" \
  --arg ts "$(date +%s)" \
  '{
    session_id: $sid,
    pid: ($pid | tonumber? // 0),
    cwd: $cwd,
    status: $status,
    tool: $tool,
    summary: $summary,
    message: $message,
    window: $window,
    deferred: $deferred,
    context: $context,
    title: $title,
    label: $label,
    timestamp: ($ts | tonumber)
  }' > "$tmp" 2>/dev/null && mv "$tmp" "$state_file" 2>/dev/null
rm -f "$tmp" 2>/dev/null

# Nudge waybar only on state transitions (PreToolUse fires constantly)
if [ "$status" != "$old_status" ]; then
  pkill -RTMIN+9 waybar 2>/dev/null || true
fi
}
_run_hook
exit 0
