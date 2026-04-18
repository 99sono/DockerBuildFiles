#!/bin/sh
# Force these into the environment of this shell and all children
export TRIATTN_STATS_DIR=/root/.cache/triattention/stats
export TRIATTN_ENABLE=true
export TRIATTN_RUNTIME_KV_BUDGET=4096
export TRIATTN_RUNTIME_PROTECT_PREFILL=true
export TRIATTN_VERBOSE=1

# Execute the original vLLM entrypoint command
exec python3 -m vllm.entrypoints.openai.api_server "$@"
