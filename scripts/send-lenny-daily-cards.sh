#!/bin/bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
CARD_FILE="$BASE_DIR/workfiles/lenny-daily-cards-latest.md"
STATE_FILE="$BASE_DIR/memory/lenny-daily-cards-send-state.txt"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/lenny-daily-cards-send.log"
TARGET="ou_14ab29b1500a6fa083003a19e543712b"
TODAY="$(date '+%Y-%m-%d')"

mkdir -p "$LOG_DIR"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

if [ ! -f "$CARD_FILE" ]; then
  log "skip: card file missing"
  exit 1
fi

if ! grep -q "$TODAY" "$CARD_FILE"; then
  log "skip: card file is not for today"
  exit 0
fi

LAST_SENT_DATE=""
if [ -f "$STATE_FILE" ]; then
  LAST_SENT_DATE=$(cat "$STATE_FILE" || true)
fi

if [ "$LAST_SENT_DATE" = "$TODAY" ]; then
  log "skip: already sent today"
  exit 0
fi

MESSAGE=$(cat "$CARD_FILE")
if [ -z "$MESSAGE" ]; then
  log "skip: card file empty"
  exit 1
fi

/opt/homebrew/bin/openclaw message send --channel feishu --target "$TARGET" --message "$MESSAGE" >/dev/null
echo "$TODAY" > "$STATE_FILE"
log "sent: $CARD_FILE"
