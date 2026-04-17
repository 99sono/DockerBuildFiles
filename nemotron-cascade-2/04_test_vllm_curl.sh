#!/bin/bash

# Configuration
TEST_PROMPT_FILE="test/test_file_01_prompt.md"
URL="http://localhost:8000/v1/chat/completions"

# Check if prompt file exists
if [ ! -f "$TEST_PROMPT_FILE" ]; then
    echo "Error: Test prompt file not found at $TEST_PROMPT_FILE"
    exit 1
fi

# Prepare prompt JSON (basic escape for content)
PROMPT=$(cat "$TEST_PROMPT_FILE" | sed 's/"/\\"/g' | tr '\n' ' ')

# Send request to vLLM
curl -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4\",
        \"messages\": [
            {\"role\": \"user\", \"content\": \"$PROMPT\"}
        ],
        \"max_tokens\": 512,
        \"temperature\": 0.7
    }"
