#!/bin/bash

# Connect to the Ollama container
docker exec -it ollama /bin/bash

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Ollama container" >&2
    exit 1
fi
