from __future__ import annotations

import subprocess
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


def verify_lenny() -> None:
    _check_exec('scripts/generate-lenny-daily-cards.sh')
    _check_exec('scripts/send-lenny-daily-cards.sh')
    _check_file('workfiles/lenny-daily-cards-task.md')


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
    }

    if capability == 'all':
        for name in ('docs', 'dual-channel', 'lenny', 'stock-finance', 'ai-trend', 'ai-trend-daily', 'vision', 'summary'):
            handlers[name]()
        return

    if capability not in handlers:
        raise VerifyError(f'unknown capability: {capability}')

    handlers[capability]()
