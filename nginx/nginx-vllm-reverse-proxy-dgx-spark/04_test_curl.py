#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source .env if it exists
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
fi

VLLM_API_KEY="${VLLM_API_KEY:-dummy-key}"

echo "Testing nginx reverse proxy with vLLM ..."
echo ""

# Test 1: Check models endpoint (using -k to bypass cert until CA install)
echo "=== Test 1: GET /v1/models (HTTPS with -k) ==="
curl -k -s https://localhost:443/v1/models | head -50
echo ""

# Test 2: Health check
echo "=== Test 2: GET /health ==="
curl -s -k https://localhost:443/health
echo ""

# Test 3: Chat completion
echo "=== Test 3: POST /v1/chat/completions ==="
curl -s -k https://localhost:443/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${VLLM_API_KEY}" \
  -d '{
    "model": "Qwen3.6-35B-A3B-NVFP4",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}]
  }' | head -20
echo ""

echo "All tests complete."
