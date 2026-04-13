#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

BASE_DIR="/Users/jyxc/.openclaw/workspace"
OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"
DUAL_SENDER="$BASE_DIR/scripts/send-dual-channel.sh"
HANDOFF_UPDATER="$BASE_DIR/scripts/update-channel-handoff.sh"
CONFIG_FILE="${CONFIG_FILE:-$BASE_DIR/config/channel-targets.env}"
OUTPUT_FILE="$BASE_DIR/workfiles/stock-finance-daily-latest.md"
RUN_STATE_FILE="$BASE_DIR/memory/stock-finance-daily-state.json"
SEND_STATE_FILE="$BASE_DIR/memory/stock-finance-daily-send-state.txt"
if [ -f "$CONFIG_FILE" ]; then
  # Keep cron/manual runs aligned with the workspace channel defaults.
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi
BRIEFING_CHANNELS="${STOCK_FINANCE_DAILY_CHANNELS:-feishu}"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/stock-finance-daily.log"
TMP_JSON="$(mktemp)"
TODAY="$(date '+%Y-%m-%d')"

mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$RUN_STATE_FILE")"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

cleanup() {
  rm -f "$TMP_JSON"
}
trap cleanup EXIT

if [ ! -x "$DUAL_SENDER" ]; then
  log "error: dual sender missing or not executable"
  exit 1
fi

PROMPT=$(cat <<'EOF'
你是一个严格按要求产出内容的股票财经晨报生成器。

任务：
1. 先读取 workfiles/stock-finance-daily-task.md。
2. 基于公开信息，为今天（__TODAY__）生成 Jack 的中文晨报。
3. 标题必须是：股票财经每日简报 - __TODAY__
4. 必须包含且只包含这四个一级部分：已完成、候选、低置信度、待验证。
5. 不要过程说明，不要假装有终端级实时精度，不要编造。
6. 如果你需要运行本地命令，只能使用当前机器可用的基础命令；不要调用 `python`，只假设 `python3` 可能可用。

最终只返回晨报正文。
EOF
)
PROMPT="${PROMPT//__TODAY__/$TODAY}"

if ! "$OPENCLAW_BIN" agent --agent main --json --timeout 900 --message "$PROMPT" > "$TMP_JSON" 2>> "$LOG_FILE"; then
  log "error: openclaw agent generation failed"
  exit 1
fi

python3 - "$TMP_JSON" "$OUTPUT_FILE" "$RUN_STATE_FILE" "$TODAY" "$LOG_FILE" <<'PY'
import json
import pathlib
import sys
from datetime import datetime

json_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
state_path = pathlib.Path(sys.argv[3])
today = sys.argv[4]
log_file = pathlib.Path(sys.argv[5])

raw_text = json_path.read_text()
start = raw_text.find('{')
while start != -1:
    chunk = raw_text[start:]
    try:
        raw = json.loads(chunk)
        break
    except json.JSONDecodeError:
        start = raw_text.find('{', start + 1)
else:
    raise SystemExit('missing json payload')


def first_text(value):
    if isinstance(value, str):
        text = value.strip()
        return text or None
    if isinstance(value, list):
        parts = []
        for item in value:
            if isinstance(item, dict):
                candidate = item.get("text") or item.get("content")
                if isinstance(candidate, str) and candidate.strip():
                    parts.append(candidate.strip())
            elif isinstance(item, str) and item.strip():
                parts.append(item.strip())
        if parts:
            return "\n\n".join(parts)
    return None


payloads = raw.get("payloads") or raw.get("result", {}).get("payloads", [])
texts = [payload.get("text", "").strip() for payload in payloads if isinstance(payload, dict) and payload.get("text")]
text = "\n\n".join(item for item in texts if item).strip()
if not text:
    text = first_text(raw.get("summary")) or first_text(raw.get("result", {}).get("summary")) or ""
if not text:
    raise SystemExit("missing text payload")
if f"股票财经每日简报 - {today}" not in text:
    raise SystemExit("generated briefing missing title/date")
for section in ("已完成", "候选", "低置信度", "待验证"):
    if section not in text:
        raise SystemExit(f"generated briefing missing section: {section}")

output_path.write_text(text + "\n")

state = {
    "version": 2,
    "createdAt": today,
}
if state_path.exists():
    try:
        state = json.loads(state_path.read_text())
    except Exception:
        pass

state.update({
    "version": 2,
    "lastRunDate": today,
    "lastStatus": "generated",
    "lastFile": str(output_path),
    "updatedAt": datetime.now().isoformat(timespec="seconds"),
})
state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")

with log_file.open("a") as fh:
    fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] generated: {output_path}\n")
PY

DELIVERY_CHANNELS="$BRIEFING_CHANNELS" "$DUAL_SENDER" \
  --message-file "$OUTPUT_FILE" \
  --state-file "$SEND_STATE_FILE" \
  --state-value "$TODAY" \
  --log-file "$LOG_FILE" \
  --label "stock-finance-daily"

if [ -x "$HANDOFF_UPDATER" ]; then
  if ! "$HANDOFF_UPDATER" \
    --source "stock-finance-daily" \
    --status "delivered" \
    --content-file "$OUTPUT_FILE" \
    --note "股票财经晨报已按当前通道配置投递。channels=$BRIEFING_CHANNELS dedupe=$TODAY" >> "$LOG_FILE" 2>&1; then
    log "warn: failed to update channel handoff"
  fi
fi

log "done"
