#!/bin/bash

# Pull Docker images
docker-compose pull

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull Docker images" >&2
    exit 1
fi

echo "Docker images pulled successfully"
