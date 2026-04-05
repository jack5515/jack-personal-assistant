#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="${BASE_DIR}/scripts/pexels-search.py"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "pexels search script not found: $SCRIPT_PATH" >&2
  exit 1
fi

exec "$PYTHON_BIN" "$SCRIPT_PATH" "$@"
