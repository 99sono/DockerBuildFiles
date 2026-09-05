# NInfer log-parser

Toolchain that turns a raw `docker logs` dump of an NInfer serve container into one
self-contained Markdown performance report. Pure-stdlib Python (no pip packages),
run inside a dedicated conda env.

## Files

| file | purpose |
|---|---|
| `01_create_conda_env_for_parse_script.sh` | create the conda env `testNInferLogParse` (python 3.12). Re-run safe: prompts before recreating. |
| `02_install_python_tools.sh` | verify the env's python + every stdlib import the parser uses. |
| `03_parse_docker_log_file_to_markdown_report.sh` | run the parser on a log file. |
| `parse_docker_log.py` | the parser itself (single pass, pure stdlib). |

## Usage

One-time setup (steps 1–2):

```bash
bash inference-containers/ninfer/log-parser/01_create_conda_env_for_parse_script.sh
bash inference-containers/ninfer/log-parser/02_install_python_tools.sh
```

Parse a log dump (step 3, works from any CWD):

```bash
bash inference-containers/ninfer/log-parser/03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]
```

- default output: `<log_file>.report.md` next to the input (`01_docker_logs.txt` -> `01_docker_logs.report.md`)
- the script prints a one-line count summary (lines/done/submitted/intervals/errors/unrecognized);
  sanity-check it against `grep -c "done finish=" <log_file>` and
  `grep -c "throughput interval" <log_file>` on the raw log

## Report layout

| section | content |
|---|---|
| S1 Startup | model load time, endpoint, KV arena sizing |
| S2 Per-request | one row per request (submitted + done, paired by req id) |
| S3 Timeline | the 5-second throughput-interval samples, verbatim |
| S4 Aggregates | single-session performance, per-request distributions, KV-reuse mode breakdown, speculative-decode vs prompt size |
| S5 Errors | every `[req N] error ...` line |
| S6 Unrecognized | every line no pattern matched — **the canary**: if S6 grows, the log format changed and a pattern in `parse_docker_log.py` needs updating |

## Example

```
$ bash inference-containers/ninfer/log-parser/03_parse_docker_log_file_to_markdown_report.sh \
    inference-containers/ninfer/qwen-3.8-27b-5090/metadata/2026_08_25/01_docker_logs.txt
wrote .../2026_08_25/01_docker_logs.report.md  (lines=249 done=46 submitted=46 intervals=134 errors=1 unrecognized=13)
```