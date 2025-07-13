#!/bin/bash

# Pull the Gemma3 12B model
docker exec -it ollama ollama pull gemma3:12b

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull Gemma3 12B model" >&2
    exit 1
fi
