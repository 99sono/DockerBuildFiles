# Qwen3.6-35B-A3B PrismaQuant Performance Analysis

## Model Configuration

- **Model**: `rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm`
- **Quantization**: PrismaQuant 4.75-bit (compressed-tensors)
- **vLLM Version**: 0.20.2
- **Hardware**: DGX Spark (Grace Blackwell ARM64)
- **Speculative Decoding**: MTP with `num_speculative_tokens=3`
- **KV Cache Dtype**: fp8
- **Attention Backend**: FlashInfer

---

## ⏱️ Startup Timeline

| Phase | Duration | Details |
|---|---|---|
| Model download | ~79 sec | HF transfer pull |
| Weight loading | ~171 sec | 6 safetensors shards |
| Draft model loading | ~22 sec | MTP speculative model |
| torch.compile | ~64 sec | Main + draft graph compilation |
| CUDA graph capture | ~2 sec | 13 capture sizes |
| **Total cold start** | **~6 min** | 21:03 → 21:10 |

---

## 📊 Token Throughput Metrics

### Prompt (Prefill) Throughput

| Request | Time | Avg Prompt Throughput | Notes |
|---|---|---|---|
| #1 | 21:11 | **1,503.9 tokens/s** | Short prompt |
| #2 | 21:14 | **786.1 tokens/s** | Medium prompt |
| #3 | 21:14 | **1,110.3 tokens/s** | |
| #4 | 21:15 | **1,219.4 tokens/s** | |
| #5 | 21:15 | **806.0 tokens/s** | |
| #6 | 21:15 | **855.5 tokens/s** | |
| #7 | 21:15 | **977.8 tokens/s** | |
| #8 | 21:19 | **507.2 tokens/s** | Longer prompt |
| #9 | 21:20 | **411.0 tokens/s** | Longer prompt |
| #10 | 21:26 | **997.4 tokens/s** | |
| #11 | 21:28 | **722.7 tokens/s** | |
| #12 | 21:32 | **716.2 tokens/s** | |

**Average prefill: ~850-900 tokens/s** (varies inversely with prompt length)

### Generation (Decode) Throughput

| Request | Time | Avg Generation Throughput | Notes |
|---|---|---|---|
| #1 | 21:11 | **50.3 tokens/s** | Baseline |
| #2 | 21:14 | **22.4 tokens/s** | Short output |
| #3 | 21:14 | **46.8 tokens/s** | |
| #4 | 21:15 | **48.9 tokens/s** | |
| #5 | 21:15 | **71.0 tokens/s** | Peak |
| #6 | 21:15 | **60.9 tokens/s** | |
| #7 | 21:15 | **40.6 tokens/s** | |
| #8 | 21:15 | **49.6 tokens/s** | |
| #9 | 21:15 | **50.0 tokens/s** | |
| #10 | 21:16 | **68.2 tokens/s** | |
| #11 | 21:16 | **65.7 tokens/s** | |
| #12 | 21:16 | **43.5 tokens/s** | |
| #13 | 21:19 | **25.9 tokens/s** | Long output |
| #14 | 21:20 | **41.6 tokens/s** | |
| #15 | 21:26 | **25.7 tokens/s** | Long output |
| #16 | 21:28 | **31.9 tokens/s** | |
| #17 | 21:32 | **54.2 tokens/s** | |

**Average decode: ~45-50 tokens/s** per request

---

## 🔬 Speculative Decoding Metrics (MTP n=3)

### Summary Statistics

| Metric | Range | Best | Worst |
|---|---|---|---|
| **Mean acceptance length** | 2.43 - 3.79 | 3.79 | 2.43 |
| **Avg Draft acceptance rate** | 47.6% - 93.1% | 93.1% | 47.6% |
| **Per-position acceptance** | See below | | |

### Per-Position Acceptance Rates

| Position | Best | Worst | Typical |
|---|---|---|---|
| **Position 1** | 96.8% | 71.8% | ~85% |
| **Position 2** | 93.6% | 48.7% | ~75% |
| **Position 3** | 88.8% | 29.5% | ~65% |

### Key Speculative Decoding Insights

- **Mean acceptance length ~3.0** means each spec step accepts ~3 tokens on average
- Since `num_speculative_tokens=3`, the draft model is accepting all 3 speculative tokens about half the time
- **Position 1 acceptance ~85%**: the draft model's first guess is usually correct
- **Position 2 acceptance ~75%**: drops but still useful
- **Position 3 acceptance ~65%**: weakest but still contributes meaningfully

### Effective Throughput with Speculative Decoding

| Metric | Range |
|---|---|
| **Accepted throughput** | 28-49 tokens/s (main model accepted) |
| **Drafted throughput** | 41-64 tokens/s (draft proposals) |

The draft model generates tokens faster than the main model accepts them — the MTP draft is doing its job well.

---

## 💾 Memory & System Stats

| Parameter | Value |
|---|---|
| **GPU KV cache capacity** | 5,463,232 tokens |
| **Available KV cache memory** | 64.69 GiB |
| **GPU memory utilization** | 80% |
| **Max concurrency (262K tokens)** | 20.84x |
| **Prefix cache hit rate** | Grew from 0% → 84% |

---

## 🎯 Overall Summary

| Metric | Value |
|---|---|
| **Prefill speed** | ~400-1,500 tokens/s (depends on prompt length) |
| **Decode speed** | ~22-71 tokens/s (avg ~45-50 tok/s) |
| **Spec acceptance rate** | ~63-93% avg draft acceptance |
| **Mean acceptance length** | ~3.0 tokens per spec step |
| **Cold start time** | ~6 minutes |

---

## 🔗 Credits

This docker-compose02.yml configuration was adapted from the **Spark Arena leaderboard**:
- **Source**: https://spark-arena.com/leaderboard
- **Submitted by**: Sean Williams — https://forums.developer.nvidia.com/u/seanthomaswilliams

The PrismaQuant 4.75-bit quantization with MTP speculative decoding (n=3) and FlashInfer attention backend represents an optimized configuration for the DGX Spark (Grace Blackwell) platform.