#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="${1:-}"
TITLE="${2:-assistant-learning-note}"
WHAT_CHANGED="${3:-}"
WHAT_LEARNED="${4:-}"
NEXT_STEP="${5:-}"

usage() {
  cat <<'EOF'
Usage:
  capture-learning-note.sh <output-file> [title] [what-changed] [what-learned] [next-step]
EOF
}

if [ -z "$OUTPUT_FILE" ]; then
  usage >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"
STAMP="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$OUTPUT_FILE" <<EOF
# $TITLE

- Updated at: $STAMP
- What changed: ${WHAT_CHANGED:-TBD}
- What learned: ${WHAT_LEARNED:-TBD}
- Next step: ${NEXT_STEP:-TBD}
EOF

echo "$OUTPUT_FILE"
