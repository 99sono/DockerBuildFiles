#!/bin/bash

# Ensure shared development network exists
echo "🔗 Ensuring shared development network exists..."
./../commonScripts/create_development_network.sh

# Start Docker Compose services
docker-compose up -d

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to start Docker Compose services" >&2
    exit 1
fi

echo "Docker Compose services started successfully"
