#!/bin/bash

# Pull the Qwen3 30B model
docker exec -it ollama ollama pull gpt-oss:20b

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull gpt-oss:20b model" >&2
    exit 1
fi
