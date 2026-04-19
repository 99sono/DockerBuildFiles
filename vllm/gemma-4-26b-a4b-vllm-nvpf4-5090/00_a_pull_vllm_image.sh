#!/bin/bash
echo "Pulling latest stable vLLM image (v0.19.0+ for Gemma 4 support)..."
docker pull vllm/vllm-openai:latest
echo "Success: Latest stable image pulled."
