#!/bin/bash
set -euo pipefail

echo "Starting Atlas Qwen3.6-35B-A3B NVFP4 on DGX Spark (GB10)..."

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
echo "Server is initializing (first download takes ~10-15GB)."
echo "Monitor progress: docker logs -f qwen-3-6-35b-a3b-nvfp4-atlas"
