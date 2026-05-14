#!/bin/bash
# =============================================================================
# 04_test_curl.sh
# Sends a test prompt to the llama.cpp server on port 8081
# =============================================================================

set -euo pipefail

SERVER_URL="${LLAMA_SERVER_URL:-http://localhost:8081}"

echo "🧪 Testing llama.cpp server at $SERVER_URL"
echo ""

# Send a simple test prompt via cURL
curl -s "$SERVER_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "unsloth/Qwen3.6-27B-A3B-GGUF:UD-Q4_K_XL",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant."
      },
      {
        "role": "user",
        "content": "What is the capital of France? Answer in one sentence."
      }
    ],
    "max_tokens": 64,
    "temperature": 1.0,
    "top_p": 0.95
  }' | jq .

echo ""
echo "✅ Test complete!"