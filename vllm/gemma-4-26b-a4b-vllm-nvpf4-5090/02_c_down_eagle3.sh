#!/bin/bash
set -e
echo "🛑 Stopping Gemma-4 EAGLE-3 server..."
docker compose -f docker-compose-eagle3.yml down
echo "Container stopped."
