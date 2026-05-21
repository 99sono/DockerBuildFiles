#!/bin/bash
echo "Starting Qwen3.6-35B-A3B PrismaQuant on DGX Spark..."
mkdir -p ./hf-cache
docker compose -f docker-compose02.yml up -d
echo "------------------------------------------------"
echo "Server is initializing (first download takes ~10GB)."
echo "Monitor progress: docker logs -f qwen3-6-prismaquant-35b"
