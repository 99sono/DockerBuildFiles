#!/bin/bash

# Pull the DeepSeek R1 8B model
docker exec -it ollama ollama pull deepseek-r1:8b-0528-qwen3-fp16

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull DeepSeek R1 8B model" >&2
    exit 1
fi
