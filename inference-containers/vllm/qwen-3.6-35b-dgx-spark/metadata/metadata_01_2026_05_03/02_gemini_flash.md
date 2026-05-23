This is an incredible success. Seeing **4,987 tokens/s** on the prefill and **2.1 million tokens** of KV cache headroom confirms that the DGX Spark is not just working—it is bored. 

You have essentially built a high-performance serving platform but are currently driving it like a commuter car. Here is my take on your proposed upgrades and why Godzilla is about to get much faster.

---

### 1. The Prefill Speed Demon (`--max-num-batched-tokens`)
You currently have this at `8192`. On the Grace Blackwell (GB10) with its unified memory, the overhead for massive prefills is significantly lower than on a discrete PCIe card.
*   **The Move:** Increase this to **`32768`** or even **`65536`**.
*   **The Why:** This will make that initial "thinking" phase for large documents almost instantaneous. Since you have 128GB of unified RAM, you aren't fighting for a tiny 24GB or 32GB VRAM bucket.

### 2. The 256k Context Window
The logs show you have **82.42 GiB** of available KV cache memory. 
*   **The Math:** At `fp8_e4m3`, a 35B model (A3B active) uses very little memory per token. 
*   **The Move:** Change `--max-model-len` to **`262144`** (256k).
*   **The Impact:** Even at 256k, you will still have room for high concurrency.

### 3. Parallel Decode (`--max-num-seqs`)
You noticed the **36.9 tokens/s** generation speed. On the Spark, the "per-token" latency is tied to the memory bandwidth of the Grace Blackwell chip.
*   **The Move:** Increase `--max-num-seqs` to **`16`** or **`32`**.
*   **The Result:** Your *individual* stream might stay at ~37 tokens/s, but your *total system throughput* will jump significantly. The Spark excels at handling many users at once without slowing down.

---

### Updated "Phase 2" Configuration Patch
I recommend these specific changes for your `docker-compose.yml` to truly test the limits of the Spark:

```yaml
      # --- MEMORY & CONTEXT (Godzilla Mode) ---
      - "--gpu-memory-utilization"
      - "0.85"  # Dropped slightly to leave more room for System/CPU in the UMA
      - "--max-model-len"
      - "262144" # 256k Context
      - "--max-num-seqs"
      - "16"     # Allow 16 parallel users

      # --- BATCHING / PREFILL (The Speed Unlock) ---
      - "--max-num-batched-tokens"
      - "32768"  # Massive prefill for high-speed document ingestion

      # --- BACKEND ALIGNMENT ---
      - "--moe-backend"
      - "flashinfer_cutlass" # Aligning with RedHat's specific recommendation
```

### Why generation feels slower than the 5090
The RTX 5090 is a high-clocked "Ferrari" optimized for single-sequence burst speed. The DGX Spark is a throughput beast. It's like comparing a motorcycle to a bus; the motorcycle is faster for one person, but the bus moves 50 people at almost the same speed. To see the Spark shine, you need to throw **parallel requests** at it.

**Would you like to apply this "Godzilla Mode" patch and see how the KV cache allocation looks in the logs?**