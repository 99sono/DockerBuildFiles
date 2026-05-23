#!/bin/bash
echo "Starting Qwen3.6-27B MTP on RTX 5090 (llama.cpp)..."
docker compose up -d
echo "------------------------------------------------"
echo "Server is initializing (first download pulls GGUF from HF hub to ~/.cache/huggingface)."
echo "Monitor progress: docker logs -f qwen-3.6-27b-mtp-5090"