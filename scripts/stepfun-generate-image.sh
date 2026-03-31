#!/bin/zsh

set -euo pipefail

prompt=""
model="${STEPFUN_IMAGE_MODEL:-step-2x-large}"
size=""
output_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      prompt="${2:-}"
      shift 2
      ;;
    --model)
      model="${2:-}"
      shift 2
      ;;
    --size)
      size="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      echo "usage: stepfun-generate-image.sh --prompt \"...\" [--model step-2x-large] [--size 1024x1024] [--output /abs/path.png]"
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$prompt" ]]; then
  echo "--prompt is required" >&2
  exit 2
fi

api_key="$(launchctl getenv STEPFUN_API_KEY 2>/dev/null || true)"
if [[ -z "$api_key" ]]; then
  api_key="${STEPFUN_API_KEY:-}"
fi
if [[ -z "$api_key" ]]; then
  echo "STEPFUN_API_KEY is not available in the current runtime" >&2
  exit 1
fi

payload="$(
  jq -n \
    --arg model "$model" \
    --arg prompt "$prompt" \
    --arg size "$size" \
    '{
      model: $model,
      prompt: $prompt,
      response_format: "url",
      n: 1
    } + (if $size == "" then {} else {size: $size} end)'
)"

response_path="$(mktemp -t stepfun-image-response)"
trap 'rm -f "$response_path"' EXIT

curl -sS https://api.stepfun.com/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${api_key}" \
  -d "$payload" > "$response_path"

image_url="$(jq -r '.data[0].url // empty' "$response_path")"
if [[ -z "$image_url" ]]; then
  jq -r '.error.message // .error // "StepFun image generation failed"' "$response_path" >&2
  exit 1
fi

if [[ -n "$output_path" ]]; then
  curl -sSL "$image_url" -o "$output_path"
  echo "$output_path"
else
  echo "$image_url"
fi
