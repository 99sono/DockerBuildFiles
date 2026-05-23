#!/bin/bash
echo "Starting Qwen3.6-27B NVFP4 MTP on DGX Spark..."
mkdir -p ./hf-cache
docker compose up -d
echo "------------------------------------------------"
echo "Server is initializing (first download pulls NVFP4 model from HF hub)."
echo "Monitor progress: docker logs -f qwen-3.6-27b-nvfp4-mtp-dgx-spark"