# Metadata

Timestamped Atlas container logs dumped via `../05_b_log_to_metadata_folder.sh`.

---

## Observations: Red Hat Models on Atlas vs vLLM

**Performance:** Atlas is faster than vLLM in both startup time and decode throughput for this model.

**Quality differences observed when using Cline with Qwen 35B on Atlas:**
- More frequent "doom loops" — the model tends to get stuck in repetitive patterns more often than on vLLM
- Higher rate of incorrect tool calls compared to the same model served through vLLM
- These issues may be related to the NVFP4 quantization handling or kernel differences

These are practical observations, not a definitive judgment on Atlas. Different models or configs may behave differently. The speed advantage is real and significant; the quality gap may narrow with future engine updates.

---



---

## Observations: Red Hat Models on Atlas vs vLLM

**Performance:** Atlas is faster than vLLM in both startup time and decode throughput for this model.

**Quality differences observed when using Cline with Qwen 35B on Atlas:**
- More frequent "doom loops" — the model tends to get stuck in repetitive patterns more often than on vLLM
- Higher rate of incorrect tool calls compared to the same model served through vLLM
- These issues may be related to the NVFP4 quantization handling or kernel differences

These are practical observations, not a definitive judgment on Atlas. Different models or configs may behave differently. The speed advantage is real and significant; the quality gap may narrow with future engine updates.

---



---

## ⚠️ CRITICAL WARNING: Red Hat Models on Atlas — Not Usable Despite Speed

**Despite Atlas being significantly faster than vLLM** (both in startup time ~5× and decode throughput ~2×), the **Red Hat Qwen3.6-35B-A3B-NVFP4 model produces severely degraded output quality on Atlas**:

- **Crazy doom loops:** The model gets stuck in repetitive loops, generating nonsensical circular reasoning or repeating phrases endlessly
- **Massive hallucination rate:** Far more fabricated content than vLLM with the same model weights — confident wrong answers at scale
- **Not practically usable:** Speed doesn't matter if the output is unreliable. For production work where correctness matters, **use vLLM instead**.

This appears to be specific to the Red Hat NVFP4 quantized models on Atlas (not necessarily a universal Atlas issue). Possible causes:
- NVFP4 weight handling differences between Atlas and vLLM
- Attention kernel implementation variations
- SSM layer precision loss in pure NVFP4 without high-precision layers

**Bottom line:** Atlas wins raw benchmarks but loses badly on quality for these models. Speed is meaningless if the model is hallucinating and looping.

---



```
YYYY-MM-DD_HH-MM-SS_atlas_log.txt
```

Logs are captured once (non-following) to preserve a snapshot of the current
container state at the time of invocation. Use `../05_docker_logs.sh` for
live, following tail output instead.

## Typical Usage

After observing anomalous behavior (e.g., high K2 rejection rate), run:

```bash
../05_b_log_to_metadata_folder.sh
```

The script produces a summary with file path, size, and line count for quick
reference in debugging sessions.
