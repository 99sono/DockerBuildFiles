#!/bin/bash
# Use a clever trick to find which container is running
CONTAINER=$(docker ps --filter "name=gemma-4-26b-it-nvfp4" --format "{{.Names}}" | head -n 1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No Gemma-4 container found running."
    exit 1
fi
echo "📋 Displaying logs for $CONTAINER (Ctrl+C to stop)..."
docker logs -f "$CONTAINER"
