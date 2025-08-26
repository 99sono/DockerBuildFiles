#!/bin/bash

if [ "$1" = "--list" ]; then
  echo "Available models (see models.md for details):"
  cat models.md
  exit 0
fi

docker exec -it ollama ollama pull "$1"

# Check if the command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull $1 model" >&2
    exit 1
fi
