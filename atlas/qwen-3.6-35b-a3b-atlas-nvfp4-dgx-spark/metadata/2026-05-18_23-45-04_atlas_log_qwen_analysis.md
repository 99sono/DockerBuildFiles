# Atlas Qwen3.6-35B-A3B NVFP4 — Optimization Analysis

**Date:** 2026-05-18  
**Hardware:** DGX Spark (GB10, 128 GB UMA)  
**Model:** RedHatAI/Qwen3.6-35B-A3B-NVFP4

---

## Problem: GODZILLA Prefill Hurts Decode Speed

Increasing `--max-prefill-tokens` to 65536 (GODZILLA mode) improved TTFT on long
prompts but made decode slower due to the oversized buffer arena consuming GPU memory
that decode needs.

### Buffer Arena Comparison (from Atlas logs, line 246 vs 260)

| max-prefill-tokens | Buffer Arena | GDN Prefill Reserve | KV Cache Blocks | KV Cache Total | Decode Speed |
|---|---|---|---|---|---|
| 8192 (default) | 8200 tok × 1512.7 MB (~1.5 GB) | 258 MB | 225325 | 39.1 GB | ~60 tok/s |
| **16384** | ~16K tok × ~3 GB | ~516 MB | ~more blocks | more KV | expected ~55-60 tok/s |
| 65536 (GODZILLA) | 65544 tok × 11981.9 MB (~12 GB) | 2064 MB | 199018 | 34.5 GB | ~50 tok/s |

The 65K arena is sized for the worst case. With typical prompts at ~14-15K tokens,
the buffer sits mostly empty but the memory reservation stands, reducing KV cache
capacity and decode bandwidth.

### Prefix Cache Issue (observed line 337)

```
Prefix cache hit: 12320 tokens but no SSM snapshot — recomputing all KV
```

Even with `--enable-prefix-caching`, SSM snapshots aren't retained between different
sessions, so repeated requests with common prefixes still recompute all KV. This
limits the real benefit of aggressive prefill chunking on repeat traffic.

---

## Changes Made

### 1. `--max-prefill-tokens 65536` → `16384`

Rationale: typical prompts are ~14K tokens. 16K covers them in a single pass,
doubling the default while keeping the buffer arena at ~3 GB instead of ~12 GB.
Freed memory goes to KV cache blocks for better concurrency and decode speed.

### 2. `--gpu-memory-utilization 0.65` → `0.70`

Rationale: with a smaller buffer arena and pure NVFP4 KV cache (no BF16 high-
precision layers), there's headroom to increase utilization. The extra ~5% (~6.4 GB
on 128 GB) translates to more KV blocks and higher concurrent request capacity.
0.70 remains conservative, leaving room for system overhead.

### 3. `--kv-high-precision-layers auto` → **disabled** (commented out)

Rationale: keeping first/last 2 layers in BF16 adds memory overhead without clear
benefit on the workloads we're running. Pure NVFP4 across all KV cache layers saves
the ~2 GB that 4 BF16 boundary layers would consume. The commented-out block remains
in docker-compose.yml for easy re-enablement if coherence issues appear on long
outputs (>32K tokens).

---

## Expected Results

- Buffer arena: ~3 GB (down from ~12 GB)
- KV cache blocks: increase (more memory available)
- Decode speed: should return to ~55-60 tok/s range
- TTFT on 14K prompt: still improved over 8K default, slightly slower than 65K but
  the trade-off is favorable because decode is where most time is spent
- Concurrent capacity: higher due to more KV blocks + 0.70 utilization

## Risk & Watch List

- **Pure NVFP4 coherence:** Atlas warns NVFP4 without high-precision layers may lose
  coherence at long context. Monitor for hallucination or quality degradation on
  outputs exceeding 32K tokens. If observed, re-enable `--kv-high-precision-layers auto`.
- **Very long prompts (>16K):** Will require chunked prefill (multiple iterations).
  TTFT will be slower than 65K mode but still faster than 8K default.
- **Memory pressure:** At 0.70 utilization (~90 GB), there's still headroom. If OOM
  occurs, reduce to 0.65 or re-enable high-precision layers.

---

## Reference: Previous Config (65K GODZILLA)

See `2026-05-18_23-45-04_atlas_log.md` for the full Atlas startup log with 65K
prefill and high-precision layers enabled. Key lines:
- Line 260: buffer arena allocation (65544 tok × 11981.9 MB)
- Line 173: GDN prefill reserve (2064 MB)
- Line 132: KV cache total (199018 blocks, 34.5 GB)
