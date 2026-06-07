#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
load_env

echo "=========================================="
echo "  Gemma 4 26B A4B — Available Commands"
echo "=========================================="
echo ""
echo "Setup scripts:"
echo "  00_a_pull_image.sh            — Pull llama.cpp server image (CUDA, ARM64)"
echo "  00_b_create_conda_env.sh      — Create conda environment 'testLlamaCppGemma'"
echo "  00_c_install_packages.sh      — Install HuggingFace Hub and CLI packages"
echo "  00_d_pre_download_model.sh    — Download Gemma 4 26B MoE GGUF + mmproj"
echo "  00_e_force_download_model.sh  — Force re-download model (bypasses cache)"
echo ""
echo "Server lifecycle:"
echo "  01_up.sh                      — Start Gemma 4 26B A4B container"
echo "  02_down.sh                    — Stop running inference container"
echo ""
echo "Operations (auto-detect active container):"
echo "  03_enter_container.sh         — Enter the container's bash shell"
echo "  05_docker_logs.sh             — Follow logs of the active container"
echo ""
echo "Other:"
echo "  04_test_curl.sh               — Test API connectivity"
echo "  06_dump_help.sh               — Show this help + llama-server info"
echo ""

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^gemma-4\.26b-a4b-dgx-spark$' | head -1)
if [ -n "$CONTAINER" ]; then
  echo "Active container detected: $CONTAINER"
  echo "Dumping llama.cpp server version/help info..."
  echo ""
  docker exec "$CONTAINER" llama-server --version 2>&1 || true
  docker exec "$CONTAINER" llama-server --help 2>&1 | head -100 || true
else
  echo "No active inference container detected — showing help above only."
fi
