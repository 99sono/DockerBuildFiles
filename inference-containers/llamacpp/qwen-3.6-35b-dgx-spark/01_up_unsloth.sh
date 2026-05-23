#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Starting Qwen3.6-35B-A3B MTP on DGX Spark GB10 (llama.cpp) — Unsloth variant..."
docker_compose_up
