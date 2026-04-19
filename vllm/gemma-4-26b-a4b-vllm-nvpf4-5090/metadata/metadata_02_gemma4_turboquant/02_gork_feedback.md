The crash is very clear from the logs:

**Root cause:**
```
ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
```

Gemma-4 forces **TRITON_ATTN** because of its **heterogeneous head dimensions** (`head_dim=256` for sliding-window layers vs `global_head_dim=512` for global layers). TurboQuant (in this nightly) does **not** support the Triton attention backend yet for KV cache compression.

vLLM explicitly rejects the combination:
- TurboQuant works best (or only reliably) with **FlashInfer** / FlashAttention-based backends.
- But Gemma-4’s mixed head sizes make vLLM refuse FlashInfer/FlashAttention and fall back to Triton → immediate rejection when you ask for `turboquant_k8v4`.

Other relevant observations from your logs:
- TurboQuant did activate partially (`TQ: skipping layers ['0', '1', '28', '29']` for boundary protection — good sign the feature is present).
- It overrode flash_attn_version to 2 (as warned).
- The unknown env var warning for `VLLM_ATTENTION_BACKEND=FLASHINFER` shows that environment variable is no longer the correct way in recent nightlies (you now need the CLI/config way).

### What to try next (in order of likelihood to work)

**Option 1: Force FlashAttention 2 and hope it bypasses the Triton force (most promising quick test)**

Update your `docker-compose-turboquant.yml` with these changes:

```yaml
environment:
  - NVIDIA_VISIBLE_DEVICES=all
  - HF_HUB_ENABLE_HF_TRANSFER=1
  - VLLM_WORKER_MULTIPROC_METHOD=spawn
  # Remove the old VLLM_ATTENTION_BACKEND line

command:
  # ... keep everything else the same ...
  - "--kv-cache-dtype"
  - "turboquant_k8v4"
  - "--attention-config.flash_attn_version=2"   # ← Add this
  - "--enforce-eager"                          # ← Add this for first test (helps WSL2 stability)
  # Optionally also try:
  # - "--moe-backend"
  # - "marlin"
```

Then bring it up again.

**Option 2: Fall back to a more compatible KV cache dtype for now**

If Option 1 still forces Triton, change to a non-TurboQuant dtype that works with Triton:

```yaml
- "--kv-cache-dtype"
- "fp8_e4m3"        # or "fp8" 
```

(and keep `max-model-len` at 98304 or push to ~130k–150k max). This will at least start reliably.

**Option 3: Use a custom image with the community turboquant-vllm plugin (more reliable for edge cases)**

If native support keeps clashing with Gemma-4, create a minimal custom Dockerfile:

```dockerfile
FROM vllm/vllm-openai:nightly

RUN pip install --no-cache-dir "turboquant-vllm[vllm]"
```

Then in your turboquant compose file, use this new image and follow the plugin’s specific flags (usually `--kv-cache-dtype auto` + extra env vars or `--turboquant-*` flags — check its README).

### Realistic expectations right now (April 19, 2026)
- TurboQuant is still very new in mainline vLLM. The tracking issue for TurboQuant follow-ups shows ongoing work for hybrid/MoE models and better backend compatibility.
- Gemma-4’s dual-attention design is one of the hardest cases for new KV cache features.
- Many people are hitting the exact same “kv_cache_dtype not supported with TRITON_ATTN” on Gemma-4 + TurboQuant right now.

**Recommended immediate action:**
Try **Option 1** first (add `--attention-config.flash_attn_version=2` + `--enforce-eager`). It has the highest chance of letting TurboQuant activate without changing the model too much.

If that still fails with the same Triton error, switch back to your normal `fp8_e4m3` config (with `--max-model-len 98304` or a moderate bump) and wait 1–2 weeks for the next nightly/release. The TurboQuant + Gemma-4 combination is clearly not fully cooked yet.

Paste the new logs after trying the `--attention-config.flash_attn_version=2` change, and we’ll iterate from there (or move to the community plugin route).

You’re right on the bleeding edge — this is exactly why these experiments are useful. Let me know what the next run shows!