#!/bin/bash
set -e
echo "🚀 Starting NORMAL Gemma-4 setup (FP8 KV Cache, 96K Context)..."
docker compose -f docker-compose.yml up -d
echo "------------------------------------------------"
echo "Server is initializing. Monitor logs with: ./05_docker_logs.sh"
