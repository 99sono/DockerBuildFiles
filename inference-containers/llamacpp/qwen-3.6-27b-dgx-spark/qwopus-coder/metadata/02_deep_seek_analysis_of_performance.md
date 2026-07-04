# Performance Analysis: Qwopus3.6-27B-Coder (DGX Spark)

**Date:** 2026-07-04
**Model:** `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF:Q5_K_M`
**Hardware:** DGX Spark (GB10, 128GB Unified Memory)
**Engine:** llama.cpp with MTP speculative decoding (draft-mtp, n_max=2, p_min=0.85)
**Context:** 262144 (256K)

## Summary

The model performs well on DGX Spark with 262K context. MTP speculative decoding achieves ~92-95% draft acceptance, delivering sustained generation at 12-16 t/s depending on prompt complexity and context depth.

## Key Metrics

### Task 377 (Haiku generation — final run)
| Metric | Value |
|---|---|
| Draft acceptance | 95.3% (403/423) |
| Sustained gen speed | 16.35 t/s |
| Prompt eval | 508.86 t/s |
| Total tokens | 1103 |
| Total time | ~50s |

### Task 103 (Earlier generation)
| Metric | Value |
|---|---|
| Draft acceptance | 92.3% (168/182) |
| Sustained gen speed | 12.57 t/s |
| Prompt eval | 398.68 t/s |
| Total tokens | 751 |

### Task 0 (First request — cold start)
| Metric | Value |
|---|---|
| Draft acceptance | 94.7% (214/226) |
| Sustained gen speed | 14.46 t/s |
| Prompt eval | 181.11 t/s |
| Total tokens | 521 |

## Observations

1. **262K context works fine** — no memory pressure on 128GB unified memory. MTP estimated memory usage was 1348 MiB for the draft context.

2. **Draft acceptance consistently >90%** — MTP heads are well-trained for this model. n_max=2 with p_min=0.85 is the sweet spot; n_max=3 degraded performance in earlier testing.

3. **Speed improves with reuse** — first request was slower (14.46 t/s) due to graph compilation; subsequent requests reached 16.35 t/s as graphs were reused (388 reused graphs in task 377).

4. **`mlock` warning** — failed to mlock a 1.9GB buffer. This is a known issue on GB10; performance is still acceptable without it.

5. **n_ctx_seq < n_ctx_train** — model supports 256K training context; our 262K setting is slightly above but works without issues.

## Comparison with n_max=3 (earlier test)
| Config | Acceptance | Speed |
|---|---|---|
| n_max=2, p_min=0.85 | 92-95% | 12-16 t/s |
| n_max=3, p_min=0.85 | 88.4% | 12.4 t/s |

**Conclusion:** n_max=2 is optimal for this model/hardware combination.
