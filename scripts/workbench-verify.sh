#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
CAPABILITY="${1:-all}"

usage() {
  cat <<'EOF'
Usage:
  workbench-verify.sh [all|docs|dual-channel|lenny|stock-finance|ai-trend|ai-trend-daily|vision|summary]

Non-destructive checks for the current assistant workbench.
EOF
}

case "$CAPABILITY" in
  all|docs|dual-channel|lenny|stock-finance|ai-trend|ai-trend-daily|vision|summary)
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

PYTHONPATH="$BASE_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - "$CAPABILITY" <<'PY'
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
