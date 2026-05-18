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
