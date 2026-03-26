#!/bin/bash
set -euo pipefail

BASE_DIR="/Users/jyxc/.openclaw/workspace"
HANDOFF_FILE="${HANDOFF_FILE:-$BASE_DIR/memory/channel-handoff.md}"
SOURCE_LABEL=""
STATUS_LABEL=""
CONTENT_FILE=""
NOTE_TEXT=""
PREVIEW_LINES="${PREVIEW_LINES:-16}"

usage() {
  cat <<'EOF'
Usage:
  update-channel-handoff.sh \
    --source ai-trend-watch \
    --status delivered \
    [--content-file /abs/path/result.md] \
    [--note "双发已完成"]
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      SOURCE_LABEL="${2:-}"
      shift 2
      ;;
    --status)
      STATUS_LABEL="${2:-}"
      shift 2
      ;;
    --content-file)
      CONTENT_FILE="${2:-}"
      shift 2
      ;;
    --note)
      NOTE_TEXT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$SOURCE_LABEL" ] || [ -z "$STATUS_LABEL" ]; then
  usage >&2
  exit 1
fi

mkdir -p "$(dirname "$HANDOFF_FILE")"

UPDATED_AT="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S %z')"
PREVIEW_TEXT=""

if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
  PREVIEW_TEXT="$(sed -n "1,${PREVIEW_LINES}p" "$CONTENT_FILE" | sed 's/[[:space:]]*$//')"
fi

cat > "$HANDOFF_FILE" <<EOF
# Cross-Channel Handoff

This file is the small shared summary for direct 1:1 chats across Feishu and Weixin.
Use it for recent durable context, not raw transcript replay.

## Current Handoff
- Updated at: $UPDATED_AT
- Source: $SOURCE_LABEL
- Status: $STATUS_LABEL
EOF

if [ -n "$CONTENT_FILE" ]; then
  cat >> "$HANDOFF_FILE" <<EOF
- Content file: $CONTENT_FILE
EOF
fi

if [ -n "$NOTE_TEXT" ]; then
  cat >> "$HANDOFF_FILE" <<EOF
- Note: $NOTE_TEXT
EOF
fi

cat >> "$HANDOFF_FILE" <<'EOF'

## Shared Rules
- Direct chats on Feishu and Weixin are separate sessions by design.
- Cross-channel continuity should come from this file plus `MEMORY.md`, not from a shared raw transcript.
- Automated mirrored delivery should use local scripts plus system `crontab`, not Gateway cron `announce`.
EOF

if [ -n "$PREVIEW_TEXT" ]; then
  cat >> "$HANDOFF_FILE" <<EOF

## Preview
\`\`\`markdown
$PREVIEW_TEXT
\`\`\`
EOF
fi
