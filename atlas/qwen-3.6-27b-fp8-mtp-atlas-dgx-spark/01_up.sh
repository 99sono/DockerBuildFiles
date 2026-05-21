#!/bin/bash
set -euo pipefail

echo "Starting Atlas Qwen3.6-27B-FP8 (Dense) on DGX Spark (GB10)..."

# Ensure cache directory exists
mkdir -p ./hf-cache

# Check for required .env file
if [ ! -f .env ]; then
    echo ""
    echo "❌ Missing .env — cannot start without auth token."
    echo ""
    echo "   Fix: copy the template and add your own token:"
    echo "     cp .env.example .env"
    echo "     # Then edit .env with a real token (e.g., openssl rand -hex 24)"
    echo ""
    exit 1
fi

docker compose up -d
echo "------------------------------------------------"
echo "Server is initializing (first download takes time)."
echo "Monitor progress: docker logs -f qwen-3-6-27b-fp8-mtp-atlas"
