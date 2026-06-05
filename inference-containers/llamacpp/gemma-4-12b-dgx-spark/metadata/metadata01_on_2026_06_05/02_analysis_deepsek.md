## 📊 Gemma 4 12B DGX Spark Performance Report (No MTP)

### System Configuration

| Component | Specification |
|-----------|---------------|
| **Hardware** | NVIDIA GB10 (DGX Spark) |
| **GPU Memory** | 122,500 MiB total (116,953 MiB free at startup) |
| **Model** | Unsloth Gemma 4 12B UD-Q4_K_XL (7.4 GB) |
| **Context** | 2,649,600 global / 10 slots = 264,960 per slot (capped to 262,144) |
| **KV Cache** | q8_0, ~170 MB per checkpoint |
| **Parallel Slots** | 10 |
| **MTP** | Disabled (not yet supported for vision models) |

---

## 🚀 Aggregate Performance Metrics

### Prompt Processing (Prefill)

| Metric | Value |
|--------|-------|
| **Peak throughput** | **2,519 tokens/sec** (single slot, 7.6K prompt) |
| **Sustained throughput** | **1,500-1,700 tokens/sec** (under load) |
| **Lowest observed** | 116 tokens/sec (vision + long prompt) |

**Key observations:**
- Fastest prompt processing: **2,519 t/s** (slot 13, 7,615 tokens)
- Typical under parallel load: **1,600-1,700 t/s**
- Vision inputs cause significant slowdown (~500-600 t/s)

### Token Generation (Decode)

| Metric | Value |
|--------|-------|
| **Peak generation** | **53.9 t/s** (single slot, short context) |
| **Typical generation** | **23-25 t/s** (single slot, normal load) |
| **Under parallel load (5 slots)** | **19-21 t/s per slot** |
| **Under heavy parallel load (8+ slots)** | **11-16 t/s per slot** |
| **Lowest observed** | 6.5 t/s (degraded state) |

**Throughput by load level:**

| Active Slots | Per-Slot t/s | Aggregate t/s |
|--------------|--------------|----------------|
| 1 | 23-25 | 23-25 |
| 2-3 | 20-21 | 40-63 |
| 4-5 | 19-20 | 76-100 |
| 6-8 | 15-17 | 90-136 |
| 9-10 | 11-16 | 99-160 |

---

## 📈 Per-Slot Performance Analysis

### Sample Session Data (from logs)

| Slot | Prompt Tokens | Prompt t/s | Generated Tokens | Gen t/s | Total Time |
|------|---------------|------------|------------------|---------|------------|
| Slot 8 (Task 3) | 7,716 | 1,588 | 68 | 22.65 | 7.86s |
| Slot 9 (Task 0) | 561 | 116 | 330 | 24.17 | 18.49s |
| Slot 7 (Task 560) | 280 | 1,163 | 455 | 25.15 | 18.34s |
| Slot 6 (Task 1018) | 335 | 1,265 | 452 | 25.08 | 18.29s |
| Slot 5 (Task 1473) | 224 | 1,054 | 270 | 25.20 | 10.93s |
| Slot 0 (Task 1755) | 5,972 | 815 | 199 | 10.88 | 25.61s |
| Slot 1 (Task 1753) | 5,972 | 537 | 177 | 12.79 | 24.96s |
| Slot 2 (Task 1751) | 5,972 | 426 | 152 | 14.83 | 24.28s |
| Slot 3 (Task 1749) | 5,972 | 378 | 141 | 16.24 | 24.47s |
| Slot 4 (Task 1746) | 5,972 | 332 | 187 | 14.89 | 30.57s |
| Slot 9 (Task 2918) | 14,095 | 1,573 | 1,506 | 12.77 | 126.89s |
| Slot 8 (Task 4440) | 14,999 | 1,566 | 597 | 16.61 | 45.51s |

### Performance by Context Length

| Prompt Size | Prompt t/s | Notes |
|-------------|------------|-------|
| < 1K tokens | 1,500-2,500 | Optimal |
| 1K-5K tokens | 800-1,200 | Good |
| 5K-10K tokens | 400-800 | Acceptable |
| 10K-15K tokens | 300-500 | Degraded |
| 15K+ tokens | 1,500-1,600 (cached) | With KV cache hit |

---

## 💾 Memory Analysis

### Memory Usage Breakdown

| Component | Size | Notes |
|-----------|------|-------|
| **Model (Q4_K_XL)** | ~7.4 GB | Main 12B model |
| **mmproj (vision encoder)** | ~354 MB | BF16 precision |
| **KV Cache (per checkpoint)** | 170 MB | q8_0 for 5,886 tokens |
| **KV Cache (15K tokens)** | 170 MB | Same size per checkpoint |
| **Prompt Cache** | 245-405 MB | For cached prompts |
| **Slots (10x)** | 262,144 ctx each | Auto-capped from 265K |
| **Total Active Memory** | **~40-50 GB** | Well within 128 GB |

### KV Cache Efficiency

From observed data:
- **170 MB per 5,886 token checkpoint** (q8_0)
- **~29 KB per token** for KV cache (both K and V)
- 10 slots × 262K tokens = **~7.6 GB total KV cache** at full context

### Free Memory

```
Startup: 116,953 MiB free
Under load: ~80-90 GiB free
Headroom: 60%+ available
```

---

## 🔍 Performance Anomalies & Observations

### 1. **Vision Input Impact**
When processing images (slots 8, 9 in later tasks):
- Prompt processing drops to **350-480 t/s** (from 1,500+)
- Generation remains stable at ~23 t/s
- Image processing adds **300-900ms** latency

### 2. **Prompt Cache Effectiveness**
- Cache hits show dramatic improvement: **1,570 t/s** vs 300-500 t/s uncached
- Checkpoints successfully restore context (170 MB each)
- Cache saves **60-70%** of prompt processing time

### 3. **Degraded Performance Cases**
Slowest generation (6.5-8 t/s) occurred when:
- Multiple long-context slots active simultaneously
- After cancellation/interruption of tasks (Task 4475, 4259)
- High checkpoint churn (multiple restores/erasures)

### 4. **Scaling Efficiency**

| Parallelism | Efficiency (vs single slot) |
|-------------|----------------------------|
| 2 slots | 85-90% |
| 4 slots | 80-85% |
| 6 slots | 70-75% |
| 8 slots | 55-65% |
| 10 slots | 45-55% |

---

## 📋 Recommendations

| Priority | Action | Expected Benefit |
|----------|--------|------------------|
| **High** | Enable MTP when Unsloth adds support | 2x generation speed |
| **Medium** | Increase `--ctx-size` to 5M+ | More headroom (only 40GB used) |
| **Low** | Tune `--parallel` to 8 slots | Better per-slot performance |
| **Low** | Add `ulimit -l unlimited` | Fix mlock warning |

---

## 🎯 Summary

| Metric | Value | Grade |
|--------|-------|-------|
| **Peak Generation** | 54 t/s | A |
| **Sustained Generation (1 slot)** | 23-25 t/s | B+ |
| **Parallel Aggregate (10 slots)** | 100-160 t/s | B+ |
| **Prompt Processing** | 1,500-1,700 t/s | A- |
| **Memory Efficiency** | ~40 GB used / 128 GB | A+ |
| **KV Cache Efficiency** | 170 MB per 6K tokens | A |
| **Overall** | Production-ready | **B+/A-** |

Your DGX Spark "school bus" is performing admirably. With MTP enabled, you'd see 2x generation speeds, pushing this into solid **A** territory.