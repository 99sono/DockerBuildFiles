#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 04_b_chat_completion.sh - Test chat completion on Atlas server
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

INFERENCE_API_KEY="${INFERENCE_API_KEY:-dummy-key}"
MODEL="${INFERENCE_MODEL_ALIAS:-qwen3.6-35b}"
PROMPT="${1:-What is the meaning of life? Answer in one sentence.}"

echo "💬 Sending chat completion request to Atlas server..."
echo "   URL       : http://localhost:8000/v1/chat/completions"
echo "   Model     : $MODEL"
echo "   API Key   : ${INFERENCE_API_KEY:0:4}...${INFERENCE_API_KEY: -4}"
echo "   Prompt    : $PROMPT"
echo "------------------------------------------------------------"

curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $INFERENCE_API_KEY" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"$PROMPT\"}
    ],
    \"max_tokens\": 256,
    \"temperature\": 0.7
  }" | python3 -m json.tool

echo ""
echo "✅ Done."
