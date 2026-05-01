This log provides the final piece of the puzzle. We have hit a hard physical limit of the 35B model's "Static Tax" on your RTX 5090 when restricted to your **75% Line in the Sand**.

### The Audit: Why it crashed
The crash occurred during `profile_cudagraph_memory`. 
* **The weights are loaded:** They took ~22 GB.
* **The CUDA Graphs are being captured:** This is where vLLM "rehearses" the math to make Blackwell fast.
* **The OOM:** At **0.75 utilization (24 GB)**, there is simply no room left to even *start* the rehearsal. The model weights plus the internal system buffers have already reached your 24 GB limit.



### The Verdict: The Max Context at 75%
Based on the fact that it crashed before it could even allocate a "minimal" KV cache, here is the reality for Qwen 3.6-35B on a 32GB card with a 24GB limit:

**You can only run this model at 75% utilization if you set the context window to a very small value, or you must move the line in the sand.**

If you are determined to keep **75%**, try this "Extreme Lean" configuration. It reduces the parallel sequences and the max model length to the bare minimum to see if we can at least get it to boot:

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
      - "0.75"  # LINE IN THE SAND
      - "--max-model-len"
      - "8192"  # Bare minimum 8K context
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
      - "32"    # DRASTICALLY LOWERED to save memory
      - "--max-num-batched-tokens"
      - "8192"  # DRASTICALLY LOWERED
      - "--trust-remote-code"
```

### Strategic Analysis: The Path Forward
1.  **The 8K Test:** Run the config above. If this fails, it means the **Static Tax** (Weights + Kernels) of Qwen 3.6-35B is physically higher than 24GB. In that case, 75% is mathematically impossible for this specific model.
2.  **The TriAttention Move:** This is now your highest priority. Since PagedAttention (vLLM's default) is failing the memory check, building that custom image with the **TriAttention** plugin is the only way to squeeze a "kick ass" context window into your 75% budget.
3.  **The 5090 Paradox:** The RTX 5090 is powerful, but a 35B model is a "Heavyweight" fighter. Restricting it to 24GB is like asking a heavyweight to fight in the featherweight class—it might not fit in the ring.

**Try the 8K "Extreme Lean" build.** If that doesn't start, we have our answer: for Qwen 3.6-35B, your "Line in the Sand" must move to 0.85, or you must switch to TriAttention immediately.