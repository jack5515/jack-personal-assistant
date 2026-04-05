#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_SKILL_ROOT="${BASE_DIR}/skills/md2pptx"
CODEX_SKILL_ROOT="${HOME}/.codex/skills/md2pptx"
if [[ -d "$LOCAL_SKILL_ROOT" ]]; then
  SKILL_ROOT="$LOCAL_SKILL_ROOT"
else
  SKILL_ROOT="$CODEX_SKILL_ROOT"
fi
PREPARE_SCRIPT="${SKILL_ROOT}/scripts/md2pptx.py"
TOOL_DIR="${BASE_DIR}/tools/md2pptx"
NODE_BIN="${NODE_BIN:-node}"
NPM_BIN="${NPM_BIN:-npm}"
MARP_BIN="${TOOL_DIR}/node_modules/.bin/marp"
DEFAULT_THEME="studio-dark"
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

usage() {
  cat <<'EOF'
Usage:
  md2pptx --input /abs/path/deck.md --output /abs/path/deck.pptx [extra args]
  md2pptx /abs/path/deck.md
  md2pptx /abs/path/deck.md /abs/path/deck.pptx --theme editorial-warm

Options passed through:
  --theme studio-dark|editorial-warm
  --title "Deck Title"
  --subtitle "Optional Subtitle"
  --author "Author Name"
  --split-by auto|manual|h1|h2
  --no-animate-bullets
  --non-editable
  --keep-workdir /abs/path/workdir
EOF
}

ensure_marp() {
  if [[ -x "$MARP_BIN" ]]; then
    return
  fi

  mkdir -p "$TOOL_DIR"
  if [[ ! -f "${TOOL_DIR}/package.json" ]]; then
    cat > "${TOOL_DIR}/package.json" <<'EOF'
{
  "name": "md2pptx-local-tooling",
  "private": true
}
EOF
  fi

  "$NPM_BIN" install --prefix "$TOOL_DIR" --no-fund --no-audit @marp-team/marp-cli
}

ensure_libreoffice() {
  if command -v soffice >/dev/null 2>&1; then
    return
  fi
  if [[ -x "/Applications/LibreOffice.app/Contents/MacOS/soffice" ]]; then
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    brew install --cask libreoffice
    return
  fi
  echo "LibreOffice is required for editable PPTX export." >&2
  exit 1
}

resolve_chrome() {
  if [[ -x "$CHROME_PATH" ]]; then
    printf '%s\n' "$CHROME_PATH"
    return
  fi
  if command -v google-chrome >/dev/null 2>&1; then
    command -v google-chrome
    return
  fi
  echo "Google Chrome not found. Install Chrome before running md2pptx." >&2
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

if [[ "${1}" == "--help" || "${1}" == "-h" ]]; then
  usage
  exit 0
fi

input_path=""
output_path=""
theme="$DEFAULT_THEME"
title=""
subtitle=""
author=""
split_by="auto"
animate_bullets=1
editable=1
keep_workdir=""

if [[ "${1}" != -* ]]; then
  input_path="$1"
  shift
  if [[ $# -gt 0 && "${1}" != -* ]]; then
    output_path="$1"
    shift
  fi
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      input_path="$2"
      shift 2
      ;;
    --output)
      output_path="$2"
      shift 2
      ;;
    --theme)
      theme="$2"
      shift 2
      ;;
    --title)
      title="$2"
      shift 2
      ;;
    --subtitle)
      subtitle="$2"
      shift 2
      ;;
    --author)
      author="$2"
      shift 2
      ;;
    --split-by)
      split_by="$2"
      shift 2
      ;;
    --no-animate-bullets)
      animate_bullets=0
      shift
      ;;
    --non-editable)
      editable=0
      shift
      ;;
    --keep-workdir)
      keep_workdir="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$input_path" ]]; then
  echo "Input markdown path is required." >&2
  exit 1
fi

if [[ -z "$output_path" ]]; then
  base_name="$(basename "$input_path")"
  stem="${base_name%.*}"
  input_dir="$(cd "$(dirname "$input_path")" && pwd)"
  output_path="${input_dir}/${stem}.pptx"
fi

if [[ ! -f "$PREPARE_SCRIPT" ]]; then
  echo "md2pptx prepare script not found: $PREPARE_SCRIPT" >&2
  exit 1
fi

ensure_marp
chrome_bin="$(resolve_chrome)"

if [[ "$editable" -eq 1 ]]; then
  ensure_libreoffice
fi

if [[ -n "$keep_workdir" ]]; then
  workdir="$keep_workdir"
  mkdir -p "$workdir"
else
  workdir="$(mktemp -d /tmp/md2pptx.XXXXXX)"
  trap 'rm -rf "$workdir"' EXIT
fi

prepared_md="${workdir}/prepared.md"
theme_file="${SKILL_ROOT}/assets/themes/${theme}.css"

if [[ ! -f "$theme_file" ]]; then
  echo "Theme file not found: $theme_file" >&2
  exit 1
fi

prepare_args=(
  --input "$input_path"
  --output-md "$prepared_md"
  --theme "$theme"
  --split-by "$split_by"
)

if [[ -n "$title" ]]; then
  prepare_args+=(--title "$title")
fi
if [[ -n "$subtitle" ]]; then
  prepare_args+=(--subtitle "$subtitle")
fi
if [[ -n "$author" ]]; then
  prepare_args+=(--author "$author")
fi
if [[ "$animate_bullets" -eq 0 ]]; then
  prepare_args+=(--no-animate-bullets)
fi

"$PYTHON_BIN" "$PREPARE_SCRIPT" "${prepare_args[@]}"
mkdir -p "$(dirname "$output_path")"

marp_args=(
  "$prepared_md"
  --allow-local-files
  --theme-set "$theme_file"
  --output "$output_path"
  --pptx
  --browser-path "$chrome_bin"
)

if [[ "$editable" -eq 1 ]]; then
  marp_args+=(--pptx-editable)
fi

exec "$MARP_BIN" "${marp_args[@]}"
