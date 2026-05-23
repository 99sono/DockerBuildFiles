#!/bin/bash

# Web request to ollama
curl http://localhost:11434/api/generate -d '{
    "model": "gemma3:4b",
    "prompt": "Hi there.",
    "options": {
        "num_ctx": 8192
    }
}'

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to send request to Ollama" >&2
    exit 1
fi
