from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Any

BASE_DIR = Path('/Users/jyxc/.openclaw/workspace')
MANIFEST_PATH = BASE_DIR / 'docs' / 'assistant-workbench-manifest.json'


def load_manifest() -> dict[str, Any]:
    return json.loads(MANIFEST_PATH.read_text())


def workbench_name(manifest: dict[str, Any]) -> str:
    workbench = manifest.get('workbench', {})
    if isinstance(workbench, dict):
        return str(workbench.get('name', 'unknown-workbench'))
    return str(workbench)


def resolve(rel_path: str) -> Path:
    return BASE_DIR / rel_path


def exists(rel_path: str) -> bool:
    return resolve(rel_path).exists()


def latest_log_line(rel_path: str) -> str | None:
    path = resolve(rel_path)
    if not path.exists():
        return None
    try:
        lines = path.read_text(errors='replace').splitlines()
    except Exception as exc:
        return f'(unreadable: {exc})'
    return lines[-1] if lines else '(empty)'


def runtime_patterns(manifest: dict[str, Any]) -> list[str]:
    patterns = [
        r'^logs/',
        r'^generated/',
        r'^tmp/',
        r'^media/',
    ]
    for rel in manifest.get('layers', {}).get('state', []):
        patterns.append('^' + re.escape(rel).replace(r'\*', '.*') + '$')
    for rel in manifest.get('layers', {}).get('delivery', []):
        patterns.append('^' + re.escape(rel).replace(r'\*', '.*') + '$')
    patterns.extend([
        r'^workfiles/dual-send-test-.*',
        r'^workfiles/ai-trend-watch-manual-.*',
    ])
    return patterns


def runtime_residue_matches(manifest: dict[str, Any]) -> list[str]:
    status = subprocess.check_output(['git', 'status', '--short'], cwd=BASE_DIR, text=True)
    patterns = runtime_patterns(manifest)
    matched: list[str] = []
    for line in status.splitlines():
        path = line[3:] if len(line) > 3 else ''
        if any(re.match(pattern, path) for pattern in patterns):
            matched.append(line)
    return matched


def status_payload(manifest: dict[str, Any], generated_at: str) -> dict[str, Any]:
    recent_logs = {}
    for cap in manifest.get('capabilities', []):
        logs = cap.get('logs', [])
        if logs:
            recent_logs[cap['name']] = {log: latest_log_line(log) for log in logs}

    return {
        'generatedAt': generated_at,
        'workbench': manifest.get('workbench'),
        'coreFiles': {item['name']: exists(item['path']) for item in manifest.get('coreFiles', [])},
        'layers': {name: len(items) for name, items in manifest.get('layers', {}).items()},
        'capabilities': {
            cap['name']: {
                'status': cap.get('status'),
                'entry': cap.get('entry'),
                'entryPresent': exists(cap['entry']),
                'verify': cap.get('verify'),
            }
            for cap in manifest.get('capabilities', [])
        },
        'recentLogs': recent_logs,
    }


def render_summary(manifest: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append(f'Workbench: {workbench_name(manifest)}')
    lines.append(f'Manifest: {MANIFEST_PATH}')
    lines.append('')
    lines.append('Layers:')
    for layer_name in ('execution', 'state', 'knowledge', 'delivery'):
        items = manifest.get('layers', {}).get(layer_name, [])
        lines.append(f'- {layer_name}: {len(items)} item(s)')
    lines.append('')
    lines.append('Core files:')
    for item in manifest.get('coreFiles', []):
        rel_path = item['path']
        state = 'present' if exists(rel_path) else 'missing'
        lines.append(f"- {item['name']}: {state} ({rel_path})")
    lines.append('')
    lines.append('Capabilities:')
    for cap in manifest.get('capabilities', []):
        entry_rel = cap['entry']
        state = 'present' if exists(entry_rel) else 'missing'
        lines.append(f"- {cap['name']} [{cap['status']}] {state} ({entry_rel})")
        lines.append(f"  verify: {cap.get('verify', '(none)')}")
        for log_rel in cap.get('logs', []):
            lines.append(f"  latest log: {log_rel}: {latest_log_line(log_rel) or '(missing)'}")
    return '\n'.join(lines)
