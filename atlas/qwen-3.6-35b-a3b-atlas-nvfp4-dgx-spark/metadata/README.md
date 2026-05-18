# Metadata

Timestamped Atlas container logs dumped via `../05_b_log_to_metadata_folder.sh`.

---

## Observations: Red Hat Models on Atlas vs vLLM

**Performance:** Atlas is faster than vLLM in both startup time and decode throughput for this model.

**Quality differences observed when using Cline with Qwen 35B on Atlas:**
- More frequent "doom loops" — the model tends to get stuck in repetitive patterns more often than on vLLM
- Higher rate of incorrect tool calls compared to the same model served through vLLM
- These issues may be related to the NVFP4 quantization handling or kernel differences

**Example doom loop observed with Cline:**

```
Cline tried to use attempt_completion without value for required parameter 'result'. Retrying...

I apologize for the formatting issue. Here is the completed task result:

Cline tried to use attempt_completion without value for required parameter 'result'. Retrying...

I apologize for the formatting issue. Here is the completed task result:

Cline tried to use attempt_completion without value for required parameter 'result'. Retrying...
```

The model gets stuck in a loop apologizing and retrying the same tool call, never producing a valid completion. This happens repeatedly with Cline's complex prompts and iterative task execution.

**Configurations tested on this model:**
- NVFP4 weights + NVFP4 KV cache — worst quality, frequent doom loops and hallucinated tool calls
- NVFP4 weights + FP8 KV cache (`--kv-cache-dtype fp8`) — some improvement but still unreliable
- Speculation OFF (`--speculative` disabled) — better latency consistency but no quality gain
- Speculation ON with `--mtp-quantization nvfp4`, K=2, ~96% rejection — real speedup (+20-30%) but zero quality improvement
- Reduced prefill window (16K vs 65K) — memory optimization only, no quality impact

**Bottom line:** For Qwen3.6-35B-A3B-NVFP4 on this hardware, vLLM delivers better output quality despite being slower. The speed advantage of Atlas is not worth the quality degradation for agentic coding workflows.

---

## Log File Naming

```
YYYY-MM-DD_HH-MM-SS_atlas_log.txt
```

Logs are captured once (non-following) to preserve a snapshot of the current
container state at the time of invocation. Use `../05_a_docker_logs.sh` for
live, following tail output instead.

## Typical Usage

After observing anomalous behavior (e.g., high K2 rejection rate), run:

```bash
../05_b_log_to_metadata_folder.sh
```

The script produces a summary with file path, size, and line count for quick
reference in debugging sessions.
