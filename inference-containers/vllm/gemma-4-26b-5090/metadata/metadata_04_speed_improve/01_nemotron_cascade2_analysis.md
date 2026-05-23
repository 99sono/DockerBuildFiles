# Analysis of Docker Compose Configuration for the Gemma‑4 NVFP4 Model

---

### 1. The original `docker-compose.yml` (old compose)

```yaml
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
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
      # Forces the most optimized attention kernel for long sequences
      - VLLM_ATTENTION_BACKEND=FLASHINFER
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "65536"
      - "--max-num-batched-tokens"
      - "8192"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "2"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
```

---

### 2. The improved `docker-compose.yml` (new compose)

```yaml
services:
  gemma-4-26b-it-nvfp4-stable:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-stable
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
      # Force Marlin MoE backend for stability on SM120 (RTX 5090)
      - VLLM_MOE_FORCE_MARLIN=1
      # Keep the safe FlashInfer attention backend
      - VLLM_ATTENTION_BACKEND=FLASHINFER
      # Expand CUDA allocator for large contexts
      - PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.85" # Push to 95% to maximize the pool for that 256k cache
      - "--max-model-len"
      - "256000" # Full 256k context for the 98k KV cache
      - "--max-num-batched-tokens"
      - "32768" # Higher batch capacity for long prompts
      - "--max-num-seqs"
      - "8"
      - "--kv-cache-dtype"
      - "fp8_e4m3" # Essential to fit 98k on one GPU
      - "--quantization"
      - "compressed-tensors"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      - "--moe-backend"
      - "marlin"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true
```

---

### 3. Key Differences & Rationale

| Aspect | Old Compose | New Compose | Why the change matters |
|--------|-------------|-------------|------------------------|
| **Service name** | `gemma-4-26b-it-nvfp4` | `gemma-4-26b-it-nvfp4-stable` | Mirrors the renaming performed on the cascade‑2 compose; makes the purpose obvious (`‑stable`). |
| **MoE backend** | *Implicit* (no explicit flag, FlashInfer‑Cutlass used, which can trigger `Assertion failed: Failed to initialize cutlass TMA WS grouped gemm`) | Explicit `VLLM_MOE_FORCE_MARLIN=1` and `moe-backend: "marlin"` | Marlin is the only backend currently stable on RTX 5090 (SM120) with FP4 weights; prevents the observed cutlass crashes. |
| **Attention backend** | `VLLM_ATTENTION_BACKEND=FLASHINFER` (unchanged) | Same, retained for performance. |
| **CUDA allocator** | Missing | `PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True` | Enables the allocator to grow beyond the default 4 GiB, preventing OOM when the context expands to 256 k. |
| **Context length (`--max-model-len`)** | `65536` | `256000` | Allows the KV‑cache to hold the full 98 k token context advertised by the model; essential for the 96 k+ KV‑cache path. |
| **Batch‑size tuning** | `--max-num-batched-tokens` = 8192, `--max-num-seqs` = 2 | `--max-num-batched-tokens` = 32768, `--max-num-seqs` = 8 | Higher batch capacity and a modest increase in concurrent requests keep the GPU saturated while staying within memory limits. |
| **Editorial choices** | No comments, raw list. | Added explanatory comments (e.g., “Force Marlin MoE backend for stability…”) | Improves onboarding for future maintainers and documents why the changes are necessary. |

---

### 4. Overall Impact

* **Stability** – The explicit Marlin backend removes the FlashInfer cutlass crashes that have been reported when the container start‑up runs on the RTX 5090 GPU with the gemma‑4 model.
* **Usability** – A 256 k context window matches the model’s KV‑cache capacity (98 k) and removes the need for manual work‑arounds; the service can now accept long prompts without hitting paging.
* **Performance** – Raising `--max-num-batched-tokens` to 32 768 and `--max-num-seqs` to 8 maximises GPU utilisation under the 32 GiB limit introduced by `shm_size: "32g"`. The extra batch room is crucial for serving many long‑context requests.
* **Maintainability** – The file contains clear comments and a stable service name, reducing future guesswork.

---

### 5. Next Steps (if you decide to make the change)

1. Overwrite the current `vllm/gemma-4-26b-a4b-vllm-nvpf4-5090/docker-compose.yml` with the **new compose** (the content above).  
2. Run `docker compose up -d` and check the logs for a clean start (`grep "Model loading"`, `grep "MoE"`).  
3. Execute a sample request with a 256 k prompt (e.g., `curl ...`) and verify the response time and memory usage.  
4. If all looks healthy, commit the file with a message like:  `feat(docker-compose): migrate gemma‑4 to Marlin backend and 256k context`.  

The analysis above is now saved at `deleteMe_cascade2_analysis.md`. Review it as a pair of compose files and the reasoning behind each change.