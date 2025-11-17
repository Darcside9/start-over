#!/usr/bin/env bash
# active-window-logger.sh
# Logs timestamp, PID, process name, and window title every time the active window changes.
# Requires: xdotool, jq (optional for nice formatting), ps, awk

OUTFILE="${HOME}/active_window_log.csv"
: > "$OUTFILE"  # overwrite existing file (or remove to append)
echo "timestamp,window_id,pid,process,window_title" >> "$OUTFILE"

last_win=""

while true; do
  # get active window id (hex) using xdotool
  win=$(xdotool getactivewindow 2>/dev/null)
  if [ -z "$win" ]; then
    sleep 0.5
    continue
  fi

  if [ "$win" != "$last_win" ]; then
    ts=$(date --iso-8601=seconds)
    # get pid owning window
    pid=$(xprop -id "$win" _NET_WM_PID 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
    # fallback if empty
    [ -z "$pid" ] && pid="unknown"
    # process name (best-effort)
    proc="unknown"
    if [ "$pid" != "unknown" ]; then
      proc=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
      proc=$(echo "$proc" | tr -d ',')
    fi
    # window title
    title=$(xdotool getwindowname "$win" 2>/dev/null | tr -d '\n' | sed 's/,/ /g')
    # write CSV line (escape quotes)
    echo "\"$ts\",\"$win\",\"$pid\",\"$proc\",\"$title\"" >> "$OUTFILE"
    last_win="$win"
  fi

  sleep 0.3
done

