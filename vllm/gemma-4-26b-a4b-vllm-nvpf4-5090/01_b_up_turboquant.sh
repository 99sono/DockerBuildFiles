#!/bin/bash
set -e
echo "🚀 Starting TURBOQUANT Gemma-4 setup (k8v4 Compression, ~200K Context)..."
docker compose -f docker-compose-turboquant.yml up -d
echo "------------------------------------------------"
echo "Server is initializing. Monitor logs for 'TurboQuant' mentions."
echo "Monitor logs with: docker logs -f gemma-4-26b-it-nvfp4-turbo"
