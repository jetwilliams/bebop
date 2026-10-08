#!/usr/bin/env bash
# Start the studio: a tmux session with the manager window plus the windows listed in STUDIO_WINDOWS.
# Safe to re-run: windows that already exist are left alone.
#
# Usage: bash scripts/studio-up.sh
# Config: ~/.config/bebop/studio.env (see studio.env.example), or set STUDIO_CONFIG.
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

need tmux

if [ ! -d "$STUDIO_DIR" ]; then
  echo "error: STUDIO_DIR does not exist: $STUDIO_DIR" >&2
  exit 1
fi

# 1. Session + manager window.
if ! tmux has-session -t "$STUDIO_SESSION" 2>/dev/null; then
  tmux new-session -d -s "$STUDIO_SESSION" -n "$MANAGER_WINDOW" -c "$STUDIO_DIR"
  tmux send-keys -t "$STUDIO_SESSION:$MANAGER_WINDOW" "$MANAGER_CMD" C-m
  log "up: created session '$STUDIO_SESSION' and started the manager"
elif ! has_window "$MANAGER_WINDOW"; then
  tmux new-window -d -t "$STUDIO_SESSION" -n "$MANAGER_WINDOW" -c "$STUDIO_DIR"
  tmux send-keys -t "$STUDIO_SESSION:$MANAGER_WINDOW" "$MANAGER_CMD" C-m
  log "up: manager window was missing, started it"
elif ! pgrep -f "$MANAGER_MATCH" >/dev/null; then
  log "up: manager window exists but the manager is not running (the watchdog will restart it, or run watchdog.sh)"
else
  log "up: manager already running"
fi

# 2. Extra windows, one per line: name|dir|command
while IFS='|' read -r name dir cmd; do
  name="$(echo "$name" | xargs)"   # trim spaces
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  dir="${dir:-$STUDIO_DIR}"
  if has_window "$name"; then
    continue
  fi
  if [ ! -d "$dir" ]; then
    log "up: skipped window '$name': folder not found: $dir"
    continue
  fi
  tmux new-window -d -t "$STUDIO_SESSION" -n "$name" -c "$dir"
  if [ -n "$(echo "$cmd" | xargs)" ]; then
    # Typed into the window's shell, so the window survives if the command exits.
    tmux send-keys -t "$STUDIO_SESSION:$name" "$cmd" C-m
  fi
  log "up: opened window '$name'"
done <<< "$STUDIO_WINDOWS"

# 3. Summary.
echo
echo "Session '$STUDIO_SESSION':"
tmux list-windows -t "$STUDIO_SESSION" -F '  #{window_index}: #W  (#{pane_current_command})'
echo
echo "Attach with: tmux attach -t $STUDIO_SESSION"
