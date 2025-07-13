#!/bin/bash

# Pull the Gemma3 24B model
docker exec -it ollama ollama pull gemma3:24b

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull Gemma3 24B model" >&2
    exit 1
fi
