#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

BASE_DIR="/Users/jyxc/.openclaw/workspace"
# Use the real binary so cron/background runs do not depend on shell wrappers.
OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"
DUAL_SENDER="$BASE_DIR/scripts/send-dual-channel.sh"
CONFIG_FILE="${CONFIG_FILE:-$BASE_DIR/config/channel-targets.env}"
OUTPUT_FILE="$BASE_DIR/workfiles/ai-trend-watch-latest.md"
RUN_STATE_FILE="$BASE_DIR/memory/ai-trend-watch-state.json"
SEND_STATE_FILE="$BASE_DIR/memory/ai-trend-watch-send-state.txt"
if [ -f "$CONFIG_FILE" ]; then
  # Keep cron/manual runs aligned with the workspace channel defaults.
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi
WATCH_CHANNELS="${AI_TREND_WATCH_CHANNELS:-feishu,openclaw-weixin}"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/ai-trend-watch.log"
TMP_JSON="$(mktemp)"
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
你是一个严格按要求产出内容的 AI 巡检执行器。

任务：
1. 先读取 workfiles/ai-trend-watch-task.md。
2. 当前北京时间：__NOW__
3. 只保留真正值得 Jack 创业判断关注的高价值 signal。
4. 如果没有达到阈值，必须只返回 NO_REPLY。
5. 如果达到阈值，只返回最终简报正文，不要过程说明。
6. 不要主动发送消息，本脚本会负责投递。
7. 严格按 task 里的证据优先级、thesis 挂载和创业动作要求执行，不要回退成普通行业新闻摘要。
8. 如果你需要运行本地命令，只能使用当前机器可用的基础命令；不要调用 `python`，只假设 `python3` 可能可用。
EOF
)
PROMPT="${PROMPT//__NOW__/$NOW}"

if ! "$OPENCLAW_BIN" agent --agent main --json --timeout 1200 --message "$PROMPT" > "$TMP_JSON" 2>> "$LOG_FILE"; then
  log "error: openclaw agent generation failed"
  exit 1
fi

RESULT="$(
python3 - "$TMP_JSON" "$OUTPUT_FILE" "$RUN_STATE_FILE" "$LOG_FILE" <<'PY'
import hashlib
import json
import pathlib
import sys
from datetime import datetime

json_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
state_path = pathlib.Path(sys.argv[3])
log_file = pathlib.Path(sys.argv[4])

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
summary_text = first_text(raw.get("summary")) or first_text(raw.get("result", {}).get("summary")) or ""
if not text:
    text = summary_text

FORMAL_MARKERS = ("已完成", "候选", "低置信度", "待验证")
PROCESS_HINTS = (
    "先做",
    "我先",
    "继续",
    "只读核查",
    "command not found",
    "退回 `grep`",
    "退回 grep",
    "最近 3 天官方源最小核查",
)

def is_formal_briefing(value):
    if not value:
        return False
    if value == "NO_REPLY":
        return True
    marker_count = sum(1 for marker in FORMAL_MARKERS if marker in value)
    if marker_count == 0:
        return False
    stripped = value.strip()
    if any(hint in stripped for hint in PROCESS_HINTS):
        return False
    return True

state = {"version": 2}
if state_path.exists():
    try:
        state = json.loads(state_path.read_text())
    except Exception:
        pass

now = datetime.now().isoformat(timespec="seconds")
if not text:
    raw_head = raw_text[:1200].replace("\n", "\\n")
    state.update({
        "version": 2,
        "lastStatus": "empty_result",
        "lastRunAt": now,
        "lastPayloadCount": len(payloads) if isinstance(payloads, list) else 0,
        "lastSummaryPresent": bool(summary_text),
        "lastJsonKeys": sorted(list(raw.keys()))[:20] if isinstance(raw, dict) else [],
        "lastRawPreview": raw_head,
    })
    state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    with log_file.open("a") as fh:
        fh.write(
            f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] empty-result payload_count={len(payloads) if isinstance(payloads, list) else 0} summary_present={bool(summary_text)} keys={sorted(list(raw.keys()))[:20] if isinstance(raw, dict) else []} raw_preview={raw_head}\n"
        )
    print("NO_REPLY")
    raise SystemExit(0)

if text == "NO_REPLY":
    state.update({
        "version": 2,
        "lastStatus": "no_reply",
        "lastRunAt": now,
    })
    state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    with log_file.open("a") as fh:
        fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] no-reply\n")
    print("NO_REPLY")
    raise SystemExit(0)

if not is_formal_briefing(text):
    preview = text[:400].replace("\n", "\\n")
    state.update({
        "version": 2,
        "lastStatus": "filtered_non_briefing",
        "lastRunAt": now,
        "lastPreview": preview,
    })
    state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    with log_file.open("a") as fh:
        fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] filtered-non-briefing preview={preview}\n")
    print("NO_REPLY")
    raise SystemExit(0)

output_path.write_text(text + "\n")
content_hash = hashlib.sha256((text + "\n").encode("utf-8")).hexdigest()
state.update({
    "version": 2,
    "lastStatus": "generated",
    "lastRunAt": now,
    "lastFile": str(output_path),
    "lastHash": content_hash,
})
state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")

with log_file.open("a") as fh:
    fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] generated: {output_path} hash={content_hash}\n")

print(content_hash)
PY
)"

if [ "$RESULT" = "NO_REPLY" ]; then
  log "done: no reply"
  exit 0
fi

DELIVERY_CHANNELS="$WATCH_CHANNELS" "$DUAL_SENDER" \
  --message-file "$OUTPUT_FILE" \
  --state-file "$SEND_STATE_FILE" \
  --state-value "$RESULT" \
  --log-file "$LOG_FILE" \
  --label "ai-trend-watch"

log "done: sent hash=$RESULT"
