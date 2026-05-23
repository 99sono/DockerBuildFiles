# docker compose 
```yml
services:
  prismaquant-35b:
    image: vllm/vllm-openai:v0.20.2-ubuntu2404
    container_name: qwen3-6-prismaquant-35b
    hostname: inference-server
    platform: linux/arm64
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - /dev/shm:/dev/shm
    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      VLLM_MARLIN_USE_ATOMIC_ADD: "1"
      VLLM_HTTP_TIMEOUT_KEEP_ALIVE: "600"
      FLASHINFER_DISABLE_VERSION_CHECK: "1"

    command:
      - "--model"
      - "rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm"
      - "--served-model-name"
      - "qwen3.6-35b"
      - "--api-key"
      - "${VLLM_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # --- MEMORY & CONTEXT ---
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "10"

      # --- BATCHING / PREFILL ---
      - "--max-num-batched-tokens"
      - "32768"

      # --- QUANTIZATION & ATTN ---
      - "--kv-cache-dtype"
      - "fp8"
      - "--quantization"
      - "compressed-tensors"
      - "--attention-backend"
      - "flashinfer"
      - "--dtype"
      - "auto"

      # --- PARSERS & TOOLS ---
      - "--reasoning-parser"
      - "qwen3"
      - "--enable-auto-tool-choice"
      - "--tool-call-parser"
      - "qwen3_coder"

      # --- CACHING & PREFILL ---
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # --- MTP SPECULATIVE DECODING (n=3 — measured optimum) ---
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":3}'

    networks:
      - development-network

networks:
  development-network:
    external: true

```


# vllm log 