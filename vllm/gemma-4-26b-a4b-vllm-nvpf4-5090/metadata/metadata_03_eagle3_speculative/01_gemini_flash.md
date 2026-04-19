To enable speculative decoding with the **EAGLE-3** speculator for your **Gemma-4-26B-A4B-it** service, you need to append specific flags to your `vLLM` command. 

### Enabling Speculative Decoding in Docker Compose

You will use the `--speculative-model` flag to point to the EAGLE-3 draft model and `--num-speculative-tokens` to define the lookahead window (typically 5 for EAGLE-3).

Update your `command` block in the `docker-compose.yml` like this:

```yaml
command:
  - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
  - "--served-model-name"
  - "gemma-4-26b-it-nvfp4"
  # --- ADDED FOR SPECULATIVE DECODING ---
  - "--speculative-model"
  - "RedHatAI/gemma-4-26B-speculator-eagle-3" # Check HF for exact draft model slug
  - "--num-speculative-tokens"
  - "5"
  - "--use-v2-block-manager" # Required for some speculative configurations in vLLM
  # --------------------------------------
  - "--host"
  - "0.0.0.0"
  - "--port"
  - "8000"
  - "--gpu-memory-utilization"
  - "0.85" 
  - "--max-model-len"
  - "98304"
  - "--kv-cache-dtype"
  - "fp8_e4m3"
  - "--quantization"
  - "compressed-tensors"
  - "--trust-remote-code"
```

---

### Does it double the KV Cache?

The short answer is **no, it does not double the KV cache**, but there is a small memory "tax."

1.  **Shared vs. Separate:** In standard **Draft Model** speculative decoding, the draft model is a separate, smaller transformer. It requires its **own KV cache** to function. However, because the draft model (0.9B) is significantly smaller than the target model (26B/3.8B active), its KV cache footprint is proportionally tiny.
2.  **The EAGLE-3 Advantage:** EAGLE-3 is an "architectural" speculator. Instead of being a completely independent model with its own full-scale KV cache, it often reuses the **hidden states** (the internal "thoughts") of the main model from previous layers.
3.  **Memory Impact:** * **Main KV Cache:** Remains the same size (based on your `98k` context and `fp8` type).
    * **Draft KV Cache:** vLLM allocates a separate, much smaller pool for the speculator. For a 0.9B model, this is usually negligible (often < 5% of the total memory).
    * **The "Draft Window" overhead:** During the verification step, the main model processes $N$ tokens at once. This requires enough temporary workspace in the main KV cache to hold those $N$ "speculated" tokens simultaneously before they are confirmed or rejected.

> [!TIP]
> Since you are pushing a **98k context** on a single GPU with **0.85 utilization**, keep an eye on your OOM (Out of Memory) errors. Speculative decoding increases the "per-request" memory overhead slightly. If it crashes, drop `--gpu-memory-utilization` to `0.80` or reduce `--max-num-seqs` to `1`.

### Summary Table: Resource Impact

| Feature | Memory Impact | Logic |
| :--- | :--- | :--- |
| **Target Model KV** | High (Primary) | Stores the `98k` context history. |
| **Draft Model KV** | Very Low | Only needs to store small states for the 0.9B drafter. |
| **Parallel Verification** | Marginal | Requires space for `num_speculative_tokens` (e.g., 5) during the check. |
| **Total Overhead** | ~5-10% extra | Mostly due to the draft model weights and its minor cache. |