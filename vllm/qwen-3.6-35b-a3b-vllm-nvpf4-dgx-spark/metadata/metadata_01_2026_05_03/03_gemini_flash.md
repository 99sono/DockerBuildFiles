# docker compose
```yml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-aarch64-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    platform: linux/arm64
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
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      # Asynchronous CPU/GPU overlap for max speed
      # VLLM_USE_V2_MODEL_RUNNER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "Qwen3.6-35B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # --- MEMORY & CONTEXT ---
      # --gpu-memory-utilization: Fraction of GPU VRAM reserved for the model.
      #   0.85 = 85% of 128GB UMA = ~108.8 GB for model weights + KV cache.
      #   Dropped from 0.90 to leave more room for System/CPU in the unified memory architecture.
      #
      # --max-model-len: Maximum context length (prompt + response) in tokens.
      #   262144 = ~256K tokens = maximum context window.
      #   With 128GB UMA, the Spark can handle massive context windows.
      #
      # --max-num-seqs: Maximum number of concurrent request sequences.
      #   Set to 8 for multi-agent / multi-user parallelism.
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "8"

      # --- BATCHING / PREFILL OPTIMIZATION ---
      # --max-num-batched-tokens controls how many tokens the model can process
      # during the prompt prefill phase (before generating output tokens).
      #
      # Higher values = faster prompt processing but more GPU memory consumed
      # for KV cache allocation. Lower values = slower prefill but more memory
      # available for context window.
      #
      # DGX Spark (Grace Blackwell) trade-offs:
      #   - 65536: Massive prefill for high-speed document ingestion (★ GODZILLA MODE)
      #   - 32768: Fast prefill, still excellent KV cache headroom
      #   -  8192: Conservative prefill, good for smaller contexts
      #
      # 65536 leverages the 128GB unified memory for blazing-fast prefill.
      - "--max-num-batched-tokens"
      - "65536"

      # --- ARCHITECTURE & QUANTIZATION ---
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # --- KERNEL FUSION (The Speed Unlock) ---
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # --- STARTUP OPTIMIZATIONS (Boot Faster) ---
      # Force disk I/O overlap
      - "--safetensors-load-strategy"
      - "prefetch"
      
      # Stop capturing useless batch graphs you won't use in single-user mode
      - "--max-cudagraph-capture-size"
      - "1"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# Gemini flash
This is it—this is the **"Godzilla Mode"** configuration that actually respects the hardware you are standing in front of. By shifting from a single-user "Ferrari" mindset to a high-throughput "Superchip" mindset, you are leveraging the core strengths of the Grace Blackwell architecture.

### Why this Configuration is a Game Changer

*   **Prefill at Scale (`65536` tokens):** Your previous log showed nearly **5,000 tokens/s** with an 8k prefill. By jumping to 64k, you are allowing the engine to saturate the massive memory bandwidth of the GB10. For long-context RAG or document analysis, the time-to-first-token will be staggeringly fast compared to consumer hardware.
*   **The 256k Context Window:** With **128GB of Unified Memory (UMA)**, the Spark is uniquely suited for this. Unlike traditional GPUs where the KV cache is trapped in 24GB or 80GB of VRAM, the Spark can spill across the unified pool. Setting `0.85` utilization is a smart safety move to keep the Linux kernel and your SSH session from being squeezed out of the UMA.
*   **Parallelism (`--max-num-seqs 8`):** This is where you'll see the real "value per second" return. Even if a single generation stays at ~40 tokens/s, handling 8 requests simultaneously means your total system throughput effectively hits **~320 tokens/s**.
*   **Backend Alignment:** Switching to `flashinfer_cutlass` aligns perfectly with RedHat's optimized path for the NVFP4 version of Qwen 3.6, ensuring the most efficient MoE routing.

---

### One Critical Log to Watch For
When you run this, pay close attention to the **KV Cache initialization** line in the logs:

> `(EngineCore pid=XXX) INFO XX-XX XX:XX:XX [kv_cache_utils.py:XXXX] GPU KV cache size: X,XXX,XXX tokens`

With a 256k context window and FP8 KV cache, we want to ensure vLLM still sees a comfortable number of total tokens available. If that number drops too low, you might see "request ignored" errors under heavy load, but with 128GB, I suspect you'll still have over a million tokens of headroom.

### Pre-Flight Tip
Before you `docker compose up`, don't forget your own advice from the **Survival Guide**:

```bash
# Clear the UMA buffer cache to give vLLM a clean slate
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
```

**Godspeed. Let's see those new throughput numbers once the server hits "Application startup complete."**



# gemini part 2 

The short answer is **yes**. While both are high-performance Cutlass-based implementations, **`FLASHINFER_CUTLASS`** is generally the superior choice for your current setup for several reasons:

### 1. JIT Autotuning Synergy
The `FLASHINFER_CUTLASS` backend is designed to work in tandem with the **FlashInfer JIT (Just-In-Time) Autotuner** you saw in your logs. 
*   **VLLM_CUTLASS** uses a set of high-quality, but more generalized, heuristic kernels.
*   **FLASHINFER_CUTLASS** allows the engine to more aggressively tune the specific tile sizes and math shapes for the **SM121 (Blackwell)** architecture during the "warmup" phase. 

### 2. Reduced Kernel Launch Overhead
FlashInfer's implementation of Cutlass kernels is specifically optimized to minimize "kernel launch latency." 
*   On a high-throughput machine like the DGX Spark, if you are running **8+ parallel sequences**, the CPU (Grace) can sometimes become the bottleneck just trying to tell the GPU (Blackwell) what to do next. 
*   FlashInfer kernels are often "fused" more tightly, meaning fewer calls from the CPU to the GPU, which directly translates to higher total throughput.

### 3. RedHat/Hugging Face Validation
Since you are serving the **RedHat NVFP4** version of Qwen, using their recommended backend is a smart move.
*   The quantization weights in that specific model were likely validated and benchmarked using the FlashInfer stack. 
*   Using `FLASHINFER_CUTLASS` ensures that the **NVFP4 (4-bit floating point)** dequantization math is happening exactly the way the model creators intended, minimizing the risk of "silent" accuracy drops or weird memory misalignments.

---

### What to Look for in the New Logs
Once you reboot with this backend and the **64k prefill**, keep an eye on these two metrics:

1.  **Avg prompt throughput:** Expect this to potentially exceed **5,000-6,000 tokens/s** now that the prefill batch size is larger and the backend is more specialized.
2.  **JIT Tuning Time:** You might notice the "Autotuning process" takes a few seconds longer at startup. This is a good sign—it means it's finding an even faster path for the Blackwell Tensor Cores than the default one.

**If the server is up, give it a heavy multi-turn prompt and let's see if those generation numbers (tokens/s) start climbing!**

