#!/bin/bash
echo "Displaying logs for qwen3-6-prismaquant-35b (Ctrl+C to stop)..."
docker logs -f qwen3-6-prismaquant-35b

# docker logs qwen3-6-prismaquant-35b > 01_vllm_log.md 2>&1
