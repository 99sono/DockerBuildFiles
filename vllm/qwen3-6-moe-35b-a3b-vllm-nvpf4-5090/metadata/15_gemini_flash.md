Understood. We are drawing a **strict line in the sand at 75% utilization**. This is a smart move for system stability, as it guarantees roughly **8GB of VRAM** remains free for your OS, WSL2 overhead, and display, while leaving **24GB** for the model.

However, here is the technical reality: **Qwen 3.6-35B at 75% utilization (24GB) is mathematically incapable of supporting a 64K+ context window.**

### The "Line in the Sand" Math
1.  **Model Weights (NVFP4):** ~21.9 GB (This is the physical floor; you can't go lower).
2.  **Blackwell CUDA Kernels/Activation Buffers:** ~1.5 GB.
3.  **Total "Static" Load:** **~23.4 GB**.

If your limit is **75% (24 GB)**, you only have **0.6 GB** left for the KV Cache. 

### The Strategy: Find the Maximum Ceiling
We will set the limit to **0.75** and start with a very conservative context. We will then look at the logs to see exactly how much "surplus" VRAM we have, and we will increment the context window until we hit the 24GB ceiling perfectly.

#### Step 1: The "Probe" Configuration (32K Context)
Let's start at **32,768**. This should fit within your 75% limit.

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
      - "0.75"  # STRICT LINE IN THE SAND
      - "--max-model-len"
      - "52768" # Starting probe point
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
      - "256"
      - "--max-num-batched-tokens"
      - "32768"
      - "--trust-remote-code"
```

### How we "squeeze" the context:
1.  **Run the above.**
2.  **Look for this line in the logs:** `Available KV cache memory: X.XX GiB`.
3.  **The Formula:** * Qwen 3.6-35B (Hybrid) needs roughly **0.6 GB per 32,768 tokens** (in FP8).
    * If the log says you have **1.2 GB** available, we can safely bump `--max-model-len` to **65536**.
    * If the log says you have **0.3 GB** available, we are at the limit.

### Why Nemotron could do 100K at 75% and Qwen can't:
Nemotron-Cascade-2-30B is a much "thinner" model in terms of parameter depth. Qwen 3.6-35B is physically "chunkier"—it has more weights to store. You are paying a "Weight Tax" of about 5GB more for Qwen than you did for Nemotron. That 5GB difference is exactly what would have provided your extra 60K of context.

**Try the 32K probe with the 0.75 limit.** Post the log line regarding "Available KV cache memory," and I will tell you the exact maximum number of tokens you can set to hit that 75% mark without crossing it.