#!/bin/bash
# =============================================================================
# 04_test_curl.sh
# Tests the llama.cpp server on port 8081
#
# Model: unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL
# Parameters: temp=1.0, top_p=0.95, max_tokens=131072
# =============================================================================

set -euo pipefail

SERVER_URL="${LLAMA_SERVER_URL:-http://localhost:8081}"
MODEL_ID="unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL"
TEST_PROMPT_FILE="test/test_file_01_prompt.md"
OUTPUT_FILE="test/test_output_01.md"

# -------------------------------------------------------
# Step 1: Check server health & verify loaded model
# -------------------------------------------------------
echo "🔍 Checking server health..."
echo ""

MODELS_RESPONSE=$(curl -s "$SERVER_URL/v1/models" 2>/dev/null) || {
    echo "❌ Cannot connect to server at $SERVER_URL"
    echo "   Make sure the container is running: docker ps | grep qwen-3.6-27b-mtp-5090"
    exit 1
}

echo "$MODELS_RESPONSE" | jq .

echo ""
echo "✅ Server is running. Available models:"
echo "$MODELS_RESPONSE" | jq -r '.data[] | "  - \(.id)"'
echo ""

# -------------------------------------------------------
# Step 2: Send a completion test request
# -------------------------------------------------------

# Read the prompt from file, fallback to inline default
if [ -f "$TEST_PROMPT_FILE" ]; then
    PROMPT_CONTENT=$(cat "$TEST_PROMPT_FILE")
else
    PROMPT_CONTENT="Write a Python function that takes a string, reverses it, and removes all vowels."
    echo "⚠️  Prompt file not found at $TEST_PROMPT_FILE, using default prompt."
fi

echo "🧪 Sending test request to $SERVER_URL/v1/chat/completions"
echo "   Model: $MODEL_ID"
echo ""

# Send completion request
RESPONSE=$(curl -s "$SERVER_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_ID\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are a helpful coding assistant. Write clean, well-documented code.\"
      },
      {
        \"role\": \"user\",
        \"content\": \"$PROMPT_CONTENT\"
      }
    ],
    \"max_tokens\": 2048,
    \"temperature\": 1.0,
    \"top_p\": 0.95,
    \"stream\": false
  }" 2>/dev/null)

# Pretty-print the response
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

# Extract and display the completion
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

if [ -n "$CONTENT" ]; then
    echo "$CONTENT" > "$OUTPUT_FILE"
    echo ""
    echo "✅ Response saved to: $OUTPUT_FILE"
    echo ""
    echo "── Preview (first 500 chars) ──"
    echo "$CONTENT" | head -c 500
    echo ""
    echo ""
    echo "── Token Usage ──"
    echo "$RESPONSE" | jq -r '.usage | "  Prompt tokens: \(.prompt_tokens)\n  Completion tokens: \(.completion_tokens)\n  Total tokens: \(.total_tokens)"' 2>/dev/null
else
    echo "⚠️  No content in response. Check server logs: docker logs -f qwen-3.6-27b-mtp-5090"
fi