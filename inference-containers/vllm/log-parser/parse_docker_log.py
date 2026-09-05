#!/usr/bin/env python3
"""vLLM docker-log -> Markdown performance report.

WHAT THIS TOOL DOES
===================
Takes a raw `docker logs <container>` dump of a vLLM serve container
(Mia-AiLab Qwen3.8-Flash-Next-NVFP4 on the DGX Spark, single GPU) and turns
it into one self-contained Markdown report:

    S1  Startup       - version/model, non-default args, KV sizing, weight-load
                        and engine-init timings, PLE-offload facts, server URL
    S2  Requests      - (a) active-serving windows read off the engine's
                        "Running: N reqs" samples, (b) the HTTP access log
                        (uvicorn) with a failure list. NOTE: at INFO level vLLM
                        emits NO per-request token accounting, so a request can
                        only be seen via its access line + the engine's running
                        count -- this tool is honest about that limit.
    S3  Timeline      - the 10-second engine samples + companion SpecDecoding
                        metric lines, verbatim (paired by timestamp)
    S4  Aggregates    - session window & throughput, speculative-decode stats,
                        KV-cache / concurrency distribution
    S5  Warnings      - JIT-compilation-during-inference, HTTP auth failures,
                        every other WARNING/ERROR (deduped with counts)
    S6  Noise         - repetitive boilerplate families (autotuner, weight-load
                        progress bars, CUDA-graph capture, transformers warnings),
                        recognized & counted so they don't pollute the canary
    S7  Unrecognized  - every line no pattern matched. THIS IS THE CANARY:
                        if S7 grows, the log format changed and a pattern below
                        needs updating.

WHY THIS DIFFERS FROM THE NINFER PARSER
=======================================
* No host-clock prefix. NInfer lines are `<host-ts> | <payload>`; vLLM lines
  start directly with an OPTIONAL process tag `(Name pid=N) ` then a payload.
  There is a single (container) clock, written in TWO styles:
      A: `INFO MM-DD HH:MM:SS [file:line] <msg>`        (MM-DD, no year/ms)
      B: `2026-09-05 14:29:55,025 - INFO - autotuner.py:1699 - <msg>` (full, +ms)
  Style A's year is inferred from the first Style B (full-date) line seen; if
  the file has none, the current year is used. A and B are the same clock.
* No per-request token lines. vLLM INFO logs have no `[req N] ... prompt= gen=`
  lines (NInfer has them). Request-level visibility = uvicorn access lines
  (`INFO:  IP:port - "METHOD PATH HTTP/1.1" STATUS`) + the engine's
  `Running: N reqs` gauge in each 10 s sample.
* 10 s engine sampling (NInfer is 5 s) and a separate SpecDecoding metrics
  line per sample (NInfer inlines speculative stats on the request `done` line).
* Far more warmup boilerplate (FlashInfer autotuner, safetensors progress bars,
  CUDA-graph capture) -> a whole "noise" section (S6) so the canary stays clean.

DESIGN DECISIONS
================
* Pure stdlib (re / datetime / math / statistics / collections / argparse / typing):
  no pip packages, so the conda env is reproducible with zero network deps.
* Every non-empty line is counted and routed to exactly one bucket:
  engine sample / spec sample / access / startup fact / jit / warning /
  noise-family / unrecognized. Nothing is silently dropped.
* Repetitive warmup boilerplate is recognized into named noise families and
  shown only as counts (S6), so the S7 canary only ever contains genuinely
  unexpected lines.

USAGE
=====
    python3 parse_docker_log.py <log_file> [-o output.md]
    # default output: <log_file>.report.md (01_vllm_log.txt -> ...report.md)
"""
from __future__ import annotations

import argparse
import math
import re
import statistics
from collections import Counter
from datetime import datetime
from typing import Any, Optional, TypedDict


# =====================================================================
# DATA CONTRACTS & SCHEMAS (TYPEDDICTS)
# =====================================================================

class EngineSample(TypedDict):
    """10-second engine throughput and utilization sample.
    
    Emitted by `loggers.py:310` in vLLM.
    """
    ts: datetime
    prompt: float         # Prompt throughput (tokens/s)
    gen: float            # Generation throughput (tokens/s)
    running: int          # Running requests count
    waiting: int          # Waiting requests in queue
    kv: float             # GPU KV cache usage (%)
    prefix: float         # Prefix cache hit rate (%)
    mm: Optional[float]   # Multimodal cache hit rate (%, or None if absent)


class SpecSample(TypedDict):
    """Companion speculative decoding metrics line.
    
    Emitted by `metrics.py:120` in vLLM at the same timestamp as EngineSample.
    """
    ts: datetime
    acc_len: float        # Mean acceptance length (tokens per step)
    acc_tps: float        # Accepted token throughput (tokens/s)
    draft_tps: float      # Drafted token throughput (tokens/s)
    accepted: int         # Cumulative accepted tokens
    drafted: int          # Cumulative drafted tokens
    p1: float             # Acceptance rate at draft position 1 [0.0 - 1.0]
    p2: float             # Acceptance rate at draft position 2 [0.0 - 1.0]
    p3: float             # Acceptance rate at draft position 3 [0.0 - 1.0]
    draft_acc: float      # Overall draft acceptance rate (%)


class AccessLogEntry(TypedDict):
    """HTTP request access log line emitted by Uvicorn."""
    seq: int              # Sequential index (1-based)
    client: str           # Client IP:port (e.g. "172.18.0.3:59288")
    method: str           # HTTP method ("GET", "POST")
    path: str             # Endpoint path (e.g. "/v1/chat/completions")
    status: int           # HTTP status code (e.g. 200, 401)
    reason: str           # HTTP status phrase (e.g. "OK", "Unauthorized")


class JitEntry(TypedDict):
    """Triton kernel just-in-time compilation during active inference."""
    ts: datetime
    kernel: str           # Triton kernel identifier


class WarningEntry(TypedDict):
    """Warning or error log entry."""
    level: str            # "WARNING", "ERROR", "CRITICAL"
    ts: datetime
    msg: str              # Log message


class ActivityWindow(TypedDict):
    """Contiguous active serving window derived from consecutive running samples."""
    start: datetime       # Timestamp of first sample with running > 0
    end: datetime         # Timestamp of last consecutive sample with running > 0
    n: int                # Number of consecutive samples in window
    peak: int             # Peak concurrent running requests
    dur: float            # Duration in seconds ((end - start).total_seconds())


class SessionStats(TypedDict):
    """Summary throughput and session statistics."""
    n_samples: int
    first_sample: datetime
    last_sample: datetime
    span: float
    peak_gen: float
    peak_prompt: float
    mean_gen_busy: Optional[float]
    busy_samples: int
    serving_span: float
    n_active_windows: int


class ParsedLog(TypedDict):
    """Full structured output returned by parse()."""
    startup: dict[str, Any]
    engines: list[EngineSample]
    specs: list[SpecSample]
    accesses: list[AccessLogEntry]
    jit: list[JitEntry]
    warnings: list[WarningEntry]
    noise: Counter[str]
    info_by_source: Counter[str]
    unrecognized: list[tuple[int, str]]
    total: int
    first: Optional[datetime]
    last: Optional[datetime]


# =====================================================================
# LINE-GRAMMAR PATTERNS & REGEXES
# =====================================================================
# PROCESS strips the optional "(Name pid=N) " tag that vLLM prefixes to most lines.
# Example:
#   (APIServer pid=1) INFO 09-05 14:18:36 [api_utils.py:333] version 0.1.dev20073+g8e685d198
PROCESS = re.compile(r"^\(([A-Za-z][A-Za-z0-9]*) pid=(\d+)\)\s?(.*)$")

# TS_A captures Style A timestamps: Level MM-DD HH:MM:SS [source:line] Message
# Example:
#   INFO 09-05 14:53:50 [loggers.py:310] Engine 000: Avg prompt throughput: 0.0 tokens/s ...
TS_A = re.compile(r"^([A-Z]+)\s+(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s+\[([^\]]+)\]\s+(.*)$")

# TS_B captures Style B timestamps: YYYY-MM-DD HH:MM:SS,mmm - Level - source - Message
# Example:
#   2026-09-05 14:29:55,025 - INFO - autotuner.py:1699 - Autotuning finished in 12.3s
TS_B = re.compile(r"(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2}),(\d{3})\s+-\s+([A-Z]+)\s+-\s+([^\s-]+)\s+-\s+(.*)$")

# Engine throughput sample:
# Example:
#   Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 31.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.1%, Prefix cache hit rate: 10.1%, MM cache hit rate: 0.0%
ENG = re.compile(
    r"Engine \d+: Avg prompt throughput: ([\d.]+) tokens/s, "
    r"Avg generation throughput: ([\d.]+) tokens/s, "
    r"Running: (\d+) reqs, Waiting: (\d+) reqs, "
    r"GPU KV cache usage: ([\d.]+)%, Prefix cache hit rate: ([\d.]+)%"
    r"(?:, MM cache hit rate: ([\d.]+)%)?")

# MTP speculative decoding metrics sample:
# Example:
#   SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 18.20 tokens/s, Drafted throughput: 39.30 tokens/s, Accepted: 182 tokens, Drafted: 393 tokens, Per-position acceptance rate: 0.626, 0.443, 0.321, Avg Draft acceptance rate: 46.3%
SPEC = re.compile(
    r"SpecDecoding metrics: Mean acceptance length: ([\d.]+), "
    r"Accepted throughput: ([\d.]+) tokens/s, Drafted throughput: ([\d.]+) tokens/s, "
    r"Accepted: (\d+) tokens, Drafted: (\d+) tokens, "
    r"Per-position acceptance rate: ([\d.]+), ([\d.]+), ([\d.]+), "
    r"Avg Draft acceptance rate: ([\d.]+)%")

# Uvicorn access log lines:
# Example:
#   INFO:  172.18.0.3:59288 - "POST /v1/chat/completions HTTP/1.1" 200 OK
ACC = re.compile(r'INFO:\s+(\S+:\d+)\s+-\s+"([A-Z]+) (\S+) HTTP/[\d.]+"\s+(\d{3})\s+(\w+)')

# Startup one-shot facts:
INIT_ENGINE = re.compile(r"Initializing a V1 LLM engine \(v(.+?)\) with config: model='([^']+)'")
NONDEFAULT  = re.compile(r"non-default args: (\{.*\})\s*$")
ARCH        = re.compile(r"Resolved architecture: (\S+)")
MAXLEN      = re.compile(r"Using max model len (\d+)")
KV_AVAIL    = re.compile(r"Available KV cache memory: ([\d.]+) GiB")
KV_SIZE     = re.compile(r"GPU KV cache size: ([\d,]+) tokens, Maximum concurrency for ([\d,]+) tokens per request: ([\d.]+)x")
WEIGHTS     = re.compile(r"Loading weights took ([\d.]+) seconds")
MODEL_LOAD  = re.compile(r"Model loading took ([\d.]+) GiB memory and ([\d.]+) seconds")
INIT_TOOK   = re.compile(r"init engine \(profile, create kv cache, warmup model\) took ([\d.]+) s")
GRAPHS      = re.compile(r"Graph capturing finished in (\d+) secs, took ([\d.]+) GiB")
PLE_TABLE   = re.compile(r"mmap table attached \(([\d,]+) rows x (\d+) B = ([\d.]+) GiB\)")
PLE_MATCH   = re.compile(r"PLE offload matched (\d+) checkpoint tensor\(s\), loaded (\d+) offload entries")
PLE_DONE    = re.compile(r"PLE weight loading complete")
SERVER_ON   = re.compile(r"Starting vLLM server on (\S+)")
MM_WARMUP   = re.compile(r"Multi-modal warmup completed in ([\d.]+)s")
TORCH_THR   = re.compile(r"Reducing Torch threads from (\d+) to (\d+)")
ATTN_BLOCK  = re.compile(r"Setting attention block size to (\d+) tokens")
ENC_BUDGET  = re.compile(r"Encoder cache will be initialized with a budget of (\d+) tokens")
SAMPLING    = re.compile(r"Default vLLM sampling parameters have been overridden by the model's `generation_config\.json`: (\{.*?\})")
SUPPORTED   = re.compile(r"Supported tasks: (\[[^\]]*\])")

# Real-time JIT compilation during inference (indicates first-token latency spike):
JIT = re.compile(r"Triton kernel JIT compilation during inference: (\S+)\.")

# Known repetitive boilerplate families (Section 6 noise, counted to keep canary clean):
NOISE_RE: list[tuple[str, re.Pattern[str]]] = [
    ("autotuner",                 re.compile(r"(?i)\[autotuner\]")),
    ("transformers-rope",         re.compile(r"^\[transformers\] Unrecognized keys")),
    ("transformers-use_fast",     re.compile(r"^\[transformers\] The `use_fast`")),
    ("docstring-not-documented",  re.compile(r"^\[ERROR\] `\w+` is part of .* not documented")),
    ("hf-unauthenticated",        re.compile(r"You are sending unauthenticated requests to the HF Hub")),
    ("load-progress-bar",         re.compile(r"^Loading safetensors checkpoint shards")),
    ("cudagraph-capture",         re.compile(r"^Capturing (?:\w+ )?CUDA graphs")),
    ("uvicorn-server",            re.compile(r"INFO:\s+(Started server process|Waiting for application startup|Application startup complete|Uvicorn running|Shutting down server|Stopping server process)")),
    ("ple-code-snippet",          re.compile(r"^\s*table = torch\.from_numpy")),
    ("shm-broadcast-wait",        re.compile(r"No available shared memory broadcast block found")),
    ("triton-make_block_ptr",     re.compile(r"tl\.make_block_ptr is deprecated")),
    ("ple-nonwritable-array",     re.compile(r"given NumPy array is not writable")),
    ("banner-art",                re.compile(r"[█▄▀]")),
]


# =====================================================================
# STATISTICAL & EXTRACTION HELPERS
# =====================================================================

def pctl(vals: list[float], p: float) -> Optional[float]:
    """Compute nearest-rank percentile (p in 0..100) without numpy.

    Args:
        vals: List of numeric float values.
        p: Target percentile (0.0 to 100.0).

    Returns:
        The nearest-rank percentile value, or None if vals is empty.
    """
    if not vals:
        return None
    v = sorted(vals)
    idx = max(0, min(len(v) - 1, math.ceil(p / 100.0 * len(v)) - 1))
    return v[idx]


def stat_row(label: str, vals: list[float], unit: str, nd: int = 1) -> str:
    """Render a standard Markdown statistical distribution table row.

    Computes count (n), mean, median, min, max, and p95.

    Args:
        label: Row title (e.g. "acceptance length").
        vals: List of numeric values to analyze.
        unit: Metric unit label (e.g. "tok", "tok/s", "%").
        nd: Number of decimal places for formatting (default 1).

    Returns:
        Formatted Markdown table row string.
    """
    if not vals:
        return f"| {label} | 0 | — | — | — | — | — | {unit} |"
    return (
        f"| {label} | {len(vals)} | {sum(vals)/len(vals):.{nd}f} | {statistics.median(vals):.{nd}f} | "
        f"{min(vals):.{nd}f} | {max(vals):.{nd}f} | {pctl(vals, 95):.{nd}f} | {unit} |"
    )


def mean(vals: list[float]) -> Optional[float]:
    """Return arithmetic mean of values, or None if list is empty."""
    return sum(vals) / len(vals) if vals else None


def noise_match(text: str) -> Optional[str]:
    """Match text against registered NOISE_RE patterns.

    Args:
        text: Stripped line payload to classify.

    Returns:
        The matching noise family name (e.g. "autotuner"), or None if no match.
    """
    for name, rx in NOISE_RE:
        if rx.search(text):
            return name
    return None


def extract_args(s: str) -> dict[str, Any]:
    """Extract operational configuration arguments from the non-default args dict repr.

    vLLM prints `non-default args: {...}` containing internal enums (e.g.
    `<CompilationMode.NONE: 0>`) which cannot be parsed directly via `ast.literal_eval`.
    This helper applies targeted regex extraction for relevant serving parameters.

    Args:
        s: Raw string representation of the argument dictionary.

    Returns:
        Dict mapping argument names to extracted typed values (str, int, float).
    """
    def g(rx: str, cast: Any = str) -> Any:
        m = re.search(rx, s)
        return cast(m[1]) if m else None

    d = {
        "model":                    g(r"'model': '([^']+)'"),
        "served_model_name":        g(r"'served_model_name': \['([^']+)'\]"),
        "max_model_len":            g(r"'max_model_len': (\d+)", int),
        "quantization":             g(r"'quantization': '([^']+)'"),
        "gpu_memory_utilization":   g(r"'gpu_memory_utilization': ([\d.]+)", float),
        "kv_cache_dtype":           g(r"'kv_cache_dtype': '([^']+)'"),
        "max_num_batched_tokens":   g(r"'max_num_batched_tokens': (\d+)", int),
        "max_num_seqs":             g(r"'max_num_seqs': (\d+)", int),
        "enable_chunked_prefill":   g(r"'enable_chunked_prefill': (\w+)"),
        "spec_method":              g(r"'method': '(\w+)'"),
        "spec_tokens":              g(r"'num_speculative_tokens': (\d+)", int),
        "reasoning_parser":         g(r"'reasoning_parser': '([^']+)'"),
        "tool_call_parser":         g(r"'tool_call_parser': '([^']+)'"),
        "load_strategy":            g(r"'safetensors_load_strategy': '([^']+)'"),
    }
    return {k: v for k, v in d.items() if v is not None}


def handle_startup(st: dict[str, Any], msg: str) -> bool:
    """Capture one-shot engine startup and configuration facts.

    Inspects line message against startup regexes and populates the `st` dict.

    Args:
        st: Target dictionary to store extracted startup facts.
        msg: Payload string of a Style A log line.

    Returns:
        True if the line matched a startup event pattern, False otherwise.
    """
    m = INIT_ENGINE.search(msg)
    if m:
        st["version"], st["model"] = m[1], m[2]
        for key, rx in (("prefix_caching", r"enable_prefix_caching=(\w+)"),
                        ("chunked_prefill", r"enable_chunked_prefill=(\w+)"),
                        ("dtype", r"\bdtype=(\w+)")):
            x = re.search(rx, msg)
            if x:
                st[key] = x[1]
        return True
    m = NONDEFAULT.search(msg)
    if m:
        st["args"] = extract_args(m[1]); return True
    m = ARCH.search(msg)
    if m:
        st.setdefault("arch", []).append(m[1]); return True
    m = MAXLEN.search(msg)
    if m:
        st["max_len"] = int(m[1]); return True
    m = KV_AVAIL.search(msg)
    if m:
        st["kv_avail"] = float(m[1]); return True
    m = KV_SIZE.search(msg)
    if m:
        st["kv_tokens"] = int(m[1].replace(",", ""))
        st["kv_concurrency"] = float(m[3]); return True
    m = WEIGHTS.search(msg)
    if m:
        st.setdefault("weights_took", []).append(float(m[1])); return True
    m = MODEL_LOAD.search(msg)
    if m:
        st["model_load"] = {"gib": float(m[1]), "s": float(m[2])}; return True
    m = INIT_TOOK.search(msg)
    if m:
        st["init_engine_s"] = float(m[1]); return True
    m = GRAPHS.search(msg)
    if m:
        st["graphs"] = {"secs": int(m[1]), "gib": float(m[2])}; return True
    m = PLE_TABLE.search(msg)
    if m:
        st["ple_table"] = {"rows": int(m[1].replace(",", "")), "bytes": int(m[2]), "gib": float(m[3])}; return True
    m = PLE_MATCH.search(msg)
    if m:
        st["ple_match"] = {"tensors": int(m[1]), "entries": int(m[2])}; return True
    if PLE_DONE.search(msg):
        st["ple_done"] = True; return True
    m = SERVER_ON.search(msg)
    if m:
        st["server_url"] = m[1]; return True
    m = MM_WARMUP.search(msg)
    if m:
        st["mm_warmup_s"] = float(m[1]); return True
    m = TORCH_THR.search(msg)
    if m:
        st["torch_threads"] = (int(m[1]), int(m[2])); return True
    m = ATTN_BLOCK.search(msg)
    if m:
        st["attn_block"] = int(m[1]); return True
    m = ENC_BUDGET.search(msg)
    if m:
        st["enc_budget"] = int(m[1]); return True
    m = SAMPLING.search(msg)
    if m:
        st["sampling_override"] = m[1]; return True
    m = SUPPORTED.search(msg)
    if m:
        st["supported_tasks"] = m[1]; return True
    return False


# =====================================================================
# CORE PARSER PIPELINE
# =====================================================================

def parse(path: str) -> ParsedLog:
    """Perform a single-pass parse of a raw vLLM docker-log dump.

    Lines are classified using a 3-layer priority filter:
      1. Process tag strip -> Style A timestamp (Engine, Spec, JIT, Startup, Noise, Warnings, Benign INFO).
      2. Style B full-date timestamp (FlashInfer autotuner noise).
      3. No-timestamp fallback (Uvicorn HTTP access log, Noise, Unrecognized canary).

    Args:
        path: File path to the raw container log dump (.txt).

    Returns:
        ParsedLog TypedDict containing all structured data models.
    """
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()

    # Infer the year for Style A timestamps from the first full-date line encountered.
    ym = re.search(r"\b(\d{4})-\d{2}-\d{2}\b", "\n".join(lines))
    year = int(ym.group(1)) if ym else datetime.now().year

    startup: dict[str, Any] = {}
    engines: list[EngineSample] = []
    specs: list[SpecSample] = []
    accesses: list[AccessLogEntry] = []
    jit: list[JitEntry] = []
    warnings: list[WarningEntry] = []
    noise: Counter[str] = Counter()
    info_by_source: Counter[str] = Counter()
    unrecognized: list[tuple[int, str]] = []
    total = 0
    first: Optional[datetime] = None
    last: Optional[datetime] = None

    def track(t: datetime) -> None:
        nonlocal first, last
        first = t if first is None else min(first, t)
        last = t if last is None else max(last, t)

    for n, raw in enumerate(lines, 1):
        raw = raw.rstrip("\n")
        if not raw.strip():
            continue  # Skip empty lines
        total += 1

        pm = PROCESS.match(raw)
        payload = pm.group(3) if pm else raw

        # Handle two-line progress bars where line 1 is only an orphan process tag
        if pm and not payload.strip():
            noise["tag-only-prefix"] += 1
            continue

        # ---- Layer 1: vLLM logger line with Style A timestamp -------------
        a = TS_A.match(payload)
        if a:
            level = a.group(1)
            ts = datetime(year, int(a.group(2)), int(a.group(3)),
                          int(a.group(4)), int(a.group(5)), int(a.group(6)))
            msg = a.group(8)
            track(ts)

            e = ENG.search(msg)
            if e:
                engines.append({
                    "ts": ts,
                    "prompt": float(e[1]),
                    "gen": float(e[2]),
                    "running": int(e[3]),
                    "waiting": int(e[4]),
                    "kv": float(e[5]),
                    "prefix": float(e[6]),
                    "mm": float(e[7]) if e[7] is not None else None,
                })
                continue

            s = SPEC.search(msg)
            if s:
                specs.append({
                    "ts": ts,
                    "acc_len": float(s[1]),
                    "acc_tps": float(s[2]),
                    "draft_tps": float(s[3]),
                    "accepted": int(s[4]),
                    "drafted": int(s[5]),
                    "p1": float(s[6]),
                    "p2": float(s[7]),
                    "p3": float(s[8]),
                    "draft_acc": float(s[9]),
                })
                continue

            j = JIT.search(msg)
            if j:
                jit.append({"ts": ts, "kernel": j[1]})
                continue

            if handle_startup(startup, msg):
                continue

            fam = noise_match(msg)
            if fam:
                noise[fam] += 1
                continue

            if level in ("WARNING", "ERROR", "CRITICAL"):
                warnings.append({"level": level, "ts": ts, "msg": msg})
            else:
                # Group benign INFO lines by source file to keep canary clean
                noise["vllm-info"] += 1
                info_by_source[a.group(7).rsplit(":", 1)[0]] += 1
            continue

        # ---- Layer 2: Full-date Style B timestamp (FlashInfer Autotuner) --
        b = TS_B.search(payload)
        if b:
            ts = datetime(int(b.group(1)), int(b.group(2)), int(b.group(3)),
                          int(b.group(4)), int(b.group(5)), int(b.group(6)),
                          int(b.group(7)) * 1000)
            track(ts)
            noise["autotuner"] += 1
            continue

        # ---- Layer 3: Un-timestamped lines (Uvicorn access or unparsed) ----
        acc = ACC.search(payload)
        if acc:
            accesses.append({
                "seq": len(accesses) + 1,
                "client": acc[1],
                "method": acc[2],
                "path": acc[3],
                "status": int(acc[4]),
                "reason": acc[5],
            })
            continue

        fam = noise_match(payload)
        if fam:
            noise[fam] += 1
            continue

        # Unmatched line reaches S7 canary
        unrecognized.append((n, raw))

    return {
        "startup": startup,
        "engines": engines,
        "specs": specs,
        "accesses": accesses,
        "jit": jit,
        "warnings": warnings,
        "noise": noise,
        "info_by_source": info_by_source,
        "unrecognized": unrecognized,
        "total": total,
        "first": first,
        "last": last,
    }


# =====================================================================
# AGGREGATION & WINDOW ANALYSIS
# =====================================================================

def activity_windows(engines: list[EngineSample]) -> list[ActivityWindow]:
    """Identify contiguous active serving windows from engine samples.

    A serving window represents consecutive samples with running requests > 0.
    Since samples are emitted roughly every 10 seconds, this reconstructs
    active client interaction periods.

    Args:
        engines: List of EngineSample dicts in chronological order.

    Returns:
        List of ActivityWindow dicts detailing window start, end, duration, and peak concurrency.
    """
    wins: list[ActivityWindow] = []
    cur: Optional[ActivityWindow] = None
    for e in engines:
        if e["running"] > 0:
            if cur is None:
                cur = {"start": e["ts"], "end": e["ts"], "n": 1, "peak": e["running"], "dur": 0.0}
            else:
                cur["end"] = e["ts"]
                cur["n"] += 1
                cur["peak"] = max(cur["peak"], e["running"])
        else:
            if cur:
                wins.append(cur)
                cur = None
    if cur:
        wins.append(cur)

    for w in wins:
        w["dur"] = (w["end"] - w["start"]).total_seconds()
    return wins


def single_session(d: ParsedLog) -> Optional[SessionStats]:
    """Compute overall session throughput and concurrency statistics.

    Args:
        d: ParsedLog output from parse().

    Returns:
        SessionStats dict or None if no engine samples exist.
    """
    eng = d["engines"]
    if not eng:
        return None
    busy = [e for e in eng if e["gen"] > 0]
    run = [e for e in eng if e["running"] > 0]
    serving_span = (max(e["ts"] for e in run) - min(e["ts"] for e in run)).total_seconds() if run else 0.0

    return {
        "n_samples": len(eng),
        "first_sample": eng[0]["ts"],
        "last_sample": eng[-1]["ts"],
        "span": (eng[-1]["ts"] - eng[0]["ts"]).total_seconds(),
        "peak_gen": max(e["gen"] for e in eng),
        "peak_prompt": max(e["prompt"] for e in eng),
        "mean_gen_busy": mean([e["gen"] for e in busy]),
        "busy_samples": len(busy),
        "serving_span": serving_span,
        "n_active_windows": len(activity_windows(eng)),
    }


# =====================================================================
# MODULAR REPORT RENDERERS (S1 - S7)
# =====================================================================

def _fmt_ts(t: Optional[datetime]) -> str:
    """Format datetime as HH:MM:SS string or dash if None."""
    return t.strftime("%H:%M:%S") if t else "—"


def _render_header(d: ParsedLog, src: str) -> list[str]:
    """Render report title, generation timestamp, and top-level summary gauges."""
    L: list[str] = [f"# vLLM Docker Log Report — `{src}`\n"]
    L.append(f"- generated: {datetime.now():%Y-%m-%d %H:%M:%S}")
    rng = f"{d['first']:%Y-%m-%d %H:%M:%S} → {d['last']:%Y-%m-%d %H:%M:%S}" if d['first'] else "n/a"
    L.append(f"- input lines: {d['total']} | log range: {rng} (container clock)")
    L.append(
        f"- engine samples: {len(d['engines'])} | spec samples: {len(d['specs'])} | "
        f"http access: {len(d['accesses'])} | warnings: {len(d['warnings'])} | "
        f"noise families: {sum(d['noise'].values())}\n"
    )
    return L


def _render_startup_section(st: dict[str, Any]) -> list[str]:
    """Render Section 1: Engine startup configuration, model parameters, and memory layout."""
    L: list[str] = ["## 1. Startup\n"]
    rows: list[str] = []

    if st.get("version"):
        rows.append(f"| vLLM version | `{st['version']}` |")
    if st.get("model"):
        rows.append(f"| model | `{st['model']}` |")
    if st.get("served_model_name"):
        rows.append(f"| served model name | `{st['served_model_name']}` |")
    if st.get("arch"):
        rows.append(f"| architecture(s) | {', '.join('`%s`' % a for a in st['arch'])} |")
    if st.get("server_url"):
        rows.append(f"| server | {st['server_url']} |")
    if st.get("supported_tasks"):
        rows.append(f"| supported tasks | {st['supported_tasks']} |")

    # Selected non-default argument overrides
    args = st.get("args", {})
    if args:
        rows.append("| non-default args |")
        arows = []
        for k in ("model", "served_model_name", "max_model_len", "quantization",
                  "gpu_memory_utilization", "kv_cache_dtype", "max_num_batched_tokens",
                  "max_num_seqs", "enable_chunked_prefill", "spec_method", "spec_tokens",
                  "reasoning_parser", "tool_call_parser", "load_strategy"):
            if k in args:
                arows.append(f"  - `{k}` = {args[k]}")
        rows.extend(arows)

    # Engine toggles
    for k, lab in (("prefix_caching", "prefix caching"), ("chunked_prefill", "chunked prefill"),
                   ("dtype", "dtype")):
        if st.get(k) is not None:
            rows.append(f"| {lab} | `{st[k]}` |")
    if st.get("max_len"):
        rows.append(f"| max model len | {st['max_len']:,} |")

    # KV memory and token sizing
    if st.get("kv_avail") is not None:
        rows.append(f"| available KV memory | {st['kv_avail']} GiB |")
    if st.get("kv_tokens"):
        rows.append(
            f"| GPU KV cache size | {st['kv_tokens']:,} tokens "
            f"(max concurrency {st.get('kv_concurrency', '—')}× for "
            f"{st.get('max_len', st.get('args', {}).get('max_model_len', '?')):,} tok/req) |"
        )

    # Loader and warmup timings
    wt = st.get("weights_took")
    if wt:
        rows.append(f"| weight-load time | {', '.join(f'{x:.1f} s' for x in wt)} |")
    if st.get("model_load"):
        rows.append(f"| model load | {st['model_load']['gib']} GiB, {st['model_load']['s']:.1f} s |")
    if st.get("init_engine_s") is not None:
        rows.append(f"| init engine (profile+KV+warmup) | {st['init_engine_s']} s |")
    if st.get("graphs"):
        rows.append(f"| CUDA-graph capture | {st['graphs']['secs']} s, {st['graphs']['gib']} GiB |")
    if st.get("mm_warmup_s") is not None:
        rows.append(f"| multi-modal warmup | {st['mm_warmup_s']} s |")
    if st.get("torch_threads"):
        rows.append(f"| torch threads | {st['torch_threads'][0]} → {st['torch_threads'][1]} |")
    if st.get("attn_block"):
        rows.append(f"| attention block size | {st['attn_block']} tokens |")
    if st.get("enc_budget"):
        rows.append(f"| encoder cache budget | {st['enc_budget']:,} tokens |")

    # PLE offload details (DGX Spark specific)
    if st.get("ple_table"):
        pt = st["ple_table"]
        rows.append(f"| PLE n-gram table | {pt['rows']:,} rows × {pt['bytes']} B = {pt['gib']} GiB (mmap) |")
    if st.get("ple_match"):
        pm = st["ple_match"]
        rows.append(f"| PLE offload | matched {pm['tensors']} tensors, {pm['entries']} entries |")
    if st.get("ple_done"):
        rows.append("| PLE weight load | complete |")
    if st.get("sampling_override"):
        rows.append(f"| sampling override | {st['sampling_override']} |")

    if rows:
        L.extend(["| field | value |", "|---|---|"] + rows + [""])
    else:
        L.append("_no startup lines found_\n")
    return L


def _render_requests_section(accesses: list[AccessLogEntry], engines: list[EngineSample]) -> list[str]:
    """Render Section 2: Active serving windows and Uvicorn HTTP access statistics."""
    L: list[str] = [
        "## 2. Requests\n",
        "_vLLM INFO logs carry no per-request token counts; a request is only visible "
        "via its HTTP access line and the engine's `Running` gauge._\n",
        "### 2.1 Active-serving windows\n",
        "Consecutive engine samples with `Running > 0` (samples are ~10 s apart).\n",
    ]

    wins = activity_windows(engines)
    if wins:
        L.append("| # | start | end | samples | est. span | peak running |")
        L.append("|---|---|---|---|---|---|")
        for i, w in enumerate(wins, 1):
            L.append(f"| {i} | {_fmt_ts(w['start'])} | {_fmt_ts(w['end'])} | {w['n']} | {w['dur']:.0f} s | {w['peak']} |")
        L.append("")
    else:
        L.append("_no active-serving samples_\n")

    L.append("### 2.2 HTTP access summary\n")
    if accesses:
        c = Counter((x["method"], x["path"], x["status"]) for x in accesses)
        L.append("| method | path | status | count |")
        L.append("|---|---|---|---|")
        for (m, p, s), cnt in sorted(c.items(), key=lambda kv: (-kv[1], kv[0])):
            L.append(f"| {m} | `{p}` | {s} | {cnt} |")

        fails = [x for x in accesses if x["status"] >= 400]
        L.append("")
        if fails:
            L.append(f"**Failures (status ≥ 400): {len(fails)}**\n")
            L.append("| # | method | path | status | reason |")
            L.append("|---|---|---|---|---|")
            for x in fails:
                L.append(f"| {x['seq']} | {x['method']} | `{x['path']}` | {x['status']} | {x['reason']} |")
            L.append("")
        else:
            L.append("_no HTTP failures_\n")
    else:
        L.append("_no access lines_\n")
    return L


def _render_timeline_section(engines: list[EngineSample], specs: list[SpecSample]) -> list[str]:
    """Render Section 3: Paired 10-second engine throughput and MTP speculative timeline."""
    L: list[str] = [
        "## 3. Engine & speculative-decode timeline\n",
        "One row per 10 s engine sample; the companion SpecDecoding line is joined on "
        "the same timestamp (`—` when that interval had no speculation).\n",
        "| time | prompt t/s | gen t/s | run | wait | KV% | prefix% | acc-len | acc t/s | draft t/s | acc tok | draft tok | pos1 | pos2 | pos3 | draft acc% |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]

    spec_by_ts = {s["ts"]: s for s in specs}
    for e in engines:
        s = spec_by_ts.get(e["ts"])
        if s:
            spec_cells = (
                f"{s['acc_len']:.2f} | {s['acc_tps']:.1f} | {s['draft_tps']:.1f} | "
                f"{s['accepted']} | {s['drafted']} | {s['p1']:.3f} | {s['p2']:.3f} | {s['p3']:.3f} | {s['draft_acc']:.1f}"
            )
        else:
            spec_cells = "— | — | — | — | — | — | — | — | —"  # 9 dash columns
        L.append(
            f"| {_fmt_ts(e['ts'])} | {e['prompt']:.1f} | {e['gen']:.1f} | {e['running']} | {e['waiting']} | "
            f"{e['kv']:.1f} | {e['prefix']:.1f} | {spec_cells} |"
        )
    L.append("")
    return L


def _render_aggregates_section(d: ParsedLog) -> list[str]:
    """Render Section 4: Aggregate session throughput, speculative decoding, and KV cache distribution."""
    L: list[str] = ["## 4. Aggregate statistics\n", "### 4.1 Session & throughput\n"]
    ss = single_session(d)

    if ss:
        L.extend([
            "| metric | value |",
            "|---|---|",
            f"| engine samples | {ss['n_samples']} |",
            f"| sample window | {_fmt_ts(ss['first_sample'])} → {_fmt_ts(ss['last_sample'])} ({ss['span']:.0f} s) |",
            f"| peak prompt throughput | {ss['peak_prompt']:.1f} tok/s |",
            f"| peak generation throughput | {ss['peak_gen']:.1f} tok/s |",
            (f"| mean generation throughput (busy samples) | {ss['mean_gen_busy']:.1f} tok/s |"
             if ss["mean_gen_busy"] is not None else "| mean generation throughput (busy) | — |"),
            f"| busy samples (gen > 0) | {ss['busy_samples']} / {ss['n_samples']} |",
            f"| active-serving windows | {ss['n_active_windows']} |",
            f"| serving window (first→last active) | {ss['serving_span']:.0f} s |",
            "",
        ])
    else:
        L.append("_not enough data_\n")

    L.append("### 4.2 Speculative decoding\n")
    sp = d["specs"]
    if sp:
        tot_acc = sum(s["accepted"] for s in sp)
        tot_dr = sum(s["drafted"] for s in sp)
        ratio = 100.0 * tot_acc / tot_dr if tot_dr else 0.0
        L.extend([
            "| metric | n | mean | median | min | max | p95 | unit |",
            "|---|---|---|---|---|---|---|---|",
            stat_row("acceptance length", [s["acc_len"] for s in sp], "tok", 2),
            stat_row("draft acceptance rate", [s["draft_acc"] for s in sp], "%", 1),
            stat_row("accepted throughput", [s["acc_tps"] for s in sp], "tok/s", 1),
            stat_row("drafted throughput", [s["draft_tps"] for s in sp], "tok/s", 1),
            "",
            f"- per-position acceptance (mean): p1 = {mean([s['p1'] for s in sp]):.3f}, "
            f"p2 = {mean([s['p2'] for s in sp]):.3f}, p3 = {mean([s['p3'] for s in sp]):.3f}",
            f"- session totals: **{tot_acc}** accepted / **{tot_dr}** drafted tokens "
            f"→ {ratio:.1f}% overall acceptance",
            "",
        ])
    else:
        L.append("_no SpecDecoding samples (speculative decoding off)_\n")

    L.append("### 4.3 KV cache & concurrency\n")
    eng = d["engines"]
    if eng:
        dist = Counter(e["running"] for e in eng)
        mm_vals = [e["mm"] for e in eng if e["mm"] is not None]
        pv = [e["prefix"] for e in eng]
        L.extend([
            "| metric | value |",
            "|---|---|",
            f"| peak GPU KV cache usage | {max(e['kv'] for e in eng):.1f}% |",
            f"| prefix cache hit rate | {min(pv):.1f}% – {max(pv):.1f}% (mean {mean(pv):.1f}%) |",
        ])
        if mm_vals:
            L.append(f"| MM cache hit rate (mean) | {mean(mm_vals):.1f}% |")
        L.extend([
            f"| concurrency distribution | " + ", ".join(f"{k} req(s): {v}" for k, v in sorted(dist.items())) + " |",
            "",
        ])
    else:
        L.append("_no engine samples_\n")
    return L


def _render_warnings_section(warnings: list[WarningEntry], jit: list[JitEntry], accesses: list[AccessLogEntry]) -> list[str]:
    """Render Section 5: Latency-critical Triton JIT spikes, HTTP failures, and deduplicated warnings."""
    L: list[str] = [
        "## 5. Warnings & errors\n",
        "### 5.1 JIT compilation during inference\n",
    ]

    if jit:
        L.extend([
            "First-use Triton kernels compiled mid-serve cause a one-time latency spike.\n",
            "| time | kernel |",
            "|---|---|",
        ])
        for j in jit:
            L.append(f"| {_fmt_ts(j['ts'])} | `{j['kernel']}` |")
        L.append("")
    else:
        L.append("_none_\n")

    L.append("### 5.2 HTTP failures\n")
    fails = [x for x in accesses if x["status"] >= 400]
    if fails:
        fc = Counter((x["method"], x["path"], x["status"]) for x in fails)
        for (m, p, s), cnt in sorted(fc.items()):
            L.append(f"- {m} `{p}` → {s} ({cnt}×)")
        L.append("")
    else:
        L.append("_none_\n")

    L.append("### 5.3 Other warnings (deduped)\n")
    if warnings:
        wc: dict[tuple[str, str], list[Any]] = {}
        for w in warnings:
            key = (w["level"], w["msg"])
            e = wc.setdefault(key, [0, w["ts"]])
            e[0] += 1
            e[1] = min(e[1], w["ts"])

        L.extend([
            "| level | count | first seen | message |",
            "|---|---|---|---|",
        ])
        for (level, msg), (cnt, first_ts) in sorted(wc.items(), key=lambda kv: (-kv[1][0], kv[0][1])):
            L.append(f"| {level} | {cnt} | {_fmt_ts(first_ts)} | {msg} |")
        L.append("")
    else:
        L.append("_none_\n")
    return L


def _render_noise_and_canary_section(
    noise: Counter[str],
    info_by_source: Counter[str],
    unrecognized: list[tuple[int, str]]
) -> list[str]:
    """Render Sections 6 (boilerplate noise classification) and 7 (canary unmatched lines)."""
    L: list[str] = ["## 6. Recognized noise (counted, not shown)\n"]
    boiler = {f: c for f, c in noise.items() if f != "vllm-info"}
    n_info = noise.get("vllm-info", 0)

    if not noise:
        L.append("_none_\n")
    else:
        if boiler:
            L.extend([
                "Repetitive warmup boilerplate, recognized so it doesn't pollute the S7 canary.\n",
                "| family | count |",
                "|---|---|",
            ])
            for fam, cnt in sorted(boiler.items(), key=lambda kv: -kv[1]):
                L.append(f"| {fam} | {cnt} |")
            L.append("")

        if n_info:
            L.extend([
                f"Benign one-line `INFO` facts without an individual matcher ({n_info} total), "
                f"grouped by source file:\n",
                "| source file | count |",
                "|---|---|",
            ])
            for sfile, cnt in sorted(info_by_source.items(), key=lambda kv: (-kv[1], kv[0])):
                L.append(f"| `{sfile}` | {cnt} |")
            L.append("")

    L.append("## 7. Unrecognized lines (canary)\n")
    if unrecognized:
        L.extend([
            f"{len(unrecognized)} lines did not match any known pattern — inspect these if they "
            f"look like a real (new) log format:\n",
            "```",
        ])
        for n, raw in unrecognized[:15]:
            L.append(f"L{n}: {raw}")
        if len(unrecognized) > 15:
            L.append(f"... and {len(unrecognized) - 15} more")
        L.append("```")
    else:
        L.append("_none — every line matched a known pattern_")

    return L


def build_report(d: ParsedLog, src: str) -> str:
    """Assemble the final Markdown performance report from parsed structures (sections S1-S7).

    Coordinates modular sub-renderers for each section to build a clean,
    deterministic Markdown document suitable for operator inspection and CI archiving.

    Args:
        d: ParsedLog output dict returned by parse().
        src: Name or path of the input log file.

    Returns:
        Full rendered Markdown report string.
    """
    lines: list[str] = []
    lines.extend(_render_header(d, src))
    lines.extend(_render_startup_section(d["startup"]))
    lines.extend(_render_requests_section(d["accesses"], d["engines"]))
    lines.extend(_render_timeline_section(d["engines"], d["specs"]))
    lines.extend(_render_aggregates_section(d))
    lines.extend(_render_warnings_section(d["warnings"], d["jit"], d["accesses"]))
    lines.extend(_render_noise_and_canary_section(d["noise"], d["info_by_source"], d["unrecognized"]))
    return "\n".join(lines) + "\n"


# =====================================================================
# CLI ENTRY POINT
# =====================================================================

def main() -> None:
    """CLI entrypoint: parse -> build_report -> write -> print summary."""
    ap = argparse.ArgumentParser(description="Parse a vLLM docker-log dump into a Markdown report.")
    ap.add_argument("log_file", help="Path to input raw vLLM log dump (.txt)")
    ap.add_argument("-o", "--output", default=None, help="Output markdown path (default: <input>.report.md)")
    args = ap.parse_args()

    out = args.output or (
        args.log_file[:-4] + ".report.md" if args.log_file.endswith(".txt") else args.log_file + ".report.md"
    )
    d = parse(args.log_file)
    report_content = build_report(d, args.log_file)

    with open(out, "w", encoding="utf-8") as f:
        f.write(report_content)

    print(
        f"wrote {out}  (lines={d['total']} engines={len(d['engines'])} specs={len(d['specs'])} "
        f"access={len(d['accesses'])} jit={len(d['jit'])} warnings={len(d['warnings'])} "
        f"noise={sum(d['noise'].values())} unrecognized={len(d['unrecognized'])})"
    )


if __name__ == "__main__":
    main()
