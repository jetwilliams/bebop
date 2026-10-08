# shellcheck shell=bash
# Shared setup for the Bebop scripts. Sourced, not run.

# launchd and systemd start jobs with a minimal PATH. Add the usual install locations.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

STUDIO_CONFIG="${STUDIO_CONFIG:-$HOME/.config/bebop/studio.env}"
if [ -f "$STUDIO_CONFIG" ]; then
  # shellcheck disable=SC1090
  . "$STUDIO_CONFIG"
fi

# Defaults (used when the config file does not set them).
STUDIO_DIR="${STUDIO_DIR:-$HOME/studio}"
STUDIO_SESSION="${STUDIO_SESSION:-studio}"
MANAGER_WINDOW="${MANAGER_WINDOW:-manager}"
MANAGER_CMD="${MANAGER_CMD:-claude --continue --channels plugin:telegram@claude-plugins-official || claude --channels plugin:telegram@claude-plugins-official}"
MANAGER_MATCH="${MANAGER_MATCH:-claude.*--channels}"
STUDIO_WINDOWS="${STUDIO_WINDOWS:-}"
LOG_DIR="${LOG_DIR:-$HOME/.local/state/bebop}"

mkdir -p "$LOG_DIR"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_DIR/studio.log"
}

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' is not installed or not on PATH" >&2; exit 1; }
}

has_window() {
  tmux list-windows -t "$STUDIO_SESSION" -F '#W' 2>/dev/null | grep -qx "$1"
}
