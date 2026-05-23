#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
echo "Dumping llama.cpp server version/help info..."
docker exec qwen-3.6-27b-mtp-5090 llama-server --version 2>&1 || true
docker exec qwen-3.6-27b-mtp-5090 llama-server --help 2>&1 | head -100 || true
