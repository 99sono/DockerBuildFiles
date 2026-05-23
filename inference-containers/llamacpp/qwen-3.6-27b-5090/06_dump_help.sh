#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
load_env

echo "=========================================="
echo "  Qwen3.6-27B MTP — Available Commands"
echo "=========================================="
echo ""
echo "Model-specific scripts:"
echo "  00_d_pre_download_model_unsloth.sh  — Download unsloth Qwen3.6 model"
echo "  00_d_pre_download_model_qwopus.sh   — Download Jackrong Qwopus3.6 model"
echo "  01_up_unsloth.sh                    — Start unsloth/Qwen3.6 container"
echo "  01_up_qwopus.sh                     — Start Jackrong/Qwopus3.6 container"
echo ""
echo "Shared scripts (auto-detect active container):"
echo "  02_down.sh                          — Stop any running inference container"
echo "  03_enter_container.sh               — Enter the active container's bash"
echo "  05_docker_logs.sh                   — Follow logs of the active container"
echo ""
echo "Other:"
echo "  04_test_curl.sh                     — Test API connectivity"
echo "  06_dump_help.sh                     — Show this help + llama-server info"
echo ""

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^(qwen-3\.6-27b-mtp-5090|qwopus36-27b-mtp-5090)$' | head -1)
if [ -n "$CONTAINER" ]; then
  echo "Active container detected: $CONTAINER"
  echo "Dumping llama.cpp server version/help info..."
  echo ""
  docker exec "$CONTAINER" llama-server --version 2>&1 || true
  docker exec "$CONTAINER" llama-server --help 2>&1 | head -100 || true
else
  echo "No active inference container detected — showing help above only."
fi
