#!/bin/bash
# Pull the DeepSeek-V4-Flash Docker image on both nodes.
# Run this BEFORE launching the cluster.
set -euo pipefail
docker pull aidendle94/sparkrun-vllm-ds4-gb10:production-ready
echo "Image pulled successfully."
