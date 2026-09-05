# vLLM log-parser

Toolchain that turns a raw `docker logs` dump of a vLLM serve container into one
self-contained Markdown performance report. Pure-stdlib Python (no pip packages),
run inside a dedicated conda env.

> **Model target.** Built for `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4` on the
> DGX Spark (single GPU) with MTP speculative decoding, but the patterns are
> generic enough for any vLLM v1 serve container — see [How to extend](#how-to-extend).

## Why this is its own tool (not the NInfer one)

vLLM and NInfer log very differently. Three differences drive the whole design:

| | NInfer | vLLM (this tool) |
|---|---|---|
| host clock prefix | `<host-ts> \| <payload>` | none — lines start with an optional process tag `(Name pid=N)` |
| per-request tokens | yes: `[req N] ... prompt= gen=` | **no** at INFO level — a request is only visible via its HTTP access line + the engine's `Running: N reqs` gauge |
| sampling | 5 s throughput interval | 10 s engine sample **plus** a separate `SpecDecoding metrics` line |
| warmup boilerplate | small | large (FlashInfer autotuner, safetensors progress bars, CUDA-graph capture) → a dedicated "noise" section |

There are two container-clock styles in one file:

```
A: INFO 09-05 14:42:00 [loggers.py:310] <msg>              (MM-DD, no year/ms)
B: 2026-09-05 14:29:55,025 - INFO - autotuner.py:1699 - <msg>  (full date + ms)
```

Style A's year is inferred from the first full-date (B) line; if the file has none,
the current year is used. Both are the same clock.

## Files

| file | purpose |
|---|---|
| `01_create_conda_env_for_parse_script.sh` | create the conda env `testVLLMLogParse` (python 3.12). Re-run safe: prompts before recreating. |
| `02_install_python_tools.sh` | verify the env's python + every stdlib import the parser uses. |
| `03_parse_docker_log_file_to_markdown_report.sh` | run the parser on a log file. |
| `parse_docker_log.py` | the parser itself (single pass, pure stdlib). |

## Usage

One-time setup (steps 1–2):

```bash
bash inference-containers/vllm/log-parser/01_create_conda_env_for_parse_script.sh
bash inference-containers/vllm/log-parser/02_install_python_tools.sh
```

Parse a log dump (step 3, works from any CWD):

```bash
bash inference-containers/vllm/log-parser/03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]
```

- default output: `<log_file>.report.md` next to the input (`01_vllm_log.txt` -> `01_vllm_log.report.md`)
- the script prints a one-line count summary (lines/engines/specs/access/jit/warnings/noise/unrecognized);
  sanity-check it against `grep -c "Engine 000:" <log_file>`, `grep -c "SpecDecoding metrics" <log_file>`
  and `grep -c "JIT compilation during inference" <log_file>` on the raw log

## Report layout

| section | content |
|---|---|
| **S1 Startup** | version/model, selected non-default args, KV sizing, weight-load & engine-init timings, PLE-offload facts, server URL |
| **S2 Requests** | (a) active-serving windows read off the engine's `Running: N reqs` samples, (b) the HTTP access log (uvicorn) with a failure list. At INFO level vLLM has **no per-request token counts**, so this is the honest ceiling on request-level detail. |
| **S3 Timeline** | the 10-second engine samples, each paired (by timestamp) with its companion `SpecDecoding metrics` line — verbatim |
| **S4 Aggregates** | 4.1 session window & throughput · 4.2 speculative-decode stats (acceptance length/rate, per-position, session totals) · 4.3 KV-cache & concurrency distribution |
| **S5 Warnings & errors** | 5.1 Triton JIT-compilation-during-inference (first-token latency spikes) · 5.2 HTTP failures · 5.3 every other WARNING/ERROR (deduped with counts + first-seen time) |
| **S6 Recognized noise** | (a) repetitive warmup boilerplate (autotuner, weight-load progress bars, CUDA-graph capture, transformers warnings) recognized & counted, plus (b) benign one-line `INFO` facts without an individual matcher, grouped by source file |
| **S7 Unrecognized** | every line no pattern matched — **the canary**: if S7 grows, the log format changed and a pattern in `parse_docker_log.py` needs updating |

## How it classifies a line

Each non-empty line is routed to exactly one bucket (nothing is dropped). A line
that is **only** a process tag with an empty payload (the first physical line of a
two-line progress bar) is counted as the `tag-only-prefix` noise family.

1. **strip** the optional `(Name pid=N)` process tag
2. **Style A** `TS_A`? then, in order: engine sample → spec sample → JIT →
   startup fact → known-noise → warning/error (S5) → **benign INFO**
   (counted as `vllm-info`, broken down by source file in S6)
3. else **Style B** `TS_B` (full-date)? → autotuner noise
4. else **no timestamp**: uvicorn access line → known-noise → unrecognized

Only a line that is **structurally unparseable** (no `TS_A`/`TS_B`/access/noise
match) lands in the S7 canary. The `NOISE_RE` table plus the `vllm-info` bucket
together mean a normal warmup+serve log ends with S7 empty.

## How to extend

All line grammar lives at the top of `parse_docker_log.py`:

- **new one-shot fact** → add a `re.compile` near the other startup regexes and
  a branch in `handle_startup()`, then a row in `build_report()` S1.
- **new metric line** → add a regex + a collector list in `parse()` + a section in
  `build_report()`.
- **new noise family** → add `(name, re.compile(...))` to `NOISE_RE`.
- **new vLLM version** → first check the S7 canary; the unmatched lines tell you
  exactly which pattern drifted.

## Example

```
$ bash inference-containers/vllm/log-parser/03_parse_docker_log_file_to_markdown_report.sh \
    inference-containers/vllm/qwen-3.8-flash-next-dgx-spark/mia-nvfp4/metadata/2026-09-05/01_vllm_log.txt
wrote .../2026-09-05/01_vllm_log.report.md  (lines=664 engines=... specs=... access=... jit=... warnings=... noise=... unrecognized=...)
```