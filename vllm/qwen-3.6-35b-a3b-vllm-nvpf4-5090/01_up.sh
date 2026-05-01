#!/bin/bash
echo "Starting Qwen3.6-35B-A3B NVFP4 on RTX 5090..."
# Ensure cache directory exists
mkdir -p ./hf-cache
docker compose up -d
echo "------------------------------------------------"
echo "Server is initializing (first download takes ~10-15GB)."
echo "Monitor progress: docker logs -f qwen3-6-moe-35b-a3b-nvfp4"
