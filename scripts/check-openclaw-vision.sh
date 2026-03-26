#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
MODELS_PATH="${OPENCLAW_AGENT_MODELS_PATH:-$HOME/.openclaw/agents/main/agent/models.json}"
DEFAULT_PROMPT="Describe the image in one short sentence."

IMAGE_ARG=""
PROMPT_ARG="$DEFAULT_PROMPT"
MODEL_ARG=""
VERBOSE=0

usage() {
  cat <<'EOF'
Usage: check-openclaw-vision.sh --image <path-or-url> [options]

Verify the OpenClaw image-reading model path with a real request.

Options:
  --image <path-or-url>   Local image path, http(s) URL, or data:image URL.
  --prompt <text>         Prompt to send with the image.
  --model <provider/model>
                          Override the configured model for this check.
  --verbose               Print resolved request details.
  -h, --help              Show this help.
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE_ARG="${2:-}"
      shift 2
      ;;
    --prompt)
      PROMPT_ARG="${2:-}"
      shift 2
      ;;
    --model)
      MODEL_ARG="${2:-}"
      shift 2
      ;;
    --verbose)
      VERBOSE=1
      shift
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

need_cmd jq
need_cmd curl

[[ -n "$IMAGE_ARG" ]] || {
  echo "--image is required" >&2
  usage >&2
  exit 1
}

[[ -f "$CONFIG_PATH" ]] || {
  echo "Config file not found: $CONFIG_PATH" >&2
  exit 1
}

[[ -f "$MODELS_PATH" ]] || {
  echo "Agent models file not found: $MODELS_PATH" >&2
  exit 1
}

resolve_model_ref() {
  if [[ -n "$MODEL_ARG" ]]; then
    printf '%s\n' "$MODEL_ARG"
    return
  fi

  local configured
  configured="$(jq -r '
    .tools.media.image.models[0]? as $imageModel
    | if $imageModel then
        ($imageModel.provider + "/" + $imageModel.model)
      else
        (.agents.defaults.model.primary // empty)
      end
  ' "$CONFIG_PATH")"

  [[ -n "$configured" && "$configured" != "null" ]] || {
    echo "No configured image-capable model found in $CONFIG_PATH" >&2
    exit 1
  }

  printf '%s\n' "$configured"
}

MODEL_REF="$(resolve_model_ref)"
PROVIDER="${MODEL_REF%%/*}"
MODEL="${MODEL_REF#*/}"

if [[ "$PROVIDER" == "$MODEL_REF" || -z "$PROVIDER" || -z "$MODEL" ]]; then
  echo "Model reference must look like provider/model, got: $MODEL_REF" >&2
  exit 1
fi

API_KIND="$(jq -r --arg provider "$PROVIDER" '.providers[$provider].api // empty' "$MODELS_PATH")"
BASE_URL="$(jq -r --arg provider "$PROVIDER" '.providers[$provider].baseUrl // empty' "$MODELS_PATH")"
API_KEY_ENV="$(jq -r --arg provider "$PROVIDER" '
  .providers[$provider].apiKey as $key
  | if ($key | type) == "string" then $key else empty end
' "$MODELS_PATH")"

if [[ -z "$BASE_URL" || -z "$API_KIND" ]]; then
  echo "Could not resolve provider $PROVIDER from $MODELS_PATH" >&2
  exit 1
fi

if [[ -z "$API_KEY_ENV" ]]; then
  API_KEY_ENV="$(jq -r --arg provider "$PROVIDER" '
    .models.providers[$provider].apiKey.id // empty
  ' "$CONFIG_PATH")"
fi

[[ -n "$API_KEY_ENV" ]] || {
  echo "Could not resolve API key env var for provider $PROVIDER" >&2
  exit 1
}

API_KEY_VALUE="${!API_KEY_ENV:-}"
[[ -n "$API_KEY_VALUE" ]] || {
  echo "Environment variable $API_KEY_ENV is not set" >&2
  exit 1
}

MODEL_INPUTS="$(jq -cr --arg provider "$PROVIDER" --arg model "$MODEL" '
  .providers[$provider].models[]? | select(.id == $model) | (.input // [])
' "$MODELS_PATH")"

if [[ -z "$MODEL_INPUTS" ]]; then
  MODEL_INPUTS="[]"
fi

build_image_url() {
  if [[ "$IMAGE_ARG" == http://* || "$IMAGE_ARG" == https://* || "$IMAGE_ARG" == data:image/* ]]; then
    printf '%s\n' "$IMAGE_ARG"
    return
  fi

  need_cmd file
  need_cmd base64

  [[ -f "$IMAGE_ARG" ]] || {
    echo "Image file not found: $IMAGE_ARG" >&2
    exit 1
  }

  local mime
  mime="$(file --brief --mime-type -- "$IMAGE_ARG")"
  [[ "$mime" == image/* ]] || {
    echo "Not an image file: $IMAGE_ARG ($mime)" >&2
    exit 1
  }

  local data
  data="$(base64 < "$IMAGE_ARG" | tr -d '\n')"
  printf 'data:%s;base64,%s\n' "$mime" "$data"
}

IMAGE_URL="$(build_image_url)"
REQUEST_BODY="$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$PROMPT_ARG" \
  --arg imageUrl "$IMAGE_URL" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: $prompt },
          { type: "image_url", image_url: { url: $imageUrl } }
        ]
      }
    ],
    max_tokens: 200,
    stream: true
  }')"

if [[ "$VERBOSE" -eq 1 ]]; then
  echo "Config: $CONFIG_PATH"
  echo "Models: $MODELS_PATH"
  echo "Provider: $PROVIDER"
  echo "Model: $MODEL"
  echo "API: $API_KIND"
  echo "Base URL: $BASE_URL"
  echo "Model input metadata: $MODEL_INPUTS"
fi

if [[ "$API_KIND" != "openai-completions" ]]; then
  echo "Unsupported provider api for this checker: $API_KIND" >&2
  exit 1
fi

TMP_RESP="$(mktemp)"
cleanup() {
  rm -f "$TMP_RESP"
}
trap cleanup EXIT

HTTP_STATUS="$(curl -sS --max-time 60 \
  -o "$TMP_RESP" \
  -w '%{http_code}' \
  "${BASE_URL%/}/chat/completions" \
  -H "Authorization: Bearer $API_KEY_VALUE" \
  -H 'Content-Type: application/json' \
  --data "$REQUEST_BODY")"

if [[ "$HTTP_STATUS" != "200" ]]; then
  echo "Vision check failed with HTTP $HTTP_STATUS" >&2
  sed -n '1,200p' "$TMP_RESP" >&2
  exit 1
fi

ANSWER="$(
  awk '/^data: /{sub(/^data: /,""); print}' "$TMP_RESP" \
    | jq -Rr 'fromjson? | .choices[]?.delta.content // empty' \
    | tr -d '\n'
)"

if [[ -z "$ANSWER" ]]; then
  echo "Vision check returned no content." >&2
  if [[ "$VERBOSE" -eq 1 ]]; then
    sed -n '1,200p' "$TMP_RESP" >&2
  fi
  exit 1
fi

echo "provider=$PROVIDER model=$MODEL"
echo "input_metadata=$MODEL_INPUTS"
echo "answer=$ANSWER"
