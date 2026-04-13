#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"

if [ "$#" -eq 0 ]; then
  set -- all
fi

usage() {
  cat <<'EOF'
Usage:
  workbench-verify.sh [all|docs|dual-channel|lenny|stock-finance|ai-trend|ai-trend-daily|vision|summary|wechat-summary]...

Non-destructive checks for the current assistant workbench.
EOF
}

for capability in "$@"; do
  case "$capability" in
    all|docs|dual-channel|lenny|stock-finance|ai-trend|ai-trend-daily|vision|summary|wechat-summary)
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

for capability in "$@"; do
PYTHONPATH="$BASE_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - "$capability" <<'PY'
import sys
from workbench_core.verify import VerifyError, verify

capability = sys.argv[1]
try:
    verify(capability)
except VerifyError as exc:
    print(str(exc), file=sys.stderr)
    raise SystemExit(1)

print(f'verify ok: {capability}')
PY
done
