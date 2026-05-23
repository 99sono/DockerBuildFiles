At a strict **0.80 (25.6 GB)** limit, the math is unforgiving for a 35B model. Based on your previous logs where we were short by **0.45 GB** to hit **32K**, the extra **5% (1.6 GB)** you just granted should actually make **32,768 (32K)** the new "floor."

However, to answer your question: if you want a guaranteed "boot" with zero crashes on the first try, you need to set it to **32768 (32K)**.

### The "Squeeze" Audit for 0.80 Utilization
Here is the projected memory map for your 5090 with this specific model:

* **Static Tax (Weights + Kernels):** ~23.5 GB
* **Buffer for 32K Context (FP8):** ~1.06 GB
* **Total:** **~24.56 GB**
* **Your Budget (80% of 32GB):** **25.6 GB**

**Verdict:** 32K will fit with about **1 GB of "safety slack"** left inside that 80% allocation.

### The Problem with 48K
To hit **49,152 (48K)**, the KV cache requirement jumps to roughly **1.6 GB**. Added to the static tax, you hit **25.1 GB**. While that *theoretically* fits under 25.6 GB, vLLM's memory profiler is extremely conservative. If it sees that you are within 500MB of your limit during the "warmup" phase, it triggers the OOM crash you've been seeing just to be safe.

### Recommended "Guaranteed" Command
Drop to 32K to get it running. Once it is running, we can look at the "Available KV Cache" log and see if we can "inch" it up to 40K.

```yaml
    command:
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--tensor-parallel-size"
      - "1"
      - "--gpu-memory-utilization"
      - "0.80" 
      - "--max-model-len"
      - "32768" # <--- Set to 32K for the guaranteed win
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "128" # Lowering this frees up a tiny bit of internal Mamba state memory
      - "--max-num-batched-tokens"
      - "32768"
      - "--trust-remote-code"
```

### Why does 32K feel like "garbage"?
It feels small because we are spoiled by Nemotron and Gemini, but remember: this is a **35B parameter model** running locally. 32K is roughly 24,000 words. That's a short novel. It's plenty for coding a single complex script or having a very deep technical discussion, even if it can't "read" a 500-page PDF yet.

**Does this 32K probe clear the logs?** If it does, we have officially found your baseline. From here, the only way up is the **TriAttention** plugin or **4-bit KV Cache**.