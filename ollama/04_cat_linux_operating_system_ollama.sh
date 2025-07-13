#!/bin/bash

# Show the operating system of the Ollama container
docker exec ollama /bin/bash -c "cat /etc/os-release"

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to get OS information from Ollama container" >&2
    exit 1
fi
