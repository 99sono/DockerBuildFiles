# Comparison: Our docker-compose.yml vs MIA AI's config

**Date:** 2026-07-04
**Source:** https://github.com/MiaAI-Lab/Qwen3.6-27B-NVFP4-vLLM
**MIA snapshot:** start.sh (image v0.24.0) + README.md (image nightly)
**Our snapshot:** docker-compose.yml (image nightly, development-network, MTP enabled with num_speculative_tokens=2)

## MIA config (from start.sh)

```bash
docker run -d \
  --name qwen3.6-27b-nvfp4-vllm \
  --network host \
  --ipc host \
  --gpus all \
  -e VLLM_TARGET_DEVICE=cuda \
  -e HF_HOME=/root/.cache/huggingface \
  -e TRITON_CACHE_DIR=/root/.triton \
  -e HF_TOKEN="${HF_TOKEN:-}" \
  -v "${HF_HOME}:/root/.cache/huggingface" \
  -v "${TRITON_CACHE_DIR}:/root/.triton" \
  -v "${WORK_DIR}/chat_template.jinja:/workspace/chat_template.jinja" \
  -v "${WORK_DIR}:/workspace" \
  "${IMAGE}" \
  "${MODEL_ID}" \
    --host "${HOST}" 0.0.0.0 \
    --port "${PORT}" 8888 \
    --tensor-parallel-size 1 \
    --trust-remote-code \
    --attention-backend flashinfer \
    --moe-backend marlin \
    --gpu-memory-utilization 0.4 \
    --max-model-len 262144 \
    --max-num-seqs 4 \
    --max-num-batched-tokens 8192 \
    --enable-chunked-prefill \
    --async-scheduling \
    --enable-prefix-caching \
    --limit-mm-per-prompt '{"image":4}' \
    --allowed-media-domains '*' \
    --speculative-config '{"method":"mtp","num_speculative_tokens":3,"moe_backend":"triton"}' \
    --load-format fastsafetensors \
    --reasoning-parser qwen3 \
    --override-generation-config '{"temperature":0.6,"top_p":0.95,"top_k":20,"min_p":0.0,"presence_penalty":0.0,"repetition_penalty":1.0}' \
    --chat-template /workspace/chat_template.jinja \
    --default-chat-template-kwargs '{"enable_thinking":true,"preserve_thinking":true}' \
    --tool-call-parser qwen3_coder \
    --enable-auto-tool-choice
```

## Our config (from docker-compose.yml)

```yaml
services:
  qwen36-27b-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen36-27b-nvfp4-nightly
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
      HF_XET_HIGH_PERFORMANCE: "1"
      VLLM_USE_RUST_FRONTEND: "0"
    command:
      - "--model" "nvidia/Qwen3.6-27B-NVFP4"
      - "--served-model-name" "${INFERENCE_MODEL_ALIAS:-qwen3.6-27b}"
      - "--api-key" "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host" "0.0.0.0"
      - "--port" "${INFERENCE_SERVER_PORT:-8000}"
      - "--gpu-memory-utilization" "0.70"
      - "--max-model-len" "262144"
      - "--max-num-seqs" "8"
      - "--max-num-batched-tokens" "65536"
      - "--kv-cache-dtype" "fp8"
      - "--dtype" "auto"
      - "--quantization" "modelopt"
      - "--reasoning-parser" "qwen3"
      - "--tool-call-parser" "qwen3_coder"
      - "--enable-auto-tool-choice"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"
      - "--safetensors-load-strategy" "prefetch"
      - "--speculative-config" '{"method":"mtp","num_speculative_tokens":2}'
    networks:
      - development-network
```

## Detailed flag comparison

| # | Flag | MIA | Us | Impact | Adopt? |
|---|------|-----|----|--------|--------|
| 1 | `--attention-backend flashinfer` | explicit | not set (auto) | FlashInfer is default in recent vLLM; explicit is safe. MTP forces FlashInfer backend anyway. | **Yes** — no-op but explicit |
| 2 | `--moe-backend marlin` | explicit | not set (auto) | vLLM auto-detects Marlin for NVFP4. Explicit documents intent. | **Yes** — no-op but explicit |
| 3 | `--speculative-config moe_backend` | `"triton"` | none | **CRITICAL.** MIA sets `moe_backend":"triton"` inside speculative-config. This means the MTP draft head uses Triton MoE kernels, not Marlin. May significantly affect MTP throughput and acceptance rate. | **Yes** |
| 4 | `--num_speculative_tokens` | `3` | `2` | MIA claims 1.5-2× speedup at 3 tokens. More tokens = more speculation but higher overhead if rejected. | **Try 3** |
| 5 | `--override-generation-config` | `{"temperature":0.6,"top_p":0.95,...}` | not set | Sets server-wide defaults matching NVIDIA benchmarks (temp=1.0, top_p=0.95 from gen_config.json). MIA uses temp=0.6 which is more conservative. Current defaults are temp=1.0. | **Yes** — keep NVIDIA defaults (temp=1.0, top_p=0.95, top_k=20) |
| 6 | `--load-format fastsafetensors` | yes | no (uses `--safetensors-load-strategy prefetch` instead) | `fastsafetensors` is a different lib for loading. Complements our `prefetch` strategy. Both can coexist or we could try one vs the other. | **Yes** — add alongside our prefetch |
| 7 | `--limit-mm-per-prompt {"image":4}` | yes | not set | Enables multi-modal image input (up to 4 images per request). Qwen3.6-27B supports vision natively. | **Yes** |
| 8 | `--allowed-media-domains '*'` | yes | not set | Companion to above; allows images from any source domain. | **Yes** |
| 9 | `--chat-template` + `--default-chat-template-kwargs` | `chat_template.jinja` | not set | Custom Jinja template with vision, tool use, thinking blocks. MIA ships a v20 template with full Qwen3.6 support. | **Yes** — grab MIA's template |
| 10 | `--gpu-memory-utilization` | `0.4` | `0.70` | MIA conservatively targets 40GB GPUs. Our GB10 has 128GB unified; 0.70 was already tuned down from 0.85. Keep ours. | **Keep 0.70** |
| 11 | `--max-num-seqs` | `4` | `8` → **`4`** | User wants to lower to 4 for parallelism. MIA uses 4. | **Change to 4** |
| 12 | `--max-num-batched-tokens` | `8192` | `65536` | MIA is very conservative (targeting 40GB). Our 65536 is aggressive for throughput. Could be fine on 128GB GB10. | **Keep 65536** (test if stable) |
| 13 | `--kv-cache-dtype fp8` | not set | `fp8` | Our advantage — halves KV cache memory. Keep. | **Keep** |
| 14 | `--dtype auto` | not set | `auto` | Lets vLLM pick best dtype. Keep. | **Keep** |
| 15 | `--quantization modelopt` | not set (auto-detected) | explicit | NVFP4 is auto-detected from config.json. Explicit is safer. Keep. | **Keep** |
| 16 | `--safetensors-load-strategy prefetch` | not set | `prefetch` | Faster weight loading. Keep. | **Keep** |
| 17 | `PYTORCH_CUDA_ALLOC_CONF` | not set | `expandable_segments:True` | Better memory management on GB10. Keep. | **Keep** |
| 18 | `HF_XET_HIGH_PERFORMANCE` | not set | `1` | Faster HF downloads. Keep. | **Keep** |
| 19 | `VLLM_USE_RUST_FRONTEND` | not set | `0` | Python frontend for compatibility. Keep. | **Keep** |
| 20 | `--served-model-name` | not set | `qwen3.6-27b` | Needed for our nginx routing + opencode model entry. Keep. | **Keep** |
| 21 | `--api-key` | not set (HF_TOKEN only) | `${INFERENCE_API_KEY}` | Security. Keep. | **Keep** |
| 22 | Network | `--network host` | `development-network` | User wants to keep development-network + nginx proxy. Keep. | **Keep** |

## Proposed changes for next experiment

### Flags to add:
```yaml
- "--attention-backend"
- "flashinfer"
- "--moe-backend"
- "marlin"
- "--load-format"
- "fastsafetensors"
- "--limit-mm-per-prompt"
- '{"image":4}'
- "--allowed-media-domains"
- '*'
- "--override-generation-config"
- '{"temperature":1.0,"top_p":0.95,"top_k":20}'
```

### Flags to modify:
```yaml
- "--max-num-seqs"
- "4"                                    # was 8
- "--speculative-config"
- '{"method":"mtp","num_speculative_tokens":3,"moe_backend":"triton"}'   # was 2 tokens, no moe_backend
```

### Flags to keep as-is:
- `--kv-cache-dtype fp8` — critical for memory
- `--gpu-memory-utilization 0.70` — tuned for GB10
- `--max-num-batched-tokens 65536` — aggressive but good for throughput
- `--safetensors-load-strategy prefetch` — complements fastsafetensors
- `--quantization modelopt` — explicit safety
- All env vars and networking

### Files to add:
- `chat_template.jinja` — grab from MIA's repo

## Expected experiment flow

1. Update docker-compose.yml with changes above
2. Download MIA's `chat_template.jinja` into config directory
3. `docker compose down && docker compose up -d`
4. Log dump → metadata02/
5. Measure:
   - Init time
   - Model + KV cache memory
   - MTP acceptance rate (mean acceptance length, draft acceptance rate)
   - Generation throughput (tok/s)
6. Compare against metadata01 numbers

## Previous baselines (metadata01, 2026-07-02)

| Metric | No MTP | MTP (2 tokens) |
|--------|--------|----------------|
| Init time | 443.17 s | 535.77 s |
| Model memory | 19.78 GiB | 20.57 GiB |
| KV cache | — | 48.6 GiB |
| Gen throughput | ~11-12 tok/s | ~20-25 tok/s |
| Mean acceptance len | — | 2.4-2.7 |
| Draft acceptance rate | — | ~75-86% |
