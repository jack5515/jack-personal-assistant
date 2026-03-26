#!/bin/bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
CARD_FILE="$BASE_DIR/workfiles/lenny-daily-cards-latest.md"
STATE_FILE="$BASE_DIR/memory/lenny-daily-cards-send-state.txt"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/lenny-daily-cards-send.log"
DUAL_SENDER="$BASE_DIR/scripts/send-dual-channel.sh"
HANDOFF_UPDATER="$BASE_DIR/scripts/update-channel-handoff.sh"
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

if [ ! -x "$DUAL_SENDER" ]; then
  log "error: dual sender missing or not executable"
  exit 1
fi

"$DUAL_SENDER" \
  --message-file "$CARD_FILE" \
  --state-file "$STATE_FILE" \
  --state-value "$TODAY" \
  --log-file "$LOG_FILE" \
  --label "lenny-daily-cards"

if [ -x "$HANDOFF_UPDATER" ]; then
  if ! "$HANDOFF_UPDATER" \
    --source "lenny-daily-cards" \
    --status "delivered" \
    --content-file "$CARD_FILE" \
    --note "Lenny 学习卡片已双发到飞书和微信。dedupe=$TODAY" >> "$LOG_FILE" 2>&1; then
    log "warn: failed to update channel handoff"
  fi
fi

log "done: $CARD_FILE"
