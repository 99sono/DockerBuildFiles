#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

echo "Testing stream_options include_usage on head node (localhost:8000)..."
echo ""

RESPONSE=$(curl -s --max-time 30 http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${INFERENCE_API_KEY:-dummy-key}" \
  -d '{
    "model": "deepseek-v4-flash",
    "messages": [{"role":"user","content":"Say hello in one word"}],
    "max_tokens": 5,
    "stream": true,
    "stream_options": {"include_usage": true}
  }' 2>&1) || {
  echo "CURL FAILED: $RESPONSE"
  echo "Is the head container running?"
  exit 1
}

LAST_CHUNK=$(echo "$RESPONSE" | grep -a 'data: ' | tail -1)

echo "Last stream chunk:"
echo "$LAST_CHUNK" | head -c 2000
echo ""

if echo "$LAST_CHUNK" | grep -q '"usage"'; then
  echo "SUCCESS: usage metadata found in stream."
else
  echo "ISSUE: usage metadata missing."
fi
