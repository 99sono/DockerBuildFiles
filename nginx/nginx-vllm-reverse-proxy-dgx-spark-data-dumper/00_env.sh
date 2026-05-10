# .env.sh - Environment variables for debug proxy bash scripts
# Copy from 00_env.sh.example if needed.

# ============================================================
# DEBUG PROXY CONFIGURATION
# ============================================================
DEBUG_PROXY_PORT=8888
DEBUG_CONTAINER_NAME=nginx-proxy-debug
COMPOSE_PROJECT_NAME=nginx-debug
DEBUG_LOGS_DIR="./logs"
VLLM_BACKEND=vllm
VLLM_BACKEND_PORT=8000