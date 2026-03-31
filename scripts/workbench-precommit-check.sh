#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
cd "$BASE_DIR"

echo "[precommit] scanning staged/unstaged changes for runtime residue"

BAD_MATCHES="$(PYTHONPATH="$BASE_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - <<'PY'
from workbench_core.core import load_manifest, runtime_residue_matches

print('\n'.join(runtime_residue_matches(load_manifest())))
PY
)"

if [ -n "$BAD_MATCHES" ]; then
  echo "Found runtime/local-only files in git status:"
  printf '%s\n' "$BAD_MATCHES"
  exit 2
fi

echo "precommit check ok"
