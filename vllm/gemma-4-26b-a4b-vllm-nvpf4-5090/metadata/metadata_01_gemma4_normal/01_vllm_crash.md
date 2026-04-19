# docker compose
services:
  gemma4-26b-nvfp4:
    image: vllm/vllm-openai:latest
    container_name: gemma-4-26b-it-nvfp4
    hostname: gemma-4-26b-it-nvfp4
    runtime: nvidia
    restart: unless-stopped
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
      - NVIDIA_VISIBLE_DEVICES=all
      - HF_HUB_ENABLE_HF_TRANSFER=1
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--model"
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "98304"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true

# crash

2026-04-19 12:48:50.490 | WARNING 04-19 10:48:50 [argparse_utils.py:191] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in v0.13.
2026-04-19 12:48:50.492 | usage: vllm [-h] [-v]
2026-04-19 12:48:50.492 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 12:48:50.492 | vllm: error: unrecognized arguments: RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 12:48:59.383 | WARNING 04-19 10:48:59 [argparse_utils.py:191] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in v0.13.
2026-04-19 12:48:59.384 | usage: vllm [-h] [-v]
2026-04-19 12:48:59.384 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 12:48:59.384 | vllm: error: unrecognized arguments: RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 12:49:07.809 | WARNING 04-19 10:49:07 [argparse_utils.py:191] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in v0.13.
2026-04-19 12:49:07.810 | usage: vllm [-h] [-v]
2026-04-19 12:49:07.810 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 12:49:07.810 | vllm: error: unrecognized arguments: RedHatAI/gemma-4-26B-A4B-it-NVFP4