#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

BASE_DIR="/Users/jyxc/.openclaw/workspace"
OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"
TASK_FILE="$BASE_DIR/workfiles/lenny-daily-cards-task.md"
STATE_FILE="$BASE_DIR/memory/lenny-daily-cards-state.json"
CARD_FILE="$BASE_DIR/workfiles/lenny-daily-cards-latest.md"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/lenny-daily-cards-generate.log"
TMP_JSON="$(mktemp)"
TODAY="$(date '+%Y-%m-%d')"

mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$STATE_FILE")"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

cleanup() {
  rm -f "$TMP_JSON"
}
trap cleanup EXIT

if [ ! -f "$TASK_FILE" ]; then
  log "error: task file missing"
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" <<'EOF'
{
  "last_run_date": "",
  "history": []
}
EOF
fi

PROMPT=$(cat <<'EOF'
你是一个严格按要求产出内容的 daily card generator。

任务：基于工作区里的 workfiles/lenny-daily-cards-task.md、memory/lenny-daily-cards-state.json 和 external-knowledge/lennys-newsletterpodcastdata，生成今天（__TODAY__）的 Lenny AI 产品学习卡片。

硬性要求：
1. 先读取任务文件和状态文件。
2. 优先避开最近 14 天已经使用过的 source 文件；如果不够，可以复用，但必须换角度。
3. 输出 5 条卡片，中文，简洁，强调“可直接借鉴”，不要编造。
4. 每条都必须给出真实 source 文件路径和对应日期。
5. 输出必须严格按下面格式，不要多余解释。
6. used_sources 必须列出实际使用到的 source 文件路径；card_titles 必须与正文 5 条标题一致。
7. 如果你需要运行本地命令，只能使用当前机器可用的基础命令；不要调用 `python`，只假设 `python3` 可能可用。

请严格返回：
<<<CARDS>>>
标题：Lenny AI 产品学习卡片 __TODAY__

1. 标题
- 观点：...
- 借鉴：...
- 来源：path/to/file.md + YYYY-MM-DD

2. ...
<<<META>>>
{"used_sources":["..."],"card_titles":["...","...","...","...","..."]}
EOF
)
PROMPT=${PROMPT//__TODAY__/$TODAY}

if ! "$OPENCLAW_BIN" agent --agent main --json --timeout 600 --message "$PROMPT" > "$TMP_JSON" 2>> "$LOG_FILE"; then
  log "error: openclaw agent generation failed"
  exit 1
fi

python3 - "$TMP_JSON" "$CARD_FILE" "$STATE_FILE" "$TODAY" "$LOG_FILE" <<'PY'
import json
import pathlib
import re
import sys
from datetime import datetime

json_path = pathlib.Path(sys.argv[1])
card_path = pathlib.Path(sys.argv[2])
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

match = re.search(r"<<<CARDS>>>\s*(.*?)\s*<<<META>>>\s*(\{.*\})\s*$", text, re.S)
if not match:
    raise SystemExit("output format mismatch")
card_text = match.group(1).strip() + "\n"
meta = json.loads(match.group(2))
used_sources = meta.get("used_sources", [])
card_titles = meta.get("card_titles", [])

if today not in card_text:
    raise SystemExit("generated card missing today date")
if len(card_titles) != 5:
    raise SystemExit("card_titles count is not 5")
if len(used_sources) < 1:
    raise SystemExit("used_sources is empty")

card_path.write_text(card_text)

state = {"last_run_date": "", "history": []}
if state_path.exists():
    try:
        state = json.loads(state_path.read_text())
    except Exception:
        pass

history = state.get("history", [])
history.insert(0, {
    "date": today,
    "used_sources": used_sources,
    "card_titles": card_titles,
})
state["last_run_date"] = today
state["history"] = history[:30]
state_path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n")

with log_file.open("a") as fh:
    fh.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] generated: {card_path}\n")
PY

log "done"
