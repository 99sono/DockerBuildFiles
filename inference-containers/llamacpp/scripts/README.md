# llama.cpp log toolchain (scripts/)

Shared helper to turn a running llama.cpp server container's logs into an
accurate markdown performance report.

## Files

| File | What it does |
|---|---|
| `parse_llamacpp_log.py` | Stdlib-only Python 3 parser. Reads a `docker logs` dump of a llama.cpp server and prints a markdown report (or `--json` raw stats). Never crashes on malformed lines. |
| `dump_and_report.sh` | Bash wrapper: dumps the container logs to a timestamped file (via `commonScripts/lib.sh` → `docker_logs_dump_container`), then runs the parser to produce a markdown report. |
| `README.md` | This file. |

## How to use it

There are **two ways** to get a performance report. Pick whichever fits your
workflow — they produce identical reports.

### Option A — per-project dump script (recommended for everyday use)

The per-project log script `05_b_dump_logs.sh` already dumps the container
logs AND runs this parser. Just run it from the project folder, exactly as you
always have:

```bash
cd inference-containers/llamacpp/qwen-3.8-27b-5090/unsloth
./05_b_dump_logs.sh
```

It produces two files **in that folder**:

- `<TIMESTAMP>_qwen-3.8-27b-5090_log_dump.txt` — full log dump (masked)
- `<TIMESTAMP>_qwen-3.8-27b-5090_log_report.md` — markdown performance report

(If the project predates this toolchain, add the same two lines to its
`05_b_dump_logs.sh`: point `PARSER` at the shared script and run
`python3 "$PARSER" "$OUTPUT_FILE" > "$REPORT_FILE"`.)

### Option B — shared one-shot wrapper

Run from any directory (output files appear in the **current directory**):

```bash
cd inference-containers/llamacpp/qwen-3.8-27b-5090/unsloth
../../scripts/dump_and_report.sh [CONTAINER]   # default container: qwen-3.8-27b-5090
```

Produces in the current directory:

- `<TIMESTAMP>_<CONTAINER>_log_dump.txt` — full log dump (sensitive values masked)
- `<TIMESTAMP>_<CONTAINER>_log_report.md` — markdown performance report

### Option C — parser only (no docker needed)

If you already have a log dump file (e.g. from an earlier run or another
machine), parse it directly:

```bash
python3 parse_llamacpp_log.py <log_dump.txt>            # markdown report to stdout
python3 parse_llamacpp_log.py --json <log_dump.txt>     # raw parsed stats as JSON
python3 parse_llamacpp_log.py /path/to/dump.txt > report.md
```

No CLI arg → prints usage and exits non-zero. Malformed lines are skipped silently.

> **Requirements:** the container must be running for Options A/B (they use
> `docker logs`); Option C works on any existing dump file.

## What the report contains

1. **Server & model** — model file path, `n_slots`, `n_ctx_slot` (or `n_ctx`),
   `kv_unified`, host:port, CPU threads, plus the MTP/speculative context lines.
2. **Requests & per-task throughput** — total task count, and (last 10 tasks)
   prompt eval ms/tokens + prompt t/s, eval ms/tokens + eval t/s, total ms,
   and MTP draft acceptance per task.
3. **Aggregates** — total prompt/generation tokens, prompt-eval t/s
   mean/min/max, generation t/s simple mean/min/max, overall generation t/s
   (Σ gen tokens / Σ eval time, i.e. token-weighted), MTP draft acceptance
   mean/min/max + weighted (Σ acc / Σ gen) + mean draft length, graphs reused total.
4. **Mid-generation snapshots** — min/mean/max of `tg` and the 3-second rolling
   `tg_3s` snapshot values.
5. **Warnings** — all `W`-level and bare `warn:` lines, deduplicated with
   counts (digit-normalized, so e.g. `prompt_save` lines with different sizes
   group together). `E`-level lines are listed under Errors.

## Supported log formats

Both the current llama.cpp timing lines (`n_gen`, `tg`, `tg_3s`, `draft
acceptance ... mean len`) and the older ones (`n_decoded`, `tg`, draft
acceptance without `mean len`) are parsed. Edge cases handled: logs with
snapshot-only tasks (no final timing block), logs with zero tasks, and
truncated/malformed lines.

## Limitations

- The parser is tuned to llama.cpp's log layout (timestamp + level +
  component + message). Lines that don't match (chat echoes, compose output)
  are ignored.
- Throughput numbers are taken from the values llama.cpp prints; they are not
  re-derived from the raw ms/token counts.
- Task table shows the last 10 tasks; all tasks still feed the aggregates.
