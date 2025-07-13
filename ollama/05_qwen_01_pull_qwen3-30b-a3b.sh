#!/bin/bash

# Pull the Qwen3 30B model
docker exec -it ollama ollama pull qwen3:30b-a3b

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull Qwen3 30B model" >&2
    exit 1
fi
