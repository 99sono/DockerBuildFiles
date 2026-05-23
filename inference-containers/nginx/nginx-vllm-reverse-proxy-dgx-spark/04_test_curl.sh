#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="./00_env.sh"
EXAMPLE_FILE="./00_env.sh.example"

# Auto-copy from example if 00_env.sh doesn't exist
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Warning: $ENV_FILE not found. Auto-copying from $EXAMPLE_FILE ..."
  cp "$EXAMPLE_FILE" "$ENV_FILE"
fi

# Source environment variables
source "$ENV_FILE"

echo "Testing nginx reverse proxy with vLLM ..."
echo ""

# Test 1: Health check (using -k to bypass cert until CA install)
echo "=== Test 1: GET /health (HTTPS with -k) ==="
curl -s -k https://$DGX_HOSTNAME/health
echo ""

# Test 2: Check models endpoint (Authorization header required by vLLM)
echo "=== Test 2: GET /v1/models (HTTPS with -k) ==="
curl -s -k https://$DGX_HOSTNAME/v1/models \
  -H "Authorization: Bearer $VLLM_API_KEY" | head -50
echo ""

# Test 3: Chat completion
echo "=== Test 3: POST /v1/chat/completions ==="
curl -s -k https://$DGX_HOSTNAME/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $VLLM_API_KEY" \
  -d '{
    "model": "qwen3.6-35b",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}]
  }' | head -20
echo ""

# Test 4: Blocked /invocations endpoint (should return 403)
echo "=== Test 4: GET /invocations (should return 403) ==="
curl -s -k -o /dev/null -w "HTTP Status: %{http_code}\n" \
  -H "Authorization: Bearer $VLLM_API_KEY" \
  https://$DGX_HOSTNAME/invocations
echo ""

echo "All tests complete."