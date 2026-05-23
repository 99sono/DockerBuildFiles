#!/bin/bash
set -e
echo "🛑 Stopping TURBOQUANT Gemma-4 server..."
docker compose -f docker-compose-turboquant.yml down
echo "Container stopped."
