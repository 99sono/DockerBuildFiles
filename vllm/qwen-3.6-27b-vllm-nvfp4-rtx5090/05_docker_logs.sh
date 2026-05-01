#!/bin/bash

# Find the most recently started Qwen container
CONTAINER=$(docker ps --filter "name=qwen-3-6-27b-nvfp4" --format "{{.Names}}" | head -n 1)

if [ -n "$CONTAINER" ]; then
    echo "📺 Tailing logs for: $CONTAINER"
    docker logs -f "$CONTAINER"
else
    echo "❌ No Qwen-3.6 container found running."
    exit 1
fi
