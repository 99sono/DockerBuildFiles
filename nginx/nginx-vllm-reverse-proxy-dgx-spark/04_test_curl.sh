#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Testing nginx reverse proxy with vLLM ..."
echo ""

# Test 1: Health check (using -k to bypass cert until CA install)
echo "=== Test 1: GET /health (HTTPS with -k) ==="
curl -s -k https://localhost/health
echo ""

# Test 2: Check models endpoint
echo "=== Test 2: GET /v1/models (HTTPS with -k) ==="
curl -s -k https://localhost/v1/models | head -50
echo ""

# Test 3: Chat completion
echo "=== Test 3: POST /v1/chat/completions ==="
curl -s -k https://localhost/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "Qwen3.6-35B-A3B-NVFP4",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}]
  }' | head -20
echo ""

# Test 4: Blocked /invocations endpoint
echo "=== Test 4: GET /invocations (should return 403) ==="
curl -s -k -o /dev/null -w "HTTP Status: %{http_code}\n" https://localhost/invocations
echo ""

echo "All tests complete."