I see exactly why the "Brute Force" wrapper is failing. It's a clash between Docker Compose's string parsing and how the `vllm/vllm-openai` base image expects commands.

The official `vllm/vllm-openai` Dockerfile uses `ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]`. When you provide a `command:` in Docker Compose, it *appends* it to that entrypoint. 

So, Docker was essentially executing this:
`python3 -m vllm.entrypoints.openai.api_server /bin/sh -c 'export ...'`

vLLM interpreted `/bin/sh` as the model name, and `-c` as the `--compilation-config` argument, which caused the JSON parsing error!

### The True Fix: Overriding the Entrypoint

We need to override the `ENTRYPOINT` to use `/bin/sh` instead of Python, and then pass our script as the `command`.

Here is the fully corrected, drop-in replacement for your `docker-compose.yml`:

```yaml
# Nemotron-Cascade-2-30B-A3B-NVFP4 + TriAttention
# Optimized for RTX 5090 (Blackwell) + WSL2 – April 2026

services:
  nemotron-cascade:
    image: vllm-triattention:1.0.0
    container_name: nemotron-cascade-2-triattn
    hostname: nemotron-cascade-2-triattn
    platform: linux/amd64
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - ~/.cache/triattention:/root/.cache/triattention
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      # --- PLUGIN & ENGINE CORE ---
      - VLLM_PLUGINS=triattention
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
      - VLLM_LOGGING_LEVEL=DEBUG

      # --- LONG CONTEXT SUPPORT ---
      - VLLM_ALLOW_LONG_MAX_MODEL_LEN=1

    # --- THE CRITICAL FIX ---
    # We must override the image's default Python entrypoint so we can use a shell script.
    entrypoint: ["/bin/sh", "-c"]

    # Now the command is evaluated by the shell, forcing the variables into the environment
    # before starting the Python process, bypassing vLLM's variable stripping.
    command: >
      "export TRIATTN_STATS_DIR=/root/.cache/triattention/stats &&
      export TRIATTN_ENABLE=true &&
      export TRIATTN_RUNTIME_KV_BUDGET=4096 &&
      export TRIATTN_RUNTIME_PROTECT_PREFILL=true &&
      export TRIATTN_VERBOSE=1 &&
      python3 -m vllm.entrypoints.openai.api_server
      --model chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4
      --served-model-name chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4
      --attention-backend TRITON_ATTN
      --mamba-ssm-cache-dtype float32
      --trust-remote-code
      --no-enable-prefix-caching
      --max-num-batched-tokens 1024
      --enforce-eager
      --max-model-len 262144
      --gpu-memory-utilization 0.85"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

### Why this will work
By adding `entrypoint: ["/bin/sh", "-c"]`, Docker will now properly execute the shell string, export the variables to the OS level inside the container, and *then* launch `vllm`. 

This guarantees the `TRIATTN_STATS_DIR` variable is hardcoded into the process environment before vLLM's V1 engine even wakes up, permanently solving the `stats_path_not_set` crash.