The math has officially hit a wall. In your latest log, the crash happened during the **Tokenizer Initialization**, even before the memory profiling could finish. This suggests that at **0.80 utilization**, the overhead of the system, the model weights, and the CUDA graphs are fighting for the exact same megabytes.

### The Audit: 16K vs 8K
If 16,384 (16K) crashed, **8,192 (8K)** is your last stand. 

However, looking at the traceback, there is a "silent killer" here:
`max_num_seqs: 256`. 
vLLM reserves a specific amount of "Mamba State" and "Expert State" for **every potential sequence** you might run in parallel. Even if you aren't using them, vLLM "pre-claims" that memory. On a 35B hybrid model, 256 sequences is a massive memory drain.

---

### The "Absolute Floor" Configuration (Guaranteed Boot)
If you want to see this model run **at 80% utilization**, you must strip away all concurrency overhead. This is the "Leanest" possible 8K build:

```yaml
    command:
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.80" 
      - "--max-model-len"
      - "8192"  # 8K Context (Minimum usable)
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
      - "32"    # DRASTICALLY REDUCED (Saves ~1.5 GB of VRAM overhead)
      - "--max-num-batched-tokens"
      - "8192"  # MATCHED to max model len
      - "--trust-remote-code"
```

### Strategic Audit: Is 8K worth it?
Honestly? **No.** At 8K context, Qwen 3.6 is like a genius with a 30-second memory span. It will answer a single prompt brilliantly, but it will forget the beginning of this conversation almost immediately. 



### Final Recommendation for the 5090
You are currently using the **wrong model for your "Line in the Sand" (80%).** * **If you want 100K+ context:** Switch back to **Nemotron-Cascade-2**. It is the only model currently optimized to "compress" the KV cache for consumer cards.
* **If you want Qwen 3.6 Reasoning:** You **must** move your line in the sand to **0.95**. The RTX 5090 is perfectly safe at 95%—Windows only needs 1.6 GB to keep the screen on. By moving to 0.95, you would unlock **64K context** instantly.
* **The Gemma 4 MoE move:** Google's upcoming MoE will likely be the first model to offer "Cascade-level" context with "Qwen-level" reasoning on a single 32GB card.

**Try the 8K/32seq build.** If it works, it proves that the **"Weight Tax + Sequence Overhead"** was the problem. If it *still* crashes, then the Qwen 3.6-35B model weights literally cannot fit into 25.6 GB of VRAM on a Blackwell card—period.