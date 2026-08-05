#!/usr/bin/env bash
# Claude Code session dashboard — runs inside the floating ghostty sidebar
# spawned by claude-dropdown. Renders the hook-maintained state files from
# ~/.cache/claude-dashboard/ and offers per-session actions:
#   approve / reject  — key injected into the session's window via
#                       `hyprctl dispatch sendshortcut` (no focus stealing)
#   jump              — focus the session's window and close the dashboard
#   dismiss           — drop a finished session from the list
# Buttons are mouse-clickable (SGR mouse reporting); keyboard works too.
# State changes stream in near-real-time: every state write is an atomic
# rename into the cache dir, so the dir mtime is a cheap change signal —
# polled at 200ms between key reads. (inotify+signal was tried first, but
# trapped signals don't interrupt bash's `read -t`; it restarts the syscall.)
# Sessions are listed in stable order (by cwd) so buttons don't shift
# position mid-click as statuses change; urgency is shown by color instead.

CACHE_DIR="$HOME/.cache/claude-dashboard"
mkdir -p "$CACHE_DIR"

SESSION_COUNT=0
SELECTED=1
SELECTED_SID=""
LAST_LINES=0
ROW=0
FLASH=""
FLASH_TS=0

declare -a s_sid s_cwd s_status s_tool s_summary s_message s_addr s_deferred s_context s_label
# session indices awaiting approval (not deferred), oldest request first;
# while non-empty the panel shows QUEUE[0] full-screen instead of the list
declare -a QUEUE
# each entry: "row x1 x2 session-idx action"
declare -a hitboxes

flash() {
  FLASH="$1"
  FLASH_TS=$(date +%s)
}

refresh_data() {
  s_sid=(); s_cwd=(); s_status=(); s_tool=(); s_summary=(); s_message=(); s_addr=(); s_deferred=(); s_context=(); s_label=()
  QUEUE=()
  SESSION_COUNT=0

  shopt -s nullglob
  local files=("$CACHE_DIR"/*.json)
  shopt -u nullglob
  [ ${#files[@]} -eq 0 ] && return

  # Live window addresses, used to drop associations for windows that have
  # genuinely closed. Only invalidate when we actually got a usable client
  # list: a transient `hyprctl clients` hiccup (hyprland busy, a reload, a
  # pipe race) must NOT blank every running agent's window — that showed up
  # as window associations randomly "getting lost" mid-session.
  local live_addrs="" clients_json
  clients_json=$(hyprctl clients -j 2>/dev/null) || clients_json=""
  if [ -n "$clients_json" ]; then
    live_addrs=$(jq -r '[.[].address] | join(" ")' <<<"$clients_json" 2>/dev/null) || live_addrs=""
  fi

  # stable order: keyed on cwd+sid, NOT urgency — rows must not jump around
  # between refreshes while the user is clicking.
  # Fields are joined with \x1f, NOT @tsv: tab is an IFS *whitespace* char,
  # so `IFS=$'\t' read` collapses consecutive tabs and empty fields shift
  # everything after them (this silently ate the window address whenever
  # tool/summary/message were empty).
  local rows sep
  sep=$(printf '\x1f')
  rows=$(jq -s -r --arg home "$HOME" --arg sep "$sep" '
    sort_by([.cwd // "?", .session_id])[] |
    [ .session_id, (.pid // 0), ((.cwd // "?") | sub("^\($home)"; "~")),
      (.status // "?"), (.tool // ""), (.summary // ""), (.message // ""),
      (.window // ""), (.deferred // false), (.context // ""), (.title // ""), (.label // ""), (.timestamp // 0) ] |
    map(tostring) | join($sep)
  ' "${files[@]}" 2>/dev/null) || rows=""
  [ -z "$rows" ] && return

  # addresses currently claimed by a session whose stored window is live —
  # title recovery must not steal one of these
  local claimed=" "
  if [ -n "$live_addrs" ]; then
    local a
    while IFS=$'\x1f' read -r _ _ _ _ _ _ _ a _ _ _ _ _; do
      case " $live_addrs " in *" $a "*) claimed+="$a " ;; esac
    done <<<"$rows"
  fi

  local i=0 sid pid cwd status tool summary message addr deferred context title label ts
  local queue_unsorted=""
  while IFS=$'\x1f' read -r sid pid cwd status tool summary message addr deferred context title label ts; do
    [ -z "$sid" ] && continue
    # skip sessions whose claude process died (waybar poll will prune the file)
    if [ "${pid:-0}" -gt 0 ] 2>/dev/null && ! kill -0 "$pid" 2>/dev/null; then
      continue
    fi
    # only drop the address when we have a trustworthy live list AND it's
    # genuinely absent; unknown list => keep the stored window
    if [ -n "$live_addrs" ] && [ -n "$addr" ]; then
      case " $live_addrs " in
        *" $addr "*) ;;
        *) addr="" ;;
      esac
    fi

    # recover a lost association by window title: if the stored address is
    # stale/empty but the agent is alive, find the one unclaimed ghostty
    # window whose title ends with this session's AI title. Persist it so
    # the hook carries it forward and waybar/jump benefit too.
    if [ -z "$addr" ] && [ -n "$title" ] && [ -n "$clients_json" ] && \
       { [ "${pid:-0}" -le 0 ] 2>/dev/null || kill -0 "$pid" 2>/dev/null; }; then
      local found
      found=$(jq -r --arg t "$title" --arg claimed "$claimed" '
        [ .[]
          | select((.class // "") | test("ghostty"))
          | select((.title // "") | endswith($t))
          | .address as $a
          | select(($claimed | contains(" " + $a + " ")) | not)
          | $a ]
        | (unique) | if length == 1 then .[0] else "" end
      ' <<<"$clients_json" 2>/dev/null) || found=""
      if [ -n "$found" ]; then
        addr="$found"
        claimed+="$found "
        local rf="$CACHE_DIR/${sid}.json" rtmp
        rtmp="$rf.tmp.$$"
        if jq --arg w "$found" '.window = $w' "$rf" > "$rtmp" 2>/dev/null; then
          mv "$rtmp" "$rf"
        fi
        rm -f "$rtmp"
      fi
    fi
    i=$((i + 1))
    s_sid[i]=$sid; s_cwd[i]=$cwd; s_status[i]=$status
    s_tool[i]=$tool; s_summary[i]=$summary; s_message[i]=$message; s_addr[i]=$addr
    s_deferred[i]=$deferred; s_context[i]=$context; s_label[i]=$label
    if [ "$status" = "permission" ] && [ "$deferred" != "true" ]; then
      queue_unsorted+="${ts:-0} $i"$'\n'
    fi
  done <<<"$rows"
  SESSION_COUNT=$i

  # approval queue: oldest pending request first
  local qidx
  while read -r qidx; do
    [ -n "${qidx:-}" ] && QUEUE+=("$qidx")
  done < <(printf '%s' "$queue_unsorted" | sort -n | cut -d' ' -f2)

  # selection follows the session, not the list position
  if [ -n "$SELECTED_SID" ]; then
    local j
    for ((j = 1; j <= SESSION_COUNT; j++)); do
      if [ "${s_sid[$j]}" = "$SELECTED_SID" ]; then
        SELECTED=$j
        break
      fi
    done
  fi
  if [ "$SELECTED" -gt "$SESSION_COUNT" ] && [ "$SESSION_COUNT" -gt 0 ]; then
    SELECTED=$SESSION_COUNT
  fi
  if [ "$SELECTED" -lt 1 ]; then SELECTED=1; fi
  SELECTED_SID="${s_sid[$SELECTED]:-}"
}

select_idx() {
  SELECTED=$1
  SELECTED_SID="${s_sid[$1]:-}"
}

# print one line, tracking the terminal row for mouse hitboxes
say() {
  ROW=$((ROW + 1))
  # shellcheck disable=SC2059
  printf "$1\033[K\n" "${@:2}"
}

# Render clickable buttons for session $1. Args: "action|label|color" ...
buttons() {
  local idx=$1; shift
  local x=6 text spec action label color
  ROW=$((ROW + 1))
  printf '     '
  for spec in "$@"; do
    action=${spec%%|*}
    label=${spec#*|}; color=${label#*|}; label=${label%%|*}
    text="[ $label ]"
    hitboxes+=("$ROW $x $((x + ${#text} - 1)) $idx $action")
    printf '%b%s\033[0m  ' "$color" "$text"
    x=$((x + ${#text} + 2))
  done
  printf '\033[K\n'
}

draw() {
  if [ ${#QUEUE[@]} -gt 0 ]; then
    draw_queue
  else
    draw_list
  fi
}

# Full-screen view of the oldest pending approval; the rest of the queue
# advances as items are approved/rejected/deferred.
draw_queue() {
  tput cup 0 0
  ROW=0
  hitboxes=()

  local cols rows idx
  cols=$(tput cols)
  rows=$(tput lines)
  idx=${QUEUE[0]}

  say ''
  say '  \033[1;31m◉ Approval needed\033[0m  \033[0;90m(%s in queue)\033[0m' "${#QUEUE[@]}"
  say ''
  if [ -n "${s_label[$idx]:-}" ]; then
    say '  \033[1m%s\033[0m' "${s_label[$idx]}"
    say '  \033[0;90m%s\033[0m' "${s_cwd[$idx]}"
  else
    say '  \033[1m%s\033[0m' "${s_cwd[$idx]}"
  fi
  say ''

  local bar
  bar=$(printf '─%.0s' $(seq 1 $((cols - 4))))

  # why the agent wants this — its last reasoning before the tool call
  local ctx="${s_context[$idx]:-}"
  if [ -n "$ctx" ]; then
    local cshown=0 cline
    while IFS= read -r cline; do
      if [ "$cshown" -ge 6 ]; then say '  \033[0;90m…\033[0m'; break; fi
      say '  \033[0;37m%s\033[0m' "$cline"
      cshown=$((cshown + 1))
    done < <(fold -s -w $((cols - 4)) <<<"$ctx")
    say ''
  fi

  say '  \033[1;36m%s\033[0m' "${s_tool[$idx]:-?}"
  say '  \033[0;90m%s\033[0m' "$bar"

  # the full command, word-wrapped; cap lines so buttons stay on screen
  local max_lines=$((rows - ROW - 8)) shown=0 line
  [ "$max_lines" -lt 3 ] && max_lines=3
  while IFS= read -r line; do
    if [ "$shown" -ge "$max_lines" ]; then
      say '  \033[0;90m… (truncated)\033[0m'
      break
    fi
    say '  %s' "$line"
    shown=$((shown + 1))
  done < <(fold -s -w $((cols - 4)) <<<"${s_summary[$idx]:-${s_message[$idx]:-}}")
  say '  \033[0;90m%s\033[0m' "$bar"
  say ''

  if [ -n "${s_addr[$idx]}" ]; then
    buttons "$idx" \
      'approve|✔ Approve|\033[1;32m' \
      'reject|✘ Reject|\033[1;31m' \
      'defer|⏳ Defer|\033[1;33m' \
      'jump|⇥ Jump|\033[1;36m'
  else
    say '  \033[0;90m(window unknown — approve in its terminal, or defer)\033[0m'
    buttons "$idx" 'defer|⏳ Defer|\033[1;33m'
  fi
  say ''

  local now
  now=$(date +%s)
  if [ -n "$FLASH" ] && [ $((now - FLASH_TS)) -lt 4 ]; then
    say '  \033[1;35m%s\033[0m' "$FLASH"
  else
    FLASH=""
    say ''
  fi

  say '  \033[0;90ma approve · r reject · d defer · ⏎ jump · l label · q quit\033[0m'

  local lines=$ROW
  if [ "$LAST_LINES" -gt "$lines" ]; then
    local k
    for ((k = lines; k < LAST_LINES; k++)); do printf '\033[K\n'; done
  fi
  LAST_LINES=$lines
}

draw_list() {
  tput cup 0 0
  ROW=0
  hitboxes=()

  local cols
  cols=$(tput cols)

  say ''
  say '  \033[1;36mClaude sessions\033[0m'
  say ''

  if [ "$SESSION_COUNT" -eq 0 ]; then
    say '  \033[0;90mNo active sessions\033[0m'
  fi

  local j
  for ((j = 1; j <= SESSION_COUNT; j++)); do
    local color icon detail sel row_start
    case "${s_status[$j]}" in
      permission) color='\033[1;31m'; icon='◉'; detail='needs approval' ;;
      attention)  color='\033[1;31m'; icon='◉'; detail='needs attention' ;;
      waiting)    color='\033[1;33m'; icon='◔'; detail='awaiting next prompt' ;;
      working)    color='\033[1;33m'; icon='⣿'; detail='working' ;;
      done)       color='\033[0;90m'; icon='✓'; detail='turn finished' ;;
      idle)       color='\033[0;32m'; icon='◯'; detail='idle' ;;
      *)          color='\033[0;37m'; icon='?'; detail="${s_status[$j]}" ;;
    esac

    if [ "${s_status[$j]}" = "permission" ] && [ "${s_deferred[$j]:-}" = "true" ]; then
      color='\033[1;33m'
      detail='needs approval (deferred)'
    fi

    sel=' '
    [ "$j" -eq "$SELECTED" ] && sel='▸'

    # user label takes the primary slot; cwd falls back when unlabeled
    local name="${s_label[$j]:-}"
    [ -z "$name" ] && name="${s_cwd[$j]}"

    row_start=$((ROW + 1))
    say "  \033[1;36m%s\033[0m %b%s\033[0m  \033[1m%-26.26s\033[0m %b%s\033[0m" \
      "$sel" "$color" "$icon" "$name" "$color" "$detail"

    # when labeled, keep the working dir visible on its own dim line
    [ -n "${s_label[$j]:-}" ] && say '      \033[0;90m%s\033[0m' "${s_cwd[$j]}"

    # context line: what it's doing / waiting on
    local ctx="" max=$((cols - 8))
    if [ -n "${s_tool[$j]}" ] && [ -n "${s_summary[$j]}" ]; then
      ctx="${s_tool[$j]}: ${s_summary[$j]}"
    elif [ -n "${s_message[$j]}" ]; then
      ctx="${s_message[$j]}"
    fi
    if [ -n "$ctx" ]; then
      [ ${#ctx} -gt "$max" ] && ctx="${ctx:0:$max}…"
      say '      \033[0;90m%s\033[0m' "$ctx"
    fi

    # whole block is clickable to select
    hitboxes+=("$row_start 1 $cols $j select")
    [ "$ROW" -gt "$row_start" ] && hitboxes+=("$ROW 1 5 $j select")

    # action buttons — only when we know the session's window; otherwise
    # explain why there's nothing to click
    if [ -n "${s_addr[$j]}" ]; then
      local -a btns=()
      if [ "${s_status[$j]}" = "permission" ] || [ "${s_status[$j]}" = "attention" ]; then
        btns+=('approve|✔ Approve|\033[1;32m' 'reject|✘ Reject|\033[1;31m')
      fi
      if [ "${s_status[$j]}" = "done" ]; then
        btns+=('dismiss|✕ Dismiss|\033[0;90m')
      fi
      btns+=('jump|⇥ Jump|\033[1;36m')
      buttons "$j" "${btns[@]}"
    else
      say '      \033[0;90m(window unknown — submit a prompt in its terminal to link it)\033[0m'
    fi
    say ''
  done

  # transient action feedback
  local now
  now=$(date +%s)
  if [ -n "$FLASH" ] && [ $((now - FLASH_TS)) -lt 4 ]; then
    say '  \033[1;35m%s\033[0m' "$FLASH"
  else
    FLASH=""
    say ''
  fi

  say '  \033[0;90m↑/↓ select · a approve · r reject · d defer · ⏎ jump · l label · x dismiss · q quit\033[0m'

  local lines=$ROW
  if [ "$LAST_LINES" -gt "$lines" ]; then
    local k
    for ((k = lines; k < LAST_LINES; k++)); do printf '\033[K\n'; done
  fi
  LAST_LINES=$lines
}

send_key() { # $1 = session idx, $2 = key name
  local addr="${s_addr[$1]:-}"
  [ -z "$addr" ] && return 1
  hyprctl dispatch sendshortcut ",$2,address:$addr" >/dev/null 2>&1 || return 1
}

# Optimistically flip the state file to working so the bar and list update
# immediately (no hook fires between approval and PostToolUse).
mark_working() {
  local f="$CACHE_DIR/${s_sid[$1]}.json" tmp
  [ -f "$f" ] || return 0
  tmp="$f.tmp.$$"
  if jq '.status = "working" | .message = ""' "$f" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$f"
  fi
  rm -f "$tmp"
  pkill -RTMIN+9 waybar 2>/dev/null || true
}

require_addr() { # $1 = idx; flashes and fails if the session has no window
  if [ -z "${s_addr[$1]:-}" ]; then
    flash "no window linked — submit a prompt in that session's terminal first"
    return 1
  fi
}

do_approve() {
  local i=$1
  case "${s_status[$i]:-}" in permission|attention) ;; *) return 0 ;; esac
  require_addr "$i" || return 0
  if send_key "$i" "1"; then
    mark_working "$i"
    flash "approved: ${s_cwd[$i]}"
  else
    flash "failed to send key to ${s_cwd[$i]}"
  fi
}

do_reject() {
  local i=$1
  case "${s_status[$i]:-}" in permission|attention) ;; *) return 0 ;; esac
  require_addr "$i" || return 0
  if send_key "$i" "Escape"; then
    mark_working "$i"
    flash "rejected: ${s_cwd[$i]}"
  else
    flash "failed to send key to ${s_cwd[$i]}"
  fi
}

do_jump() {
  local i=$1
  require_addr "$i" || return 0
  hyprctl dispatch focuswindow "address:${s_addr[$i]}" >/dev/null 2>&1 || true
  exit 0
}

# Drop a pending approval from the queue without answering it; the flag
# clears (hook-side) as soon as the session moves off this request, so its
# next prompt queues normally.
do_defer() {
  local i=$1
  [ "${s_status[$i]:-}" = "permission" ] || return 0
  local f="$CACHE_DIR/${s_sid[$i]}.json"
  local tmp="$f.tmp.$$"
  [ -f "$f" ] || return 0
  if jq '.deferred = true' "$f" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$f"
  fi
  rm -f "$tmp"
  flash "deferred: ${s_cwd[$i]} — approve it in its own window"
  pkill -RTMIN+9 waybar 2>/dev/null || true
}

do_dismiss() {
  rm -f "$CACHE_DIR/${s_sid[$1]}.json"
  pkill -RTMIN+9 waybar 2>/dev/null || true
}

# Rename a session: drop out of raw/mouse mode for a prefilled readline entry,
# write the label to the state file (empty clears it), then restore the TUI.
do_label() {
  local i=$1
  local sid="${s_sid[$i]:-}"
  [ -z "$sid" ] && return 0
  local f="$CACHE_DIR/$sid.json"
  [ -f "$f" ] || return 0
  local cur="${s_label[$i]:-}"

  local rows
  rows=$(tput lines)
  printf '\033[?1000;1006l'          # disable mouse reporting
  tput cnorm                          # show cursor for typing
  tput cup $((rows - 1)) 0
  printf '\033[K'                     # clear the prompt line

  local ans=""
  # -e readline editing, -i prefill with the current label
  read -rep $'  \033[1;36mLabel\033[0m (empty clears): ' -i "$cur" ans || ans="$cur"
  ans=$(printf '%s' "$ans" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  local tmp="$f.tmp.$$"
  if jq --arg l "$ans" '.label = $l' "$f" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$f"
    pkill -RTMIN+9 waybar 2>/dev/null || true
  fi
  rm -f "$tmp"

  tput civis                          # back to hidden cursor
  printf '\033[?1000;1006h'           # re-enable mouse
  clear
  LAST_LINES=0                        # force a full repaint
  flash "${ans:+labeled: $ans}${ans:-label cleared}"
}

handle_click() { # $1 = "btn;x;y" from SGR mouse report
  local btn x y
  IFS=';' read -r btn x y <<<"$1"
  [ "${btn:-1}" != "0" ] && return 0  # left button only
  local hb row x1 x2 idx action
  for hb in "${hitboxes[@]}"; do
    read -r row x1 x2 idx action <<<"$hb"
    if [ "$y" = "$row" ] && [ "$x" -ge "$x1" ] && [ "$x" -le "$x2" ]; then
      select_idx "$idx"
      case "$action" in
        approve) do_approve "$idx" ;;
        reject)  do_reject "$idx" ;;
        defer)   do_defer "$idx" ;;
        jump)    do_jump "$idx" ;;
        dismiss) do_dismiss "$idx" ;;
        select)  ;;
      esac
      return 0
    fi
  done
}

# Floating panel: pin ourselves to the right edge, full height below the
# bar, computed from the focused monitor's logical geometry (windowrule
# move formulas don't evaluate reliably, so we place ourselves).
setup_window() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  local addr="" i
  for i in $(seq 1 10); do
    addr=$(hyprctl clients -j 2>/dev/null |
      jq -r '[.[] | select(.title == "ClaudeDashboard")][0].address // empty') || true
    [ -n "$addr" ] && break
    sleep 0.05
  done
  [ -z "$addr" ] && return 0

  local geo
  geo=$(hyprctl monitors -j 2>/dev/null | jq -r '
    .[] | select(.focused) |
    ((.width / .scale) | floor) as $lw | ((.height / .scale) | floor) as $lh |
    .reserved as [$rl, $rt, $rr, $rb] |
    560 as $w | 8 as $gap |
    "\(.x + $lw - $rr - $w - $gap) \(.y + $rt + $gap) \($w) \($lh - $rt - $rb - 2 * $gap)"
  ') || return 0
  [ -z "$geo" ] && return 0
  local px py pw ph
  read -r px py pw ph <<<"$geo"

  hyprctl dispatch resizewindowpixel "exact $pw $ph,address:$addr" >/dev/null 2>&1 || true
  hyprctl dispatch movewindowpixel "exact $px $py,address:$addr" >/dev/null 2>&1 || true
}

cleanup() {
  printf '\033[?1000;1006l'
  tput cnorm
  tput rmcup
}
trap cleanup EXIT
# claude-dropdown toggles the panel off by sending TERM: exit cleanly so
# ghostty closes the now-empty surface itself, with no confirm-close prompt
# (which is what `hyprctl closewindow` on a live process would trigger).
trap 'exit 0' INT TERM

setup_window
tput smcup
tput civis
printf '\033[?1000;1006h'
clear

DIR_STAMP=""
while true; do
  stamp=$(stat -c %y "$CACHE_DIR" 2>/dev/null) || stamp="?"
  if [ "$stamp" != "$DIR_STAMP" ]; then
    DIR_STAMP=$stamp
    refresh_data
    draw
  elif [ -n "$FLASH" ] && [ $(($(date +%s) - FLASH_TS)) -ge 4 ]; then
    draw  # clear the expired flash line
  fi

  key=""
  if read -rsn1 -t 0.2 key; then
    # keys act on the queue head in approval mode, else the selected row
    target=$SELECTED
    [ ${#QUEUE[@]} -gt 0 ] && target=${QUEUE[0]}
    case "$key" in
      q|Q) exit 0 ;;
      a|A|y|Y) do_approve "$target" ;;
      r|R|n|N) do_reject "$target" ;;
      d|D) do_defer "$target" ;;
      j|J|'') do_jump "$target" ;;   # '' = Enter
      l|L) do_label "$target" ;;
      x|X) do_dismiss "$SELECTED" ;;
      [1-9])
        if [ "$key" -le "$SESSION_COUNT" ] 2>/dev/null; then select_idx "$key"; fi
        ;;
      $'\x1b')
        k2=""
        read -rsn1 -t 0.05 k2 || true
        if [ "$k2" != "[" ]; then
          exit 0  # bare Esc closes the popup
        fi
        k3=""
        read -rsn1 -t 0.05 k3 || true
        case "$k3" in
          A) if [ "$SELECTED" -gt 1 ]; then select_idx $((SELECTED - 1)); fi ;;
          B) if [ "$SELECTED" -lt "$SESSION_COUNT" ]; then select_idx $((SELECTED + 1)); fi ;;
          '<')
            seq=""
            c=""
            while read -rsn1 -t 0.05 c; do
              case "$c" in M|m) break ;; *) seq+="$c" ;; esac
            done
            if [ "${c:-}" = "M" ]; then handle_click "$seq"; fi  # act on press, not release
            ;;
        esac
        ;;
    esac
    draw  # reflect selection moves and action feedback immediately
  fi
done
