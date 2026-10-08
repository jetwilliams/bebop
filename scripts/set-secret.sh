#!/usr/bin/env bash
# Store a secret in a .env file through a hidden prompt.
#
# The value is typed by you at the host's keyboard (or over SSH). It never appears on screen, in shell history,
# in the process list or in any chat transcript. The file is created with permissions 600.
#
# Usage: bash scripts/set-secret.sh <env-file> <NAME>
# Example (Telegram bot token for the Claude Code Telegram plugin):
#   bash scripts/set-secret.sh ~/.claude/channels/telegram/.env TELEGRAM_BOT_TOKEN
#
# To check that a key exists later, without showing it:
#   grep -c '^TELEGRAM_BOT_TOKEN=' ~/.claude/channels/telegram/.env
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <env-file> <NAME>" >&2
  exit 2
fi
file="$1"
name="$2"

if ! [[ "$name" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
  echo "error: NAME must be UPPER_CASE letters, digits and underscores" >&2
  exit 2
fi
if [ ! -t 0 ]; then
  echo "error: run this in an interactive terminal (it reads the value from a hidden prompt)" >&2
  exit 2
fi

umask 077
mkdir -p "$(dirname "$file")"

IFS= read -r -s -p "Value for $name (hidden): " value
echo
if [ -z "$value" ]; then
  echo "error: empty value, nothing changed" >&2
  exit 1
fi

tmp="$(mktemp "${file}.XXXXXX")"
if [ -f "$file" ]; then
  grep -v "^${name}=" "$file" > "$tmp" || true
fi
printf '%s=%s\n' "$name" "$value" >> "$tmp"   # printf is a shell builtin: the value never shows in ps
unset value
mv "$tmp" "$file"
chmod 600 "$file"

echo "Saved $name to $file (permissions 600)."
