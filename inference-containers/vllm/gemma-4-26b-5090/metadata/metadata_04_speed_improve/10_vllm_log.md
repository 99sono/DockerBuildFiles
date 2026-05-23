#compose
```yml
version: "3.9"

services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-stable
    hostname: gemma-4-26b-it-nvfp4
    platform: linux/amd64

    ports:
      - "8000:8000"

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
      # Required for Blackwell + WSL2 stability
      VLLM_WORKER_MULTIPROC_METHOD: spawn

      # Critical for very large KV-cache allocations
      PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True

      # Optional but useful for faster model pulls
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      # Model
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"

      # Required
      - "--trust-remote-code"

      # Networking
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # Memory budget
      - "--gpu-memory-utilization"
      - "0.85"

      # ===== Long-context experiment =====
      - "--max-model-len"
      - "256000"

      # Batching (intentionally conservative for long windows)
      - "--max-num-seqs"
      - "2"
      - "--max-num-batched-tokens"
      - "16384"

      # KV cache
      - "--kv-cache-dtype"
      - "fp8_e4m3"

      # Quantization
      - "--quantization"
      - "compressed-tensors"

      # Long-context ergonomics
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # Reasoning + tools
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"

      # NVFP4 MoE backend (performance path)
      - "--moe-backend"
      - "cutlass"

      # Optional ultra-stability fallback (DISABLED by default)
      # - "--moe-backend"
      # - "marlin"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log
IServer pid=1) INFO:     Started server process [1]

(APIServer pid=1) INFO:     Waiting for application startup.

(APIServer pid=1) INFO:     Application startup complete.

(APIServer pid=1) INFO:     172.18.0.1:59468 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO:     172.18.0.1:59468 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 22:44:09 [loggers.py:271] Engine 000: Avg prompt throughput: 2123.9 tokens/s, Avg generation throughput: 23.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%

(APIServer pid=1) INFO 04-23 22:44:19 [loggers.py:271] Engine 000: Avg prompt throughput: 1283.0 tokens/s, Avg generation throughput: 103.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.1%, Prefix cache hit rate: 38.4%

(APIServer pid=1) INFO:     172.18.0.1:59468 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 22:44:26 [loggers.py:271] Engine 000: Avg prompt throughput: 248.1 tokens/s, Avg generation throughput: 104.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.3%, Prefix cache hit rate: 60.2%

(APIServer pid=1) INFO 04-23 22:44:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 10.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.2%

(APIServer pid=1) INFO 04-23 22:44:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.2%

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 22:57:32 [loggers.py:271] Engine 000: Avg prompt throughput: 158.3 tokens/s, Avg generation throughput: 46.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 70.6%

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 22:57:42 [loggers.py:271] Engine 000: Avg prompt throughput: 471.1 tokens/s, Avg generation throughput: 90.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.1%, Prefix cache hit rate: 83.1%

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO:     172.18.0.1:42110 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 22:57:50 [loggers.py:271] Engine 000: Avg prompt throughput: 624.6 tokens/s, Avg generation throughput: 87.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.9%, Prefix cache hit rate: 87.5%

(APIServer pid=1) INFO 04-23 22:58:00 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 87.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 87.5%

(APIServer pid=1) INFO 04-23 22:58:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 87.5%

(APIServer pid=1) INFO:     172.18.0.1:33308 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-23 23:00:00 [loggers.py:271] Engine 000: Avg prompt throughput: 300.7 tokens/s, Avg generation throughput: 34.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 88.3%

(APIServer pid=1) INFO 04-23 23:00:08 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 88.3%
