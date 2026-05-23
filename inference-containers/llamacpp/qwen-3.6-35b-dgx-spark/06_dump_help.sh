#!/bin/bash
echo "Dumping llama.cpp server help..."
docker run --rm ghcr.io/ggml-org/llama.cpp:server-cuda13 llama-server -h 2>&1 | tee metadata/server_help_dump.txt
