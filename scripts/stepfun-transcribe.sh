#!/bin/zsh

set -euo pipefail

audio_path="${1:-}"
if [[ -z "$audio_path" ]]; then
  echo "usage: stepfun-transcribe.sh /abs/path/audio" >&2
  exit 2
fi

if [[ ! -f "$audio_path" ]]; then
  echo "audio file not found: $audio_path" >&2
  exit 1
fi

api_key="${STEPFUN_API_KEY:-}"
if [[ -z "$api_key" ]]; then
  api_key="$(launchctl getenv STEPFUN_API_KEY 2>/dev/null || true)"
fi
if [[ -z "$api_key" ]]; then
  echo "STEPFUN_API_KEY is not available in the current runtime" >&2
  exit 1
fi

model="${STEPFUN_ASR_MODEL:-step-asr-1.1}"
fallback_model="step-asr"
upload_path="$audio_path"
converted_path=""
response_path="$(mktemp /tmp/stepfun-asr-response.XXXXXX.json)"

cleanup() {
  rm -f "$response_path"
  if [[ -n "$converted_path" ]]; then
    rm -f "$converted_path"
  fi
}
trap cleanup EXIT

ext="${audio_path##*.}"
ext="${ext:l}"
case "$ext" in
  flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm|aac|opus)
    ;;
  *)
    if command -v afconvert >/dev/null 2>&1; then
      converted_path="$(mktemp /tmp/stepfun-asr-audio.XXXXXX.wav)"
      afconvert -f WAVE -d LEI16 "$audio_path" "$converted_path" >/dev/null 2>&1
      upload_path="$converted_path"
    else
      echo "unsupported audio format and afconvert is unavailable: $audio_path" >&2
      exit 1
    fi
    ;;
esac

transcribe() {
  local current_model="$1"
  curl -sS https://api.stepfun.com/v1/audio/transcriptions \
    -H "Authorization: Bearer ${api_key}" \
    -F "model=${current_model}" \
    -F "file=@${upload_path}" > "$response_path"

  if jq -e '.text and (.text | type == "string")' "$response_path" >/dev/null 2>&1; then
    jq -r '.text' "$response_path"
    return 0
  fi

  return 1
}

if transcribe "$model"; then
  exit 0
fi

if [[ "$model" != "$fallback_model" ]] && transcribe "$fallback_model"; then
  exit 0
fi

jq -r '.error.message // .error // "StepFun transcription failed"' "$response_path" >&2
exit 1
