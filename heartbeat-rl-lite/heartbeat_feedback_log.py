import json
from pathlib import Path

LOG_PATH = Path('/root/.openclaw/workspace/heartbeat-rl-lite/logs/heartbeat_rl_shadow.jsonl')
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)


def append_log(record: dict) -> None:
    with LOG_PATH.open('a', encoding='utf-8') as f:
        f.write(json.dumps(record, ensure_ascii=False) + '\n')
