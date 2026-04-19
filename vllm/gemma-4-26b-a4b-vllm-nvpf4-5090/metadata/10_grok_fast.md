The crash is caused by this exact error:

```bash
ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin'].
```

**Why this happens:**

- Your model (`RedHatAI/gemma-4-26B-A4B-it-NVFP4`) uses **compressed-tensors** quantization with **NVFP4** weights on the MoE experts.
- NVFP4 MoE has a restricted set of supported backends in vLLM (see the `select_nvfp4_moe_backend` / `map_nvfp4_backend` logic). **Triton** is *not* among them — it's only valid for unquantized or certain other quantized MoE models.
- You explicitly passed `--moe-backend triton` (plus `--enable-chunked-prefill`, `--enable-prefix-caching`, etc.), so vLLM tries to honor it and fails hard during model loading (in the `Gemma4MoE` → `FusedMoE` path).

Even though you're on a very recent nightly (`0.19.2rc1.dev8+...`), the NVFP4 MoE backend restrictions are still enforced.

### Quick fix

Remove (or change) the `--moe-backend triton` flag.

Try one of these instead (start with the simplest):

1. **Let vLLM choose automatically** (recommended first try):
   ```yaml
   # remove the entire --moe-backend line
   # or explicitly:
   - "--moe-backend"
   - "auto"
   ```

2. **Explicitly use a supported backend for NVFP4** (many people succeed with this on Gemma-4 26B NVFP4):
   ```yaml
   - "--moe-backend"
   - "marlin"
   ```
   or
   ```yaml
   - "--moe-backend"
   - "cutlass"
   ```

   Some reports also mention `flashinfer_cutlass` or `flashinfer_cutedsl` working depending on the exact nightly and GPU.

### Other recommendations for this specific model

- The RedHatAI NVFP4 checkpoint **should work with `--quantization compressed-tensors`** (it auto-detects in many cases, but you can keep it).
- Keep your other Gemma-4 specific flags: `--reasoning-parser gemma4`, `--tool-call-parser gemma4`, `--trust-remote-code`.
- You're already using a high `--max-model-len` and `--kv-cache-dtype fp8_e4m3` — that's fine.
- You're on WSL (the pin_memory warning). This is known to hurt performance a bit, but it shouldn't cause this crash.
- Some community NVFP4 Gemma-4 variants (e.g. from bg-digitalservices) require `--quantization modelopt` + `--moe-backend marlin` + a patched `gemma4.py`. RedHatAI's version is designed for `compressed-tensors`, so you probably don't need the patch.

### Should you switch to a "gemma4" specialized image?

The generic `vllm/vllm-openai:nightly` you're using is usually fine, but some people building/running Gemma-4 NVFP4 on Blackwell / DGX Spark / WSL use community images (e.g. spark-vllm-docker with TF5 transformers) or Red Hat's preview images because they ship newer `transformers >= 5.5` and sometimes include Gemma-4-specific patches.

Your nightly already pulled the Gemma4 model code, so the architecture detection succeeded. The issue is purely the MoE backend incompatibility.

### What to try next (in order)

1. Remove `--moe-backend triton` (or set to `auto` / `marlin`).
2. If it still fails, add `-e VLLM_NVFP4_GEMM_BACKEND=marlin` (or `cutlass`) as an environment variable.
3. Rebuild/pull a fresher nightly if possible (the dev hash you have is recent but the ecosystem moves fast for Gemma-4).
4. If you hit scale-mapping or expert loading errors after this, you may need the community patch for `gemma4.py` (mount an updated version into the container).

This exact error has appeared in several Gemma-4 NVFP4 threads on GitHub and NVIDIA forums in April 2026. Changing the MoE backend away from `triton` resolves it in the majority of reported cases.

Let me know what happens after you remove/change the `--moe-backend` flag (and paste the new error if any). We can iterate from there.