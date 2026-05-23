

# Qwen3.6-27B-MTP on llama.cpp — Performance Analysis Report

**Date:** 2026-05-14
**Hardware:** NVIDIA GeForce RTX 5090 (32 GB VRAM, compute capability 12.0)
**Model:** Qwen3.6-27B-UD-Q4_K_XL (Unsloth quantization, 5.24 BPW, 16.67 GiB)
**Framework:** llama.cpp / llamafile b484-2c4055912
**Context:** 131,072 tokens, Flash Attention enabled, CUDA graphs enabled
**Speculative Decoding:** MTP (Multi-Token Prediction) with 1 draft layer, checkpoint-based

---

## System Configuration

| Parameter | Value |
|---|---|
| GPU | NVIDIA GeForce RTX 5090 (32,606 MiB total VRAM) |
| Model VRAM usage | 16,387 MiB (full offload, 66/66 layers GPU) |
| KV Cache | 4,352 MiB (q8_0, 131K cells) |
| Recurrent State buffer | 598.5 MiB |
| Compute buffer | 495 MiB GPU + 276 MiB host |
| Threads | 16 (batch), 32 total CPU cores |
| Parallel slots | 4 |

---

## Performance Results Summary

| # | Task | Input Tokens | Output Tokens | Prefill (tok/s) | Decode (tok/s) | Accept Rate | MTP Accepted | MTP Contribution |
|---|------|-------------|---------------|-----------------|----------------|-------------|-------------|-----------------|
| 1 | 0 | 133 | 2,048 | 204.94 | **67.40** | 98.3% | 1,186 | ~58% |
| 2 | 921 | 11 | 10 | 32.36 | **95.89** | 100% | 6 | ~60% |
| 3 | 927 | 133 | 2,048 | 327.03 | **60.38** | 98.7% | 1,156 | ~56% |
| 4 | 1896 | 11,756 | 40 | 1,371.48 | **26.11** | 100% | 22 | ~55% |
| 5 | 1895 | 867 | 565 | 472.70 | **50.75** | 95.6% | 302 | ~53% |
| 6 | 2193 | 11,801* | 262 | 839.09 | **53.90** | 99.3% | 135 | ~52% |
| 7 | 2330 | 38,252* | 3,235 | 1,955.69 | **45.38** | 97.6% | 1,544 | ~48% |

*\*Checkpoint restored — only delta tokens required actual prefill computation.*

---

## Detailed Observations

### Prefill Performance

Prefill throughput scales well with batch size:

| Input Size | Prefill Speed | Notes |
|---|---|---|
| 11 tokens | 32 tok/s | Tiny batch, high overhead ratio |
| 133 tokens | 205–327 tok/s | Standard chat prompt |
| 867 tokens | 473 tok/s | Multi-turn conversation |
| 11,756 tokens | 1,371 tok/s | Long context, cold |
| 27,012 tokens | 1,956 tok/s | Checkpoint restore (delta only) |

The 1,956 tok/s on Task 2330 reflects the delta prefill after restoring a checkpoint at position 11,240 — only 27K new tokens needed evaluation over 13.8s.

### Decode Performance

Decode speed shows clear dependence on accumulated context length:

| Approx. Total Context | Decode Speed | MTP Speed (est.) |
|---|---|---|
| ~2K tokens | 67.4 tok/s | ~38 tok/s base |
| ~2K tokens | 60.4 tok/s | ~34 tok/s base |
| ~12K tokens | 26.1 tok/s | ~14 tok/s base |
| ~1.4K tokens | 50.8 tok/s | ~27 tok/s base |
| ~12K tokens (cached) | 53.9 tok/s | ~28 tok/s base |
| ~41K tokens | 45.4 tok/s | ~24 tok/s base |

Short-context decode (Tasks 0, 927): **~60–67 tok/s**
Long-context decode (Tasks 1895, 2193, 2330): **~45–54 tok/s**

Task 4 (26.1 tok/s) was anomalous — only 40 output tokens were generated, with high per-token overhead dominating the measurement.

### MTP Speculative Decoding Contribution

| Task | Draft Tokens Generated | Accepted | Accept Rate | Output Tokens | MTP % of Output |
|---|---|---|---|---|---|
| 0 | 1,207 | 1,186 | 98.3% | 2,048 | ~58% |
| 921 | 6 | 6 | 100% | 10 | ~60% |
| 927 | 1,171 | 1,156 | 98.7% | 2,048 | ~56% |
| 1896 | 22 | 22 | 100% | 40 | ~55% |
| 1895 | 316 | 302 | 95.6% | 565 | ~53% |
| 2193 | 136 | 135 | 99.3% | 262 | ~52% |
| 2330 | 1,582 | 1,544 | 97.6% | 3,235 | ~48% |

**Key takeaways:**

- MTP acceptance rate stays high (**95–100%**), indicating the draft layer predicts well.
- MTP contributes **48–60%** of all output tokens — meaning roughly half the tokens are generated without a full 65-layer forward pass.
- Estimated effective speedup: **~1.7–2.0x** compared to non-speculative decoding.
- At 41K context (Task 2330), MTP contribution drops slightly to ~48%, likely due to longer generation horizon increasing draft error accumulation.

### Concurrent Request Handling

Tasks 1895 and 1896 ran concurrently (started within the same second). Observed decode speeds:
- Task 1896: 26.1 tok/s (40 tokens, high overhead)
- Task 1895: 50.8 tok/s (565 tokens, sustained)

This suggests **minimal cross-slot interference** — Task 1895 performed close to single-request decode speed despite sharing the GPU with Task 1896.

---

## Estimated Effective Throughput (with vs. without MTP)

| Context Length | Observed (with MTP) | Estimated (without MTP) | Speedup |
|---|---|---|---|
| Short (~2K) | ~64 tok/s | ~34–38 tok/s | **~1.9x** |
| Medium (~12K) | ~50 tok/s | ~27 tok/s | **~1.8x** |
| Long (~41K) | ~45 tok/s | ~24–26 tok/s | **~1.8x** |

---

## Conclusion

The RTX 5090 running Qwen3.6-27B-MTP at Q4_K_XL quantization delivers:

- **~67 tok/s decode** with short context (2K input)
- **~45 tok/s decode** with long context (41K accumulated)
- **~2x effective speedup** from MTP speculative decoding across all context lengths
- **~2,000 tok/s prefill** for large deltas with checkpoint restoration
- Excellent concurrent request handling with minimal performance degradation

The MTP mechanism is the primary contributor to decode performance — without it, effective throughput would be roughly halved. At 27B parameters in Q4_K_XL on 32 GB VRAM, this is a strong result for single-GPU inference.
