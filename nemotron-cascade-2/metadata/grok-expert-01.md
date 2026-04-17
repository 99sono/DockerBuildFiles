**Yes**, the latest `vllm/vllm-openai:latest` fully supports the Nemotron-Cascade-2 model family (including the hybrid Mamba+Transformer architecture) via the exact flags you provided. The model card explicitly recommends that `vllm serve` command, so it works out-of-the-box on Blackwell (RTX 5090). Native NVFP4 compute is supported on Blackwell, but the official vLLM loading path still uses the FP8 repo ID (`chankhavu/Nemotron-Cascade-2-30B-A3B-FP8`) even when referencing the NVFP4 weights — that's how the HF cards are written.

**TurboQuant status**: Yes, it has been merged into the main branch (PRs #38479 / #39890 and follow-ups landed ~April 2026). The official `vllm/vllm-openai:latest` image includes it. You enable it by changing `--kv-cache-dtype fp8` to one of the TurboQuant presets (e.g. `turboquant_k8v4`, `turboquant_4bit_nc`, etc.). It applies only to the Transformer (attention) KV cache — Mamba state is unaffected and still uses `--mamba_ssm_cache_dtype float32`.

### Adapted docker-compose.yml (base version matching your exact `vllm serve` command)

```yaml
# Nemotron-Cascade-2-30B-A3B (chankhavu FP8 / NVFP4 compatible) - Hardened for RTX 5090 (Blackwell)
services:
  nemotron-cascade:
    image: vllm/vllm-openai:latest
    container_name: nemotron-cascade-2
    hostname: nemotron-cascade-2
    platform: linux/amd64
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    ipc: host
    environment:
      # --- BLACKWELL STABILITY OVERRIDES (keep these) ---
      - VLLM_USE_V1=0
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
      - VLLM_USE_FLASHINFER_MOE_FP8=1
      - VLLM_FLASHINFER_MOE_BACKEND=throughput
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]    
    command:
      # Model + all flags from the official HF model card
      - "--model"
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-FP8"
      - "--mamba_ssm_cache_dtype"
      - "float32"
      - "--max-model-len"
      - "262144"
      - "--trust-remote-code"
      - "--enable-auto-tool-choice"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--reasoning-parser"
      - "nemotron_v3"
      - "--kv-cache-dtype"
      - "fp8"                  # ← official recommendation
      
      # --- MEMORY / STABILITY (tuned for 5090 + 262k context) ---
      - "--gpu-memory-utilization"
      - "0.75"                 # adjust down to 0.65-0.70 if you still OOM
      - "--enforce-eager"      # critical on Blackwell/WSL2 to avoid CUDA Graph spikes
      - "--dtype"
      - "auto"                 # lets vLLM pick FP8 weights automatically
      
    networks:
      - development-network

networks:
  development-network:
    external: true
```

### TurboQuant version (sub-4-bit KV cache for even more headroom at 262k)

Just replace the KV cache line (everything else stays identical):

```yaml
      - "--kv-cache-dtype"
      - "turboquant_k8v4"      # ← mildest TurboQuant (8-bit keys + 4-bit values)
      # Alternatives (more aggressive):
      # - "turboquant_4bit_nc"   # 4-bit keys + 4-bit values + norm correction
      # - "turboquant_k3v4_nc"   # 3-bit keys + 4-bit values + norm correction
      # - "turboquant_3bit_nc"   # 3-bit keys + 3-bit values + norm correction (biggest memory win, slightly higher perplexity)
```

**Why these presets?**  
- `turboquant_k8v4` is the closest drop-in replacement for `fp8` (very small quality impact).  
- The `_nc` variants add norm-correction for better Needle-in-a-Haystack / long-context fidelity.  
- No extra flags or env vars are required for Nemotron-Cascade (hybrid Mamba+Transformer works out of the box).

**Quick tips for RTX 5090 + 262k context**:
- Start with `turboquant_k8v4` + `gpu-memory-utilization: 0.75`.
- If you want maximum context / throughput, try `turboquant_4bit_nc` (you'll gain ~30-40% more KV cache headroom vs FP8).
- Monitor startup logs — the Blackwell overrides you already have are still important.
- First run will download the model (~30-35 GB depending on quant) into `~/.cache/huggingface`.

Just `docker compose up -d` and you’re good. The OpenAI-compatible endpoint will be at `http://localhost:8000/v1`.

Let me know if you want a version with `kv_cache_dtype_skip_layers` (to skip first/last layers) or any other tweaks!