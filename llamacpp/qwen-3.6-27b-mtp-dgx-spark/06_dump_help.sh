#!/bin/bash
echo "Dumping llama.cpp server version/help info..."
docker exec qwen-3.6-27b-mtp-dgx-spark llama-server --version 2>&1 || true
docker exec qwen-3.6-27b-mtp-dgx-spark llama-server --help 2>&1 | head -100 || true
