#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

BASE_DIR="/Users/jyxc/.openclaw/workspace"
OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"
DUAL_SENDER="$BASE_DIR/scripts/send-dual-channel.sh"
HANDOFF_UPDATER="$BASE_DIR/scripts/update-channel-handoff.sh"
OUTPUT_FILE="$BASE_DIR/workfiles/ai-trend-daily-latest.md"
RUN_STATE_FILE="$BASE_DIR/memory/ai-trend-daily-state.json"
SEND_STATE_FILE="$BASE_DIR/memory/ai-trend-daily-send-state.txt"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/ai-trend-daily.log"
TMP_JSON="$(mktemp)"
TODAY="$(TZ=Asia/Shanghai date '+%Y-%m-%d')"
NOW="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S %z')"

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
你是一个严格按要求产出内容的 AI 巡检日报生成器。

任务：
1. 先读取 workfiles/ai-trend-watch-task.md。
2. 当前北京时间：__NOW__。
3. 为今天（__TODAY__）生成一份固定日报，不允许返回 NO_REPLY。
4. 即使今天没有足够强的高价值 signal，也必须生成日报，并在“已完成”里明确写“今日无强 signal”；不要伪造发现。
5. 标题必须是：AI 巡检日报 - __TODAY__。
6. 必须包含且只包含这四个一级部分：已完成、候选、低置信度、待验证。
7. 每个部分都可以为空，但不能省略；没有内容时写“无”。
8. 优先给出 0-2 条真正值得看的信号；证据不足就降级，不要硬凑。
9. 最终只返回日报正文，不要过程说明，不要发送动作。
10. 如果你需要运行本地命令，只能使用当前机器可用的基础命令；不要调用 `python`，只假设 `python3` 可能可用。
EOF
)
PROMPT="${PROMPT//__TODAY__/$TODAY}"
PROMPT="${PROMPT//__NOW__/$NOW}"

if ! "$OPENCLAW_BIN" agent --agent main --json --timeout 1200 --message "$PROMPT" > "$TMP_JSON" 2>> "$LOG_FILE"; then
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

raw_text = json_path.read_text(errors="replace")
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
if f"AI 巡检日报 - {today}" not in text:
    raise SystemExit("generated briefing missing title/date")
for section in ("已完成", "候选", "低置信度", "待验证"):
    if section not in text:
        raise SystemExit(f"generated briefing missing section: {section}")

output_path.write_text(text + "\n")

state = {"version": 1}
if state_path.exists():
    try:
        state = json.loads(state_path.read_text())
    except Exception:
        pass

state.update({
    "version": 1,
    "lastRunDate": today,
    "lastStatus": "generated",
    "lastFile": str(output_path),
    "updatedAt": datetime.now().isoformat(timespec="seconds"),
})
state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")

with log_file.open("a") as fh:
    fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] generated: {output_path}\n")
PY

MESSAGE="$(cat "$OUTPUT_FILE")"
if [ -z "$MESSAGE" ]; then
  log "error: daily message file empty"
  exit 1
fi

"$DUAL_SENDER" \
  --message-file "$OUTPUT_FILE" \
  --state-file "$SEND_STATE_FILE" \
  --state-value "$TODAY" \
  --log-file "$LOG_FILE" \
  --label "ai-trend-daily"

if [ -x "$HANDOFF_UPDATER" ]; then
  if ! "$HANDOFF_UPDATER" \
    --source "ai-trend-daily" \
    --status "delivered" \
    --content-file "$OUTPUT_FILE" \
    --note "AI 巡检日报已按默认双发链路投递，微信优先。dedupe=$TODAY" >> "$LOG_FILE" 2>&1; then
    log "warn: failed to update channel handoff"
  fi
fi

log "done"
