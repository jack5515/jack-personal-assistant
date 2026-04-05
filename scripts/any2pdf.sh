#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_SKILL_ROOT="${BASE_DIR}/skills/any2pdf"
CODEX_SKILL_ROOT="${HOME}/.codex/skills/any2pdf"

if [[ -f "${LOCAL_SKILL_ROOT}/scripts/md2pdf.py" ]]; then
  SCRIPT_PATH="${LOCAL_SKILL_ROOT}/scripts/md2pdf.py"
else
  SCRIPT_PATH="${CODEX_SKILL_ROOT}/scripts/md2pdf.py"
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "any2pdf renderer not found: $SCRIPT_PATH" >&2
  exit 1
fi

ensure_reportlab() {
  if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import reportlab
PY
  then
    "$PYTHON_BIN" -m pip install --user reportlab
  fi
}

usage() {
  cat <<'EOF'
Usage:
  any2pdf --input /abs/path/report.md --output /abs/path/report.pdf [extra args]
  any2pdf /abs/path/report.md
  any2pdf /abs/path/report.md /abs/path/report.pdf --theme warm-academic
EOF
}

ensure_reportlab

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

if [[ "${1}" == "--help" || "${1}" == "-h" ]]; then
  exec "$PYTHON_BIN" "$SCRIPT_PATH" --help
fi

if [[ "${1}" != -* ]]; then
  input_path="$1"
  shift
  output_path=""

  if [[ $# -gt 0 && "${1}" != -* ]]; then
    output_path="$1"
    shift
  else
    base_name="$(basename "$input_path")"
    stem="${base_name%.*}"
    input_dir="$(cd "$(dirname "$input_path")" && pwd)"
    output_path="${input_dir}/${stem}.pdf"
  fi

  mkdir -p "$(dirname "$output_path")"
  exec "$PYTHON_BIN" "$SCRIPT_PATH" --input "$input_path" --output "$output_path" "$@"
fi

exec "$PYTHON_BIN" "$SCRIPT_PATH" "$@"
