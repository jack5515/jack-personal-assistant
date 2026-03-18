import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path('/root/.openclaw/workspace')
STATE_DIR = ROOT / 'heartbeat-rl-lite' / 'state'
LAST_UPDATE_FILE = STATE_DIR / 'last_update.json'


def _run(cmd: str) -> str:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return (result.stdout or '').strip()


def _count_lines(cmd: str) -> int:
    out = _run(cmd)
    return len([line for line in out.splitlines() if line.strip()])


def _minutes_since_last_update(now: datetime) -> int:
    if not LAST_UPDATE_FILE.exists():
        return 999
    try:
        data = json.loads(LAST_UPDATE_FILE.read_text())
        ts = datetime.fromisoformat(data['ts'])
        return max(0, int((now - ts).total_seconds() // 60))
    except Exception:
        return 999


def _has_new_user_message(now: datetime) -> bool:
    # Approximate with a recent direct-session activity signal.
    out = _run("openclaw status | sed -n '/Sessions/,$p'")
    return 'agent:main:main' in out and ('just now' in out or '1m ago' in out or '2m ago' in out)


def _stalled_task() -> bool:
    # If tmux/Codex exists but no new shadow log for a while, treat as possible stall.
    ps_out = _run("ps -ef | grep -Ei 'codex|tmux' | grep -v grep")
    has_task = any(line.strip() for line in ps_out.splitlines())
    shadow_log = ROOT / 'heartbeat-rl-lite' / 'logs' / 'heartbeat_rl_shadow.jsonl'
    if not has_task or not shadow_log.exists():
        return False
    age_minutes = int((datetime.now().timestamp() - shadow_log.stat().st_mtime) // 60)
    return age_minutes >= 20


def _severity(findings: list[str]) -> str:
    high_markers = {'gateway_down', 'cron_log_error', 'stalled_task'}
    medium_markers = {'missing_heartbeat_file', 'no_cron_tasks', 'recent_failures'}
    if any(item in high_markers for item in findings):
        return 'high'
    if any(item in medium_markers for item in findings):
        return 'medium'
    return 'low'


def build_state() -> dict:
    now = datetime.now().astimezone()
    ps_out = _run("ps -ef | grep -Ei 'codex|tmux' | grep -v grep")
    running_task_count = len([line for line in ps_out.splitlines() if line.strip()])

    heartbeat_path = ROOT / 'HEARTBEAT.md'
    memory_path = ROOT / 'MEMORY.md'
    findings: list[str] = []

    cron_task_count = _count_lines('crontab -l 2>/dev/null')
    if cron_task_count == 0:
        findings.append('no_cron_tasks')
    if not heartbeat_path.exists():
        findings.append('missing_heartbeat_file')

    daily_news_log = ROOT / 'daily-news' / 'cron.log'
    daily_reports_log = ROOT / 'daily-reports' / 'cron.log'
    if daily_news_log.exists() and 'error' in daily_news_log.read_text(errors='ignore').lower()[-2000:]:
        findings.append('cron_log_error')
    if daily_reports_log.exists() and 'error' in daily_reports_log.read_text(errors='ignore').lower()[-2000:]:
        findings.append('cron_log_error')

    stalled = _stalled_task()
    if stalled:
        findings.append('stalled_task')

    state = {
        'ts': now.isoformat(),
        'hour': now.hour,
        'weekday': now.weekday(),
        'has_heartbeat_file': heartbeat_path.exists(),
        'has_memory_file': memory_path.exists(),
        'running_task_count': running_task_count,
        'has_running_task': running_task_count > 0,
        'heartbeat_check_items': _count_lines("grep -E '^- \\[ \\]' /root/.openclaw/workspace/HEARTBEAT.md 2>/dev/null"),
        'cron_task_count': cron_task_count,
        'has_new_user_message': _has_new_user_message(now),
        'minutes_since_last_update': _minutes_since_last_update(now),
        'severity': _severity(findings),
        'stalled_task': stalled,
        'findings': findings
    }

    return state


if __name__ == '__main__':
    print(json.dumps(build_state(), ensure_ascii=False, indent=2))
