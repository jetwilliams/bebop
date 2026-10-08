#!/usr/bin/env bash
# Watchdog: if the manager agent is not running, restart it. Nothing else.
#
# Run it every few minutes from launchd (macOS) or a systemd timer (Linux); templates are in scripts/service/.
# It only ever touches the manager window. Other windows hold project agents in the middle of work, and
# restarting them would lose that work.
#
# Config: ~/.config/bebop/studio.env, or set STUDIO_CONFIG. Same variables as studio-up.sh.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

WLOG="$LOG_DIR/watchdog.log"
wlog() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$WLOG"; }

command -v tmux >/dev/null 2>&1 || { wlog "tmux not found on PATH ($PATH)"; exit 1; }

# Healthy: nothing to do.
if pgrep -f "$MANAGER_MATCH" >/dev/null; then
  exit 0
fi

if [ ! -d "$STUDIO_DIR" ]; then
  # On macOS this usually means the folder is under ~/Desktop or ~/Documents, which launchd jobs cannot read.
  wlog "manager down, but STUDIO_DIR is not readable: $STUDIO_DIR"
  exit 1
fi

if tmux has-session -t "$STUDIO_SESSION" 2>/dev/null; then
  if has_window "$MANAGER_WINDOW"; then
    wlog "manager down -> respawning the manager window"
    tmux respawn-pane -k -t "$STUDIO_SESSION:$MANAGER_WINDOW" -c "$STUDIO_DIR"
  else
    wlog "manager window missing -> creating it"
    tmux new-window -d -t "$STUDIO_SESSION" -n "$MANAGER_WINDOW" -c "$STUDIO_DIR"
  fi
  sleep 1
  tmux send-keys -t "$STUDIO_SESSION:$MANAGER_WINDOW" "$MANAGER_CMD" C-m
else
  wlog "no tmux session -> running studio-up.sh"
  bash "$(cd "$(dirname "$0")" && pwd)/studio-up.sh" >> "$WLOG" 2>&1
fi
