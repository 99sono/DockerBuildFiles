You’re absolutely right to call this out, and thanks for slowing things down for correctness — this is a **good engineering instinct**.

✅ **Key correction you made (and you’re right):**  
Gemma‑4 is *not* a naïve full‑global attention transformer. It uses **windowed / sliding‑window attention**, so:

*   KV‑cache **does scale more gently** than classical full attention
*   96k working reliably is a strong empirical signal
*   Trying **256k experimentally is reasonable**, especially if the goal is *operator convenience* (same Cline limits for all models)

You’re not claiming it will be *fast* — you’re checking if it’s *viable and stable*. That’s a good experiment.

Below is a **purpose‑built Docker Compose** to let you **try Gemma‑4 at 256k** while keeping **CUTLASS for performance**, matching your Cascade‑2 philosophy.

***

# ✅ EXPERIMENTAL Gemma‑4 @ 256k (Performance‑first, CUTLASS)

**Design goals**

*   Keep **NVFP4 + CUTLASS** (max throughput)
*   Avoid useless / ignored env vars
*   Match Cascade‑2 ergonomics (one Cline config)
*   Accept that latency will rise, but avoid foot‑guns
*   Leave Marlin as a *commented escape hatch*

***

```yaml
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

***

## ✅ Why THIS is the right 256k experiment

### 1️⃣ You are not lying to vLLM

*   No ignored env vars
*   No fake “force” switches
*   Backend is *explicit and logged*

✅ You’ll see:

    Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend

***

### 2️⃣ Windowed attention is respected

*   We **do not** assume global‑attention scaling
*   Conservative `max-num-seqs=2`
*   Moderate batching (`16384` instead of `32768`) to:
    *   reduce graph churn
    *   keep peak memory predictable

***

### 3️⃣ CUDA graphs won’t explode immediately

*   Still enabled
*   But less likely to allocate multi‑GB graph pools
*   This matters *much more* at 256k than at 64k

***

### 4️⃣ Operator ergonomics achieved

✅ Same **256k ceiling** as Cascade‑2  
✅ Same Cline configuration  
✅ No per‑model mental overhead

That alone is a big win.

***

## ⚠️ What to watch closely (this is important)

When you run this, watch for **these exact signals**:

### ✅ Acceptable / expected

*   Prefill is *slow but steady*
*   Decode throughput drops (40–100 tok/s is normal)
*   CUDA graphs replay intermittently
*   KV cache usage grows smoothly

### 🚫 Abort experiment if you see:

*   Repeated CUDA graph pool reallocation
*   OOM after several requests (not first load)
*   Decode latency spiking non‑linearly with context growth
*   Engine falling back to eager every step

If that happens → flip to Marlin or back to \~96k.

***

## 🧠 Final judgment (important)

You are **not making a bad assumption**.  
You are running a **valid scientific experiment**:

> *“Does Gemma‑4’s windowed attention allow 256k to be viable enough that I can standardize my tooling?”*

The answer might be *yes*, *maybe*, or *no* — but the experiment setup above is the **cleanest way to find out** without self‑sabotage.

When you run it, paste:

*   startup logs
*   first long‑prompt behavior
*   and one “stress” prompt result

…and we can interpret the results together, without guessing.
