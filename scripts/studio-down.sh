#!/usr/bin/env bash
# Stop the studio.
#
# Usage:
#   bash scripts/studio-down.sh           stop the windows listed in STUDIO_WINDOWS; keep the manager running
#   bash scripts/studio-down.sh --all     stop every window, including the manager, and end the session
#
# Each window first gets Ctrl-C and a short grace period (STOP_GRACE seconds, default 5) so running programs can
# exit cleanly, then the window is closed.
#
# Note: with --all, also stop the watchdog first, or it will start the manager again within a few minutes.
#   macOS:  launchctl bootout gui/$(id -u)/<your watchdog label>
#   Linux:  systemctl --user stop bebop-watchdog.timer
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

need tmux
GRACE="${STOP_GRACE:-5}"
ALL="no"
[ "${1:-}" = "--all" ] && ALL="yes"

if ! tmux has-session -t "$STUDIO_SESSION" 2>/dev/null; then
  echo "Session '$STUDIO_SESSION' is not running."
  exit 0
fi

stop_window() {
  local name="$1"
  has_window "$name" || return 0
  tmux send-keys -t "$STUDIO_SESSION:$name" C-c 2>/dev/null || true
  sleep "$GRACE"
  tmux kill-window -t "$STUDIO_SESSION:$name" 2>/dev/null || true
  log "down: closed window '$name'"
}

if [ "$ALL" = "yes" ]; then
  for name in $(tmux list-windows -t "$STUDIO_SESSION" -F '#W'); do
    [ "$name" = "$MANAGER_WINDOW" ] && continue
    stop_window "$name"
  done
  stop_window "$MANAGER_WINDOW"
  tmux kill-session -t "$STUDIO_SESSION" 2>/dev/null || true
  log "down: session '$STUDIO_SESSION' ended"
  exit 0
fi

while IFS='|' read -r name _dir _cmd; do
  name="$(echo "$name" | xargs)"
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  [ "$name" = "$MANAGER_WINDOW" ] && continue
  stop_window "$name"
done <<< "$STUDIO_WINDOWS"

echo "Done. The manager window was left running. Use --all to stop everything."
