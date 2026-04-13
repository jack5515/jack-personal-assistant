#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode, urlsplit
from urllib.request import Request, urlopen


TYPE_LABELS = {
    1: "",
    3: "[图片]",
    34: "[语音]",
    43: "[视频]",
    47: "[表情]",
    49: "[引用/链接]",
    50: "[语音通话]",
    10000: "[系统消息]",
}

MAX_CHATS = 12
MAX_MSGS_PER_CHAT = 6
MAX_TOTAL_MSGS = 40
MAX_PREVIEW_LEN = 80
INTEREST_THRESHOLD = 2
EXCLUDED_CHAT_IDS = {
    "zhangxiaokunkitty",
}
EXCLUDED_CHAT_NAMES = {
    "坤宝宝",
}

INTEREST_CHAT_KEYWORDS = (
    "ai",
    "agent",
    "openclaw",
    "模型",
    "大模型",
    "开发者",
    "技术",
    "极客",
    "产品",
    "创业",
    "增长",
    "知识星球",
    "投资",
    "财经",
    "股票",
    "量化",
    "基金",
    "证券",
    "猎头",
    "招聘",
)

INTEREST_MESSAGE_KEYWORDS = (
    "ai",
    "agent",
    "openclaw",
    "gpt",
    "openai",
    "claude",
    "gemini",
    "grok",
    "deepseek",
    "kimi",
    "qwen",
    "llm",
    "模型",
    "大模型",
    "推理",
    "训练",
    "微调",
    "agentic",
    "benchmark",
    "eval",
    "上线",
    "公测",
    "内测",
    "发布",
    "demo",
    "增长",
    "留存",
    "转化",
    "商业化",
    "变现",
    "用户研究",
    "招聘",
    "内推",
    "机会",
    "合作",
    "面试",
    "offer",
    "融资",
    "创业",
    "投资",
    "股票",
    "美股",
    "港股",
    "a股",
    "纳指",
    "标普",
    "特斯拉",
    "英伟达",
    "tsla",
    "nvda",
    "财报",
    "估值",
    "比特币",
    "btc",
    "eth",
    "原油",
    "黄金",
    "利率",
    "银行跌",
    "银行涨",
)

PROMO_KEYWORDS = (
    "粉丝群",
    "福利群",
    "会员群",
    "复制整段",
    "腹制",
    "去陶",
    "淘丨宝",
    "淘宝",
    "官旗",
    "旗舰店",
    "消费券",
    "折扣",
    "返利",
    "秒杀",
    "拼团",
    "冰淇淋",
    "超市",
    "外卖",
    "店铺",
    "下单",
    "拍下",
    "优惠",
)


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def log_line(log_file: Path, message: str) -> None:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("a", encoding="utf-8") as fh:
        fh.write(f"[{now_str()}] {message}\n")


def read_env_file(path: Path) -> Dict[str, str]:
    data: Dict[str, str] = {}
    if not path.exists():
        return data
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def build_request_url(base_url: str, path: str, params: Optional[Dict[str, int]] = None) -> str:
    url = f"{base_url.rstrip('/')}{path}"
    scheme = urlsplit(base_url).scheme.lower()
    if scheme == "file" or not params:
        return url
    query = urlencode(params)
    separator = "&" if "?" in url else "?"
    return f"{url}{separator}{query}"


def http_json(base_url: str, token: str, path: str, params: Optional[Dict[str, int]] = None):
    url = build_request_url(base_url, path, params)
    headers = {"Accept": "application/json"}
    if urlsplit(url).scheme.lower() != "file":
        headers["Authorization"] = f"Bearer {token}"
    req = Request(url, headers=headers)
    with urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_chats(base_url: str, token: str, limit: int) -> List[dict]:
    return http_json(base_url, token, "/api/chats", {"limit": limit})


def fetch_messages(base_url: str, token: str, chat_id: str, limit: int) -> List[dict]:
    return http_json(base_url, token, f"/api/messages/{quote(chat_id, safe='')}", {"limit": limit})


def compact_text(text: Optional[str], limit: int = MAX_PREVIEW_LEN) -> str:
    if not text:
        return ""
    cleaned = " ".join(str(text).split())
    if len(cleaned) <= limit:
        return cleaned
    return cleaned[: limit - 1] + "…"


def normalize(value: Optional[str]) -> str:
    return str(value or "").strip().lower()


def contains_any(text: str, keywords: Tuple[str, ...]) -> bool:
    return any(keyword in text for keyword in keywords)


def render_message(msg: dict) -> str:
    msg_type = int(msg.get("type") or 0)
    content = compact_text(msg.get("content"))
    if msg_type == 49:
        reply = msg.get("reply") or {}
        reply_content = compact_text(reply.get("content"))
        if content and not content.startswith("<?xml"):
            return content
        if reply_content:
            return f"[引用] {reply_content}"
    if msg_type == 3:
        return "[图片]"
    if msg_type == 34:
        return "[语音]"
    if msg_type == 43:
        return "[视频]"
    if msg_type == 47:
        return "[表情]"
    if msg_type == 10000:
        return compact_text(msg.get("content"), 60) or "[系统消息]"
    if content:
        return content
    return TYPE_LABELS.get(msg_type, f"[类型{msg_type}]")


def interest_score(chat: dict, msg: dict) -> int:
    chat_text = " ".join(
        [
            normalize(chat.get("name")),
            normalize(chat.get("remark")),
            normalize(chat.get("username")),
        ]
    )
    content_text = " ".join(
        [
            normalize(msg.get("content")),
            normalize((msg.get("reply") or {}).get("content")),
            normalize(msg.get("senderName")),
        ]
    )
    score = 0
    if contains_any(chat_text, INTEREST_CHAT_KEYWORDS):
        score += 1
    if contains_any(content_text, INTEREST_MESSAGE_KEYWORDS):
        score += 2
    if contains_any(chat_text, PROMO_KEYWORDS):
        score -= 3
    if contains_any(content_text, PROMO_KEYWORDS):
        score -= 5
    if str(msg.get("content") or "").startswith("<?xml"):
        score -= 2
    if int(msg.get("type") or 0) in (3, 34, 43, 47) and not normalize(msg.get("content")):
        score -= 1
    return score


def local_hm(iso_ts: str) -> str:
    try:
        return datetime.fromisoformat(iso_ts).astimezone().strftime("%H:%M")
    except Exception:
        return "--:--"


def display_sender(msg: dict) -> str:
    if msg.get("isSelf"):
        return "我"
    return (msg.get("senderName") or msg.get("sender") or "unknown").strip()


def parse_send_output(raw: str) -> str:
    start = raw.find("{")
    while start != -1:
        try:
            obj = json.loads(raw[start:])
            payload = obj.get("payload") or {}
            result = payload.get("result") or {}
            parts = []
            message_id = result.get("messageId")
            via = payload.get("via")
            if message_id:
                parts.append(f"messageId={message_id}")
            if via:
                parts.append(f"via={via}")
            if obj.get("dryRun"):
                parts.append("dryRun=true")
            return " ".join(parts) if parts else "json=parsed"
        except json.JSONDecodeError:
            start = raw.find("{", start + 1)
    return "json=unparsed"


def send_feishu(openclaw_bin: str, target: str, message: str, dry_run: bool) -> Tuple[bool, str]:
    cmd = [openclaw_bin, "message", "send", "--json", "--channel", "feishu", "--target", target, "--message", message]
    if dry_run:
        cmd.insert(3, "--dry-run")
    env = os.environ.copy()
    env["PATH"] = f"/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:{env.get('PATH', '')}"
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    output = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode == 0:
        return True, parse_send_output(output)
    return False, output.strip()


def should_skip_chat(chat: dict) -> bool:
    chat_id = str(chat.get("id") or "")
    chat_name = str(chat.get("name") or "").strip()
    return (
        chat_id.startswith("@placeholder_")
        or chat_id in EXCLUDED_CHAT_IDS
        or chat_name in EXCLUDED_CHAT_NAMES
    )


def build_summary(
    chats: List[dict],
    total_messages: int,
    interested_messages: int,
    total_chats: int,
    omitted_chats: int,
    omitted_msgs: int,
    truncated: bool,
) -> str:
    title_time = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = [
        f"微信5分钟汇总 - {title_time}",
        "",
        f"总计 {total_messages} 条新消息，筛出 {interested_messages} 条你大概率会关心的，来自 {total_chats} 个会话。",
        "",
    ]
    for index, chat in enumerate(chats, start=1):
        lines.append(f"{index}. {chat['name']}（{chat['count']}条）")
        for msg in chat["messages"]:
            lines.append(f"- {local_hm(msg.get('timestamp', ''))} {display_sender(msg)}：{render_message(msg)}")
        if chat["hidden_count"] > 0:
            lines.append(f"- ...另有 {chat['hidden_count']} 条")
        lines.append("")
    if omitted_chats > 0:
        lines.append(f"- 其余 {omitted_chats} 个会话未展开。")
    if omitted_msgs > 0:
        lines.append(f"- 其余 {omitted_msgs} 条消息未展开。")
    if truncated:
        lines.append(f"- 高峰期仅保留最近 {MAX_TOTAL_MSGS} 条新消息的摘要。")
    return "\n".join(lines).strip() + "\n"


def load_state(path: Path) -> dict:
    if not path.exists():
        return {"version": 1, "initialized": False, "chat_last_ids": {}}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {"version": 1, "initialized": False, "chat_last_ids": {}}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize new WeChat messages and send to Feishu.")
    parser.add_argument("--base-url", default="http://localhost:6174")
    parser.add_argument("--token-file", default=str(Path.home() / ".config/agent-wechat/token"))
    parser.add_argument("--config-file", default="/Users/jyxc/.openclaw/workspace/config/channel-targets.env")
    parser.add_argument("--openclaw-bin", default="/opt/homebrew/bin/openclaw")
    parser.add_argument("--state-file", default="/Users/jyxc/.openclaw/workspace/memory/wechat-feishu-summary-state.json")
    parser.add_argument("--output-file", default="/Users/jyxc/.openclaw/workspace/workfiles/wechat-feishu-summary-latest.md")
    parser.add_argument("--log-file", default="/Users/jyxc/.openclaw/workspace/logs/wechat-feishu-summary.log")
    parser.add_argument("--chat-limit", type=int, default=150)
    parser.add_argument("--message-limit", type=int, default=200)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    token_file = Path(args.token_file).expanduser()
    config_file = Path(args.config_file).expanduser()
    state_file = Path(args.state_file).expanduser()
    output_file = Path(args.output_file).expanduser()
    log_file = Path(args.log_file).expanduser()
    env_cfg = read_env_file(config_file)
    feishu_target = env_cfg.get("FEISHU_TARGET", "").strip()
    if not feishu_target:
        log_line(log_file, "error: FEISHU_TARGET missing")
        return 1

    token = token_file.read_text(encoding="utf-8").strip()
    state = load_state(state_file)
    baseline_ids = dict(state.get("chat_last_ids") or {})

    try:
        chats = [chat for chat in fetch_chats(args.base_url, token, args.chat_limit) if not should_skip_chat(chat)]
    except (HTTPError, URLError, OSError) as exc:
        log_line(log_file, f"error: fetch chats failed: {exc}")
        return 1

    current_ids = {str(chat.get("id")): int(chat.get("lastMsgLocalId") or 0) for chat in chats}

    if not state.get("initialized"):
        save_state(
            state_file,
            {
                "version": 1,
                "initialized": True,
                "initializedAt": now_str(),
                "lastRunAt": now_str(),
                "chat_last_ids": current_ids,
            },
        )
        log_line(log_file, f"init: baseline established for {len(current_ids)} chats")
        return 0

    grouped: Dict[str, dict] = {}
    next_ids = dict(baseline_ids)
    truncated = False
    total_new = 0

    for chat in chats:
        chat_id = str(chat.get("id"))
        chat_name = str(chat.get("name") or chat_id)
        current_last = current_ids.get(chat_id, 0)
        previous_last = int(baseline_ids.get(chat_id, current_last))
        if chat_id not in baseline_ids:
            next_ids[chat_id] = current_last
            continue
        if current_last < previous_last:
            next_ids[chat_id] = current_last
            log_line(log_file, f"rebaseline: {chat_name} {previous_last}->{current_last}")
            continue
        if current_last == previous_last:
            next_ids[chat_id] = current_last
            continue

        try:
            messages = fetch_messages(args.base_url, token, chat_id, args.message_limit)
        except (HTTPError, URLError, OSError) as exc:
            log_line(log_file, f"warn: fetch messages failed for {chat_name}: {exc}")
            continue

        new_messages = [msg for msg in messages if int(msg.get("localId") or 0) > previous_last]
        new_messages.sort(key=lambda item: int(item.get("localId") or 0))
        if not new_messages:
            log_line(log_file, f"warn: {chat_name} lastMsgLocalId advanced but API returned no delta")
            continue

        total_new += len(new_messages)
        if len(new_messages) >= args.message_limit and int(new_messages[0].get("localId") or 0) > previous_last + 1:
            truncated = True
        interesting_messages = [msg for msg in new_messages if interest_score(chat, msg) >= INTEREST_THRESHOLD]
        if not interesting_messages:
            next_ids[chat_id] = current_last
            continue

        grouped[chat_id] = {
            "id": chat_id,
            "name": chat_name,
            "count": len(interesting_messages),
            "all_messages": interesting_messages,
            "latest_ts": interesting_messages[-1].get("timestamp", ""),
        }
        next_ids[chat_id] = current_last

    for chat_id, current_last in current_ids.items():
        next_ids.setdefault(chat_id, current_last)

    if not grouped:
        state.update({"lastRunAt": now_str(), "chat_last_ids": next_ids})
        save_state(state_file, state)
        log_line(log_file, f"done: no interesting messages (raw_new={total_new})")
        return 0

    ordered = sorted(grouped.values(), key=lambda item: (item["count"], item["latest_ts"]), reverse=True)
    selected = ordered[:MAX_CHATS]
    omitted_chats = max(0, len(ordered) - len(selected))
    rendered_count = 0
    omitted_msgs = 0
    summary_chats = []
    for chat in selected:
        remaining = MAX_TOTAL_MSGS - rendered_count
        if remaining <= 0:
            omitted_msgs += chat["count"]
            continue
        visible = min(len(chat["all_messages"]), MAX_MSGS_PER_CHAT, remaining)
        hidden = len(chat["all_messages"]) - visible
        if visible < len(chat["all_messages"]):
            truncated = True
        summary_chats.append(
            {
                "name": chat["name"],
                "count": chat["count"],
                "messages": chat["all_messages"][:visible],
                "hidden_count": hidden,
            }
        )
        rendered_count += visible
    omitted_msgs += max(0, total_new - sum(chat["count"] for chat in selected))

    interested_total = sum(chat["count"] for chat in ordered)
    message = build_summary(summary_chats, total_new, interested_total, len(ordered), omitted_chats, omitted_msgs, truncated)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(message, encoding="utf-8")

    ok, detail = send_feishu(args.openclaw_bin, feishu_target, message, args.dry_run)
    if not ok:
        log_line(log_file, f"error: send failed: {detail}")
        return 1

    state.update(
        {
            "version": 1,
            "initialized": True,
            "lastRunAt": now_str(),
            "lastSentAt": now_str(),
            "lastMessageFile": str(output_file),
            "chat_last_ids": next_ids,
        }
    )
    save_state(state_file, state)
    log_line(log_file, f"sent: chats={len(grouped)} raw_messages={total_new} interested_messages={interested_total} {detail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
