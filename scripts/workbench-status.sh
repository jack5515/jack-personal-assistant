#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
NOW="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S %z')"
MODE="${1:-text}"

if [ "$MODE" = "--json" ]; then
  PYTHONPATH="$BASE_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - "$NOW" <<'PY'
import json
import sys
from workbench_core.core import load_manifest, status_payload

print(json.dumps(status_payload(load_manifest(), sys.argv[1]), ensure_ascii=False, indent=2))
PY
  exit 0
fi

PYTHONPATH="$BASE_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 "$BASE_DIR/scripts/render-workbench-summary.py"
