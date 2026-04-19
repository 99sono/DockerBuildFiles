The error you're seeing—`unrecognized arguments`—happens because the standard `vllm` entrypoint doesn't automatically map those flags if it's defaulting to a specific subcommand (like `run-batch`) or if the CLI structure has shifted in the `nightly` build you are using.

In the 2026 `nightly` builds of vLLM, the preferred way to enable **EAGLE-3** is via the unified `--speculative-config` flag or by ensuring you are explicitly calling the `serve` subcommand.

### The Fix: Update your Docker `command`
Update your `command` block to use the **JSON-style configuration** which vLLM now uses to handle complex speculative setups like EAGLE-3.

```yaml
    command:
      - "serve" # Explicitly call the serve subcommand
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      # --- UPDATED FOR EAGLE-3 ---
      - "--speculative-method"
      - "eagle"
      - "--speculative-model"
      - "RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3"
      - "--num-speculative-tokens"
      - "3" # Red Hat benchmarks suggest 2-3 is the sweet spot for Gemma-4
      # ---------------------------
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

### Why the error occurred:
1.  **Subcommand requirement:** The `vllm` image often defaults to a generic entrypoint. By adding `"serve"` as the first argument, you ensure the CLI parser recognizes the serving-specific flags like `--speculative-model`.
2.  **EAGLE vs EAGLE-3:** While the model is named EAGLE-3, the `--speculative-method` in vLLM is typically just `eagle`. The engine detects the version from the model weights.
3.  **The "Sweet Spot":** Recent Red Hat performance data for Gemma-4 (April 2026) indicates that while the hardware supports 5 tokens, **3 tokens** usually provides the best balance between speedup and verification overhead. 



### Memory Considerations for Gemma-4
Since you are running at a massive **98k context window**:
* **The KV Cache Tax:** As discussed, the draft model doesn't double the cache, but it does require "lookahead" slots. With 3 speculative tokens, the verifier needs to reserve 3 extra slots per sequence during the forward pass.
* **WSL Warning:** Your logs show `Using 'pin_memory=False' as WSL is detected`. This indicates you are on Windows. WSL has a known overhead with GPU memory paging; if you hit "Out of Memory" errors even at 85% utilization, try disabling `--enable-chunked-prefill` as it can occasionally spike memory during long context processing.