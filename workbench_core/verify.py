from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Callable

from workbench_core.core import BASE_DIR, exists, load_manifest


class VerifyError(RuntimeError):
    pass


def _check_file(rel_path: str) -> None:
    if not exists(rel_path):
        raise VerifyError(f'missing file: {BASE_DIR / rel_path}')


def _check_exec(rel_path: str) -> None:
    path = BASE_DIR / rel_path
    if not path.exists():
        raise VerifyError(f'missing file: {path}')
    if not path.is_file() or not (path.stat().st_mode & 0o111):
        raise VerifyError(f'not executable: {path}')


def _run(command: list[str]) -> None:
    result = subprocess.run(command, cwd=BASE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        raise VerifyError(result.stderr.strip() or f'command failed: {" ".join(command)}')


def _run_capture(command: list[str], *, env: dict[str, str] | None = None, cwd: Path = BASE_DIR) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
    if result.returncode != 0:
        stderr = result.stderr.strip()
        stdout = result.stdout.strip()
        detail = stderr or stdout or f'command failed: {" ".join(command)}'
        raise VerifyError(detail)
    return result


def _ensure(condition: bool, message: str) -> None:
    if not condition:
        raise VerifyError(message)


def _write_executable(path: Path, content: str) -> None:
    path.write_text(content)
    path.chmod(0o755)


def _check_channel_config() -> None:
    config_path = BASE_DIR / 'config/channel-targets.env'
    _check_file('config/channel-targets.env')
    config_text = config_path.read_text()
    required_keys = (
        'FEISHU_TARGET=',
        'WEIXIN_TARGET=',
        'WEIXIN_ACCOUNT_ID=',
        'STOCK_FINANCE_DAILY_CHANNELS=',
        'AI_TREND_DAILY_CHANNELS=',
        'LENNY_DAILY_CARD_CHANNELS=',
        'AI_TREND_WATCH_CHANNELS=',
    )
    for key in required_keys:
        _ensure(key in config_text, f'missing config key in {config_path}: {key[:-1]}')


def _verify_dual_channel_routing() -> None:
    script_path = BASE_DIR / 'scripts/send-dual-channel.sh'
    with tempfile.TemporaryDirectory(prefix='verify-dual-channel-') as tmp_dir:
        tmp = Path(tmp_dir)
        message_file = tmp / 'message.md'
        state_file = tmp / 'state.txt'
        log_file = tmp / 'send.log'
        calls_file = tmp / 'calls.log'
        openclaw_bin = tmp / 'fake-openclaw'
        message_file.write_text('hello\n')
        _write_executable(
            openclaw_bin,
            """#!/bin/bash
set -euo pipefail
printf '%s\\n' "$*" >> "$FAKE_CALLS"
channel=""
while [ $# -gt 0 ]; do
  case "$1" in
    --channel)
      channel="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf '{"dryRun":true,"payload":{"via":"stub","result":{"messageId":"stub-%s"}}}\\n' "$channel"
""",
        )

        base_env = os.environ.copy()
        base_env.update(
            {
                'OPENCLAW_BIN': str(openclaw_bin),
                'CONFIG_FILE': str(tmp / 'missing.env'),
                'DRY_RUN': '1',
                'FAKE_CALLS': str(calls_file),
            }
        )

        env = base_env | {'DELIVERY_CHANNELS': 'feishu'}
        _run_capture(
            [
                str(script_path),
                '--message-file',
                str(message_file),
                '--state-file',
                str(state_file),
                '--state-value',
                'verify-feishu',
                '--log-file',
                str(log_file),
                '--label',
                'verify-test',
            ],
            env=env,
        )
        feishu_calls = calls_file.read_text()
        feishu_log = log_file.read_text()
        _ensure('--channel feishu' in feishu_calls, 'feishu-only routing did not invoke feishu send')
        _ensure('--channel openclaw-weixin' not in feishu_calls, 'feishu-only routing unexpectedly invoked weixin send')
        _ensure('dry-run: verify-test feishu (verify-feishu)' in feishu_log, 'feishu-only dry-run log missing')
        _ensure('skip: verify-test openclaw-weixin disabled by DELIVERY_CHANNELS=feishu' in feishu_log, 'feishu-only skip log missing')

        calls_file.write_text('')
        weixin_log = tmp / 'send-weixin.log'
        env = base_env | {'DELIVERY_CHANNELS': 'openclaw-weixin', 'WEIXIN_ACCOUNT_ID': 'verify-account'}
        _run_capture(
            [
                str(script_path),
                '--message-file',
                str(message_file),
                '--state-file',
                str(tmp / 'state-weixin.txt'),
                '--state-value',
                'verify-weixin',
                '--log-file',
                str(weixin_log),
                '--label',
                'verify-test',
            ],
            env=env,
        )
        weixin_calls = calls_file.read_text()
        weixin_log_text = weixin_log.read_text()
        _ensure('--account verify-account' in weixin_calls, 'weixin-only routing did not pass account id')
        _ensure('--channel openclaw-weixin' in weixin_calls, 'weixin-only routing did not invoke weixin send')
        _ensure('--channel feishu' not in weixin_calls, 'weixin-only routing unexpectedly invoked feishu send')
        _ensure('skip: verify-test feishu disabled by DELIVERY_CHANNELS=openclaw-weixin' in weixin_log_text, 'weixin-only skip log missing')
        _ensure('dry-run: verify-test openclaw-weixin (verify-weixin)' in weixin_log_text, 'weixin-only dry-run log missing')


def _verify_lenny_generation_flow() -> None:
    script_path = BASE_DIR / 'scripts/generate-lenny-daily-cards.sh'
    with tempfile.TemporaryDirectory(prefix='verify-lenny-') as tmp_dir:
        tmp = Path(tmp_dir)
        task_file = tmp / 'task.md'
        state_file = tmp / 'state.json'
        card_file = tmp / 'cards.md'
        log_file = tmp / 'logs/cards.log'
        calls_file = tmp / 'calls.log'
        openclaw_bin = tmp / 'fake-openclaw'
        task_file.write_text('placeholder\n')
        _write_executable(
            openclaw_bin,
            """#!/bin/bash
set -euo pipefail
printf '%s\\n' "$*" >> "$FAKE_CALLS"
cat <<'JSON'
{"payloads":[],"summary":"<<<CARDS>>>\\n标题：Lenny AI 产品学习卡片 2026-04-11\\n\\n1. 标题一\\n- 观点：A\\n- 借鉴：B\\n- 来源：external-knowledge/x.md + 2026-01-01\\n\\n2. 标题二\\n- 观点：A\\n- 借鉴：B\\n- 来源：external-knowledge/y.md + 2026-01-02\\n\\n3. 标题三\\n- 观点：A\\n- 借鉴：B\\n- 来源：external-knowledge/z.md + 2026-01-03\\n\\n4. 标题四\\n- 观点：A\\n- 借鉴：B\\n- 来源：external-knowledge/u.md + 2026-01-04\\n\\n5. 标题五\\n- 观点：A\\n- 借鉴：B\\n- 来源：external-knowledge/v.md + 2026-01-05\\n<<<META>>>\\n{\\"used_sources\\":[\\"external-knowledge/x.md\\"],\\"card_titles\\":[\\"标题一\\",\\"标题二\\",\\"标题三\\",\\"标题四\\",\\"标题五\\"]}"}
JSON
""",
        )

        env = os.environ.copy()
        env.update(
            {
                'OPENCLAW_BIN': str(openclaw_bin),
                'TASK_FILE': str(task_file),
                'STATE_FILE': str(state_file),
                'CARD_FILE': str(card_file),
                'LOG_DIR': str(log_file.parent),
                'LOG_FILE': str(log_file),
                'TODAY': '2026-04-11',
                'GEN_SESSION_ID': 'verify-session',
                'FAKE_CALLS': str(calls_file),
            }
        )

        _run_capture([str(script_path)], env=env)
        calls_text = calls_file.read_text()
        card_text = card_file.read_text()
        state = json.loads(state_file.read_text())
        log_text = log_file.read_text()

        _ensure('agent --local --session-id verify-session --json --timeout 600 --message' in calls_text, 'lenny generation did not use local sessionized agent call')
        _ensure('标题：Lenny AI 产品学习卡片 2026-04-11' in card_text, 'lenny generation did not write expected card output')
        _ensure(state.get('last_run_date') == '2026-04-11', 'lenny generation did not update state date')
        history = state.get('history') or []
        _ensure(bool(history), 'lenny generation did not append history')
        _ensure(len((history[0] or {}).get('card_titles') or []) == 5, 'lenny generation did not persist 5 card titles')
        _ensure('start: session=verify-session' in log_text, 'lenny generation start log missing')
        _ensure('done' in log_text, 'lenny generation completion log missing')


def _verify_wechat_summary_flow() -> None:
    script_path = BASE_DIR / 'scripts/run-wechat-feishu-summary.py'

    with tempfile.TemporaryDirectory(prefix='verify-wechat-summary-') as tmp_dir:
        tmp = Path(tmp_dir)
        root_dir = tmp / 'mock-root'
        chats_file = root_dir / 'api/chats'
        messages_dir = root_dir / 'api/messages'
        token_file = tmp / 'token'
        config_file = tmp / 'channel-targets.env'
        state_file = tmp / 'state.json'
        output_file = tmp / 'summary.md'
        log_file = tmp / 'summary.log'
        calls_file = tmp / 'calls.log'
        openclaw_bin = tmp / 'fake-openclaw'

        messages_dir.mkdir(parents=True)
        token_file.write_text('verify-token\n')
        config_file.write_text('FEISHU_TARGET=verify-feishu-target\n')
        _write_executable(
            openclaw_bin,
            """#!/bin/bash
set -euo pipefail
printf '%s\\n' "$*" >> "$FAKE_CALLS"
printf '{"payload":{"via":"stub","result":{"messageId":"stub-feishu"}}}\\n'
""",
        )

        command = [
            'python3',
            str(script_path),
            '--base-url',
            root_dir.as_uri(),
            '--token-file',
            str(token_file),
            '--config-file',
            str(config_file),
            '--openclaw-bin',
            str(openclaw_bin),
            '--state-file',
            str(state_file),
            '--output-file',
            str(output_file),
            '--log-file',
            str(log_file),
        ]
        env = os.environ.copy()
        env.update({'FAKE_CALLS': str(calls_file)})

        chats_file.write_text(
            json.dumps(
                [
                    {
                        'id': 'chat-1',
                        'name': 'AI 产品群',
                        'lastMsgLocalId': 2,
                    }
                ],
                ensure_ascii=False,
                indent=2,
            )
        )
        (messages_dir / 'chat-1').write_text('[]\n')

        _run_capture(command, env=env)
        state = json.loads(state_file.read_text())
        log_text = log_file.read_text()
        _ensure(state.get('initialized') is True, 'wechat summary init did not mark state initialized')
        _ensure('lastSentAt' not in state, 'wechat summary init unexpectedly sent a message')
        _ensure(state.get('chat_last_ids', {}).get('chat-1') == 2, 'wechat summary init did not store baseline local id')
        _ensure('init: baseline established for 1 chats' in log_text, 'wechat summary init log missing')
        _ensure(not calls_file.exists(), 'wechat summary init unexpectedly called openclaw send')

        chats_file.write_text(
            json.dumps(
                [
                    {
                        'id': 'chat-1',
                        'name': 'AI 产品群',
                        'lastMsgLocalId': 4,
                    }
                ],
                ensure_ascii=False,
                indent=2,
            )
        )
        (messages_dir / 'chat-1').write_text(
            json.dumps(
                [
                    {
                        'localId': 1,
                        'timestamp': '2026-04-12T10:00:00+08:00',
                        'senderName': 'Alice',
                        'content': '旧消息',
                        'type': 1,
                    },
                    {
                        'localId': 2,
                        'timestamp': '2026-04-12T10:01:00+08:00',
                        'senderName': 'Bob',
                        'content': '旧消息2',
                        'type': 1,
                    },
                    {
                        'localId': 3,
                        'timestamp': '2026-04-12T10:02:00+08:00',
                        'senderName': 'Alice',
                        'content': 'OpenAI 发布新模型了',
                        'type': 1,
                    },
                    {
                        'localId': 4,
                        'timestamp': '2026-04-12T10:03:00+08:00',
                        'senderName': 'Bob',
                        'content': '收到',
                        'type': 1,
                    },
                ],
                ensure_ascii=False,
                indent=2,
            )
        )

        _run_capture(command, env=env)

        calls_text = calls_file.read_text()
        summary_text = output_file.read_text()
        state = json.loads(state_file.read_text())
        log_text = log_file.read_text()

        _ensure(
            'message send --json --channel feishu --target verify-feishu-target --message' in calls_text,
            'wechat summary did not invoke feishu send with expected target',
        )
        _ensure('微信5分钟汇总 - ' in summary_text, 'wechat summary did not write summary title')
        _ensure('总计 2 条新消息，筛出 1 条你大概率会关心的，来自 1 个会话。' in summary_text, 'wechat summary totals are incorrect')
        _ensure('1. AI 产品群（1条）' in summary_text, 'wechat summary chat section missing')
        _ensure('Alice：OpenAI 发布新模型了' in summary_text, 'wechat summary did not include interesting message')
        _ensure(state.get('chat_last_ids', {}).get('chat-1') == 4, 'wechat summary did not advance stored local id')
        _ensure(bool(state.get('lastSentAt')), 'wechat summary did not persist send timestamp')
        _ensure(str(output_file) == state.get('lastMessageFile'), 'wechat summary did not persist output file path')
        _ensure('sent: chats=1 raw_messages=2 interested_messages=1' in log_text, 'wechat summary send log missing')


def verify_docs() -> None:
    manifest = load_manifest()
    _check_file('README.md')
    _check_file('docs/assistant-workbench-manifest.md')
    _check_file('docs/assistant-workbench-manifest.json')
    for item in manifest.get('coreFiles', []):
        _check_file(item['path'])


def verify_dual_channel() -> None:
    _check_exec('scripts/send-dual-channel.sh')
    _run([str(BASE_DIR / 'scripts/send-dual-channel.sh'), '--help'])
    _check_channel_config()
    _verify_dual_channel_routing()


def verify_lenny() -> None:
    _check_exec('scripts/generate-lenny-daily-cards.sh')
    _check_exec('scripts/send-lenny-daily-cards.sh')
    _check_file('workfiles/lenny-daily-cards-task.md')
    _verify_lenny_generation_flow()


def verify_stock_finance() -> None:
    _check_exec('scripts/run-stock-finance-daily.sh')
    _check_file('workfiles/stock-finance-daily-task.md')


def verify_ai_trend() -> None:
    _check_exec('scripts/run-ai-trend-watch.sh')
    _check_file('workfiles/ai-trend-watch-task.md')


def verify_ai_trend_daily() -> None:
    _check_exec('scripts/run-ai-trend-daily.sh')
    _check_exec('scripts/send-dual-channel.sh')
    _check_file('workfiles/ai-trend-watch-task.md')


def verify_vision() -> None:
    _check_exec('scripts/check-openclaw-vision.sh')
    _run([str(BASE_DIR / 'scripts/check-openclaw-vision.sh'), '--help'])


def verify_summary() -> None:
    _check_exec('scripts/render-workbench-summary.py')
    _run(['python3', str(BASE_DIR / 'scripts/render-workbench-summary.py')])


def verify_wechat_summary() -> None:
    _check_exec('scripts/run-wechat-feishu-summary.py')
    _verify_wechat_summary_flow()


def verify(capability: str) -> None:
    handlers: dict[str, Callable[[], None]] = {
        'docs': verify_docs,
        'dual-channel': verify_dual_channel,
        'lenny': verify_lenny,
        'stock-finance': verify_stock_finance,
        'ai-trend': verify_ai_trend,
        'ai-trend-daily': verify_ai_trend_daily,
        'vision': verify_vision,
        'summary': verify_summary,
        'wechat-summary': verify_wechat_summary,
    }

    if capability == 'all':
        for name in ('docs', 'dual-channel', 'lenny', 'stock-finance', 'ai-trend', 'ai-trend-daily', 'vision', 'summary', 'wechat-summary'):
            handlers[name]()
        return

    if capability not in handlers:
        raise VerifyError(f'unknown capability: {capability}')

    handlers[capability]()
