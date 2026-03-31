#!/bin/zsh

set -euo pipefail

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=1
elif [[ $# -gt 0 ]]; then
  echo "usage: openclaw-session-guard.sh [--dry-run]" >&2
  exit 2
fi

home_dir="${HOME:-/Users/jyxc}"
store_path="$home_dir/.openclaw/agents/main/sessions/sessions.json"
err_log_path="$home_dir/.openclaw/logs/gateway.err.log"
state_dir="$home_dir/.openclaw/state/session-guard"
backup_root="$home_dir/.openclaw/agents/main/sessions/guard-backups"
action_log="$state_dir/actions.log"

mkdir -p "$state_dir" "$backup_root"

if [[ ! -f "$store_path" || ! -f "$err_log_path" ]]; then
  exit 0
fi

session_ids=("${(@f)$(tail -n 2000 "$err_log_path" | sed -n 's/.*timed out during compaction .*sessionId=\([[:alnum:]-]\+\).*/\1/p' | awk '!seen[$0]++')}")

if [[ ${#session_ids[@]} -eq 0 ]]; then
  exit 0
fi

now_ms() {
  /usr/bin/python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
}

for session_id in "${session_ids[@]}"; do
  [[ -n "$session_id" ]] || continue

  marker_path="$state_dir/handled-$session_id"
  if [[ -f "$marker_path" ]]; then
    continue
  fi

  session_key="$(jq -r --arg sid "$session_id" 'to_entries[] | select(.value.sessionId == $sid) | .key' "$store_path" | head -n 1)"
  if [[ -z "$session_key" ]]; then
    touch "$marker_path"
    continue
  fi

  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$backup_root/$timestamp-$session_id"
  session_file="$(jq -r --arg key "$session_key" '.[$key].sessionFile // empty' "$store_path")"
  entry_snapshot="$(jq -c --arg key "$session_key" '.[$key]' "$store_path")"
  next_session_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"

  if [[ -n "$session_file" ]]; then
    next_session_file="$(dirname "$session_file")/$next_session_id.jsonl"
  else
    next_session_file="$(dirname "$store_path")/$next_session_id.jsonl"
  fi

  if (( dry_run )); then
    echo "would reset $session_key $session_id -> $next_session_id"
    continue
  fi

  mkdir -p "$backup_dir"
  cp "$store_path" "$backup_dir/sessions.json"
  if [[ -n "$session_file" && -f "$session_file" ]]; then
    cp "$session_file" "$backup_dir/"
  fi
  printf '%s\n' "$entry_snapshot" > "$backup_dir/entry.json"

  tmp_store="$(mktemp)"
  jq \
    --arg key "$session_key" \
    --arg next_session_id "$next_session_id" \
    --arg next_session_file "$next_session_file" \
    --argjson updated_at "$(now_ms)" \
    '
      .[$key].sessionId = $next_session_id |
      .[$key].updatedAt = $updated_at |
      .[$key].systemSent = false |
      .[$key].abortedLastRun = false |
      .[$key].sessionFile = $next_session_file |
      del(
        .[$key].modelProvider,
        .[$key].model,
        .[$key].contextTokens,
        .[$key].systemPromptReport,
        .[$key].fallbackNoticeSelectedModel,
        .[$key].fallbackNoticeActiveModel,
        .[$key].fallbackNoticeReason,
        .[$key].inputTokens,
        .[$key].outputTokens,
        .[$key].totalTokens,
        .[$key].totalTokensFresh,
        .[$key].compactionCount,
        .[$key].memoryFlushCompactionCount
      )
    ' \
    "$store_path" > "$tmp_store"
  mv "$tmp_store" "$store_path"

  touch "$marker_path"
  printf '%s reset %s %s -> %s\n' "$(date -Is)" "$session_key" "$session_id" "$next_session_id" >> "$action_log"
  echo "reset $session_key $session_id -> $next_session_id"
done
