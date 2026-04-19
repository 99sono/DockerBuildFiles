#!/bin/bash
echo "Pulling latest vLLM Nightly (Blackwell / SM 12.0 support)..."
docker pull vllm/vllm-openai:nightly
echo "Success: Nightly image pulled."
