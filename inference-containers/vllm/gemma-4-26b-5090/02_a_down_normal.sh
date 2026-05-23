#!/bin/bash
set -e
echo "🛑 Stopping NORMAL Gemma-4 server..."
docker compose -f docker-compose.yml down
echo "Container stopped."
