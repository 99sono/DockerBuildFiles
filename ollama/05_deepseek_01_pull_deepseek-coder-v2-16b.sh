#!/bin/bash

# Pull the DeepSeek Coder V2 16B model
docker exec -it ollama ollama pull deepseek-coder-v2:16b

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull DeepSeek Coder V2 16B model" >&2
    exit 1
fi
