#!/bin/bash
set -e
echo "🚀 Starting Gemma-4 EAGLE-3 Speculative Decoding setup..."
docker compose -f docker-compose-eagle3.yml up -d
echo "------------------------------------------------"
echo "Server is initializing. Speculative decoding enabled (5 tokens)."
echo "Monitor logs with: docker logs -f gemma-4-26b-it-nvfp4-eagle3"
