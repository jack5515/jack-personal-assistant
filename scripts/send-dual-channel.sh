#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"
CONFIG_FILE="${CONFIG_FILE:-/Users/jyxc/.openclaw/workspace/config/channel-targets.env}"
if [ -f "$CONFIG_FILE" ]; then
  # Load fixed channel targets from workspace config so automation stays pinned.
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi
FEISHU_TARGET="${FEISHU_TARGET:-ou_14ab29b1500a6fa083003a19e543712b}"
WEIXIN_TARGET="${WEIXIN_TARGET:-o9cq804e6C58_WBPHvn6QUyvFp1s@im.wechat}"
WEIXIN_ACCOUNT_ID="${WEIXIN_ACCOUNT_ID:-88052f3acc0f-im-bot}"
DELIVERY_CHANNELS="${DELIVERY_CHANNELS:-feishu,openclaw-weixin}"
DRY_RUN="${DRY_RUN:-0}"
MESSAGE_FILE=""
STATE_FILE=""
STATE_VALUE=""
LOG_FILE=""
LABEL="dual-channel"
SEND_FEISHU=0
SEND_WEIXIN=0

usage() {
  cat <<'EOF'
Usage:
  send-dual-channel.sh \
    --message-file /abs/path/message.md \
    --state-file /abs/path/state.txt \
    --state-value 2026-03-25 \
    --log-file /abs/path/send.log \
    [--label stock-finance]
EOF
}

log() {
  local message="$1"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$LOG_FILE"
}

parse_delivery_channels() {
  local item=""
  local parts=()

  IFS=',' read -r -a parts <<< "$DELIVERY_CHANNELS"
  for item in "${parts[@]}"; do
    item="$(printf '%s' "$item" | tr -d '[:space:]')"
    [ -n "$item" ] || continue
    case "$item" in
      feishu)
        SEND_FEISHU=1
        ;;
      weixin|openclaw-weixin)
        SEND_WEIXIN=1
        ;;
      *)
        echo "Unknown delivery channel: $item" >&2
        exit 1
        ;;
    esac
  done

  if [ "$SEND_FEISHU" != "1" ] && [ "$SEND_WEIXIN" != "1" ]; then
    echo "No delivery channels enabled; set DELIVERY_CHANNELS to feishu, openclaw-weixin, or both" >&2
    exit 1
  fi
}

send_channel() {
  local channel="$1"
  local target="$2"
  local cmd=("$OPENCLAW_BIN" message send --json)
  local output=""
  local parsed=""

  if [ "$DRY_RUN" = "1" ]; then
    cmd+=(--dry-run)
  fi
  if [ "$channel" = "openclaw-weixin" ]; then
    cmd+=(--account "$WEIXIN_ACCOUNT_ID")
  fi

  cmd+=(--channel "$channel" --target "$target" --message "$MESSAGE")

  if output="$("${cmd[@]}" 2>&1)"; then
    parsed="$(printf '%s' "$output" | python3 -c '
import json, sys
raw = sys.stdin.read()
start = raw.find("{")
obj = None
while start != -1:
    try:
        obj = json.loads(raw[start:])
        break
    except json.JSONDecodeError:
        start = raw.find("{", start + 1)
if not isinstance(obj, dict):
    print("json=unparsed")
    raise SystemExit(0)
payload = obj.get("payload") or {}
result = payload.get("result") or {}
message_id = result.get("messageId") or ""
via = payload.get("via") or ""
parts = []
if message_id:
    parts.append(f"messageId={message_id}")
if via:
    parts.append(f"via={via}")
if obj.get("dryRun"):
    parts.append("dryRun=true")
print(" ".join(parts) if parts else "json=parsed")
' 2>/dev/null || true)"
    [ -n "$parsed" ] && log "ack: $LABEL $channel $parsed"
    return 0
  fi

  log "error: $LABEL $channel failed: $output"
  return 1
}

state_matches() {
  local file_path="$1"
  if [ ! -f "$file_path" ]; then
    return 1
  fi
  [ "$(cat "$file_path" || true)" = "$STATE_VALUE" ]
}

mark_state() {
  local file_path="$1"
  printf '%s\n' "$STATE_VALUE" > "$file_path"
}

process_channel() {
  local channel="$1"
  local target="$2"
  local state_path="$3"

  if state_matches "$state_path"; then
    log "skip: $LABEL $channel already sent ($STATE_VALUE)"
    return 0
  fi

  if ! send_channel "$channel" "$target"; then
    return 1
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "dry-run: $LABEL $channel ($STATE_VALUE)"
    return 0
  fi

  mark_state "$state_path"
  log "sent: $LABEL $channel ($STATE_VALUE)"
  return 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --message-file)
      MESSAGE_FILE="${2:-}"
      shift 2
      ;;
    --state-file)
      STATE_FILE="${2:-}"
      shift 2
      ;;
    --state-value)
      STATE_VALUE="${2:-}"
      shift 2
      ;;
    --log-file)
      LOG_FILE="${2:-}"
      shift 2
      ;;
    --label)
      LABEL="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$MESSAGE_FILE" ] || [ -z "$STATE_FILE" ] || [ -z "$STATE_VALUE" ] || [ -z "$LOG_FILE" ]; then
  usage >&2
  exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

if [ ! -f "$MESSAGE_FILE" ]; then
  log "skip: $LABEL message file missing"
  exit 1
fi

MESSAGE="$(cat "$MESSAGE_FILE")"
if [ -z "$MESSAGE" ]; then
  log "skip: $LABEL message file empty"
  exit 1
fi

parse_delivery_channels

STATUS=0
if [ "$SEND_FEISHU" = "1" ]; then
  process_channel "feishu" "$FEISHU_TARGET" "${STATE_FILE}.feishu" || STATUS=1
else
  log "skip: $LABEL feishu disabled by DELIVERY_CHANNELS=$DELIVERY_CHANNELS"
fi

if [ "$SEND_WEIXIN" = "1" ]; then
  process_channel "openclaw-weixin" "$WEIXIN_TARGET" "${STATE_FILE}.weixin" || STATUS=1
else
  log "skip: $LABEL openclaw-weixin disabled by DELIVERY_CHANNELS=$DELIVERY_CHANNELS"
fi

exit "$STATUS"
