#!/bin/bash
echo "Gracefully stopping llama.cpp server..."
docker compose down
echo "Container stopped."
