#!/usr/bin/env bash
# Back up the context pod (and, optionally, the agents' own memory folders) to an external drive.
#
# Safe mirror: files deleted or changed at the source are moved into _deleted/<timestamp>/ on the drive,
# so a mistake on the host never wipes the only copy.
# Secrets are excluded (.env files, keys). Keep secrets in a password manager instead.
#
# Usage:
#   bash scripts/backup.sh              one backup run
#   bash scripts/backup.sh --loop 3600  run forever, once an hour (for a tmux window)
#
# Config: BACKUP_VOLUME, BACKUP_DEST, BACKUP_AGENT_MEMORY in ~/.config/bebop/studio.env.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_common.sh"

BACKUP_VOLUME="${BACKUP_VOLUME:-}"
BACKUP_DEST="${BACKUP_DEST:-}"
BACKUP_AGENT_MEMORY="${BACKUP_AGENT_MEMORY:-yes}"
BLOG="$LOG_DIR/backup.log"

EXCLUDES=(
  --exclude '.env' --exclude '.env.*' --exclude '*.env'
  --exclude '*.pem' --exclude '*.key' --exclude 'secrets/'
  --exclude 'node_modules/' --exclude '.DS_Store' --exclude '__pycache__/'
)

run_once() {
  local stamp
  stamp="$(date +%Y-%m-%d_%H%M)"

  # Guard rails: never write anywhere unexpected.
  if [ -z "$BACKUP_VOLUME" ] || [ -z "$BACKUP_DEST" ]; then
    echo "$(date '+%F %T') BACKUP_VOLUME / BACKUP_DEST not set, skipped" | tee -a "$BLOG"; return 0
  fi
  case "$BACKUP_DEST" in
    "$BACKUP_VOLUME"/?*) ;;
    *) echo "$(date '+%F %T') BACKUP_DEST must be a folder inside BACKUP_VOLUME, refusing" | tee -a "$BLOG"; return 1 ;;
  esac
  if [ ! -d "$BACKUP_VOLUME" ]; then
    echo "$(date '+%F %T') drive not mounted ($BACKUP_VOLUME), skipped" | tee -a "$BLOG"; return 0
  fi
  if [ ! -d "$STUDIO_DIR" ]; then
    echo "$(date '+%F %T') STUDIO_DIR not found ($STUDIO_DIR), skipped" | tee -a "$BLOG"; return 1
  fi

  mkdir -p "$BACKUP_DEST/studio" "$BACKUP_DEST/_deleted"

  rsync -rt --delete --backup --backup-dir="$BACKUP_DEST/_deleted/$stamp/studio" \
    "${EXCLUDES[@]}" "$STUDIO_DIR/" "$BACKUP_DEST/studio/"

  # Claude Code keeps per-project memory in ~/.claude/projects/*/memory. Copy only those folders plus
  # instructions, settings and custom commands/skills/agents. Never the credentials or channel tokens.
  # If you put API keys in settings.json (the "env" block), set BACKUP_AGENT_MEMORY=no or move the keys out.
  if [ "$BACKUP_AGENT_MEMORY" = "yes" ] && [ -d "$HOME/.claude" ]; then
    mkdir -p "$BACKUP_DEST/agent-memory"
    rsync -rtL --delete --backup --backup-dir="$BACKUP_DEST/_deleted/$stamp/agent-memory" "${EXCLUDES[@]}" \
      --include 'CLAUDE.md' --include 'settings.json' \
      --include 'projects/' --include 'projects/*/' --include 'projects/*/memory/' --include 'projects/*/memory/**' \
      --include 'agents/' --include 'agents/**' --include 'commands/' --include 'commands/**' \
      --include 'skills/' --include 'skills/**' \
      --exclude '*' "$HOME/.claude/" "$BACKUP_DEST/agent-memory/"
  fi

  echo "$(date '+%F %T') backup OK -> $BACKUP_DEST" | tee -a "$BLOG"
}

if [ "${1:-}" = "--loop" ]; then
  interval="${2:-3600}"
  while true; do
    run_once
    sleep "$interval"
  done
else
  run_once
fi
