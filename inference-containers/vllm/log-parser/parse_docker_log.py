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
      A: `INFO 09-05 14:42:00 [loggers.py:310] <msg>`        (MM-DD, no year/ms)
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
* Pure stdlib (re / datetime / math / statistics / collections / argparse):
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
import argparse       # CLI: log path + optional -o output path
import math           # pctl() nearest-rank percentile (no numpy dependency)
import re             # line-grammar patterns defined below
import statistics     # mean/median for the S4 distribution tables
from collections import Counter
from datetime import datetime

# =====================================================================
# LINE-GRAMMAR PATTERNS
# =====================================================================
# PROCESS strips the optional "(Name pid=N) " tag that vLLM prefixes to most
# lines; banner/progress/noise lines have no tag (group 1 = None).
#
# TS_A / TS_B capture the two container-clock styles (see module docstring).
# TS_A groups: 1=level 2=mm 3=dd 4=hh 5=mi 6=ss 7=source 8=message
# TS_B groups: 1=yyyy 2=mm 3=dd 4=hh 5=mi 6=ss 7=mmm 8=level 9=source 10=message
#
# Keep in sync if vLLM changes its logger format; the S7 section
# (unrecognized lines) is the canary that tells you when they diverged.

PROCESS = re.compile(r"^\(([A-Za-z][A-Za-z0-9]*) pid=(\d+)\)\s?(.*)$")
TS_A    = re.compile(r"^([A-Z]+)\s+(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s+\[([^\]]+)\]\s+(.*)$")
TS_B    = re.compile(r"(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2}),(\d{3})\s+-\s+([A-Z]+)\s+-\s+([^\s-]+)\s+-\s+(.*)$")

# Engine sample (loggers.py): the headline 10 s throughput line.
#   g1=prompt tok/s g2=gen tok/s g3=running g4=waiting g5=KV % g6=prefix %
#   g7=MM % (optional, newer builds only)
ENG = re.compile(
    r"Engine \d+: Avg prompt throughput: ([\d.]+) tokens/s, "
    r"Avg generation throughput: ([\d.]+) tokens/s, "
    r"Running: (\d+) reqs, Waiting: (\d+) reqs, "
    r"GPU KV cache usage: ([\d.]+)%, Prefix cache hit rate: ([\d.]+)%"
    r"(?:, MM cache hit rate: ([\d.]+)%)?")

# SpecDecoding metrics (metrics.py): companion line, same timestamp as ENG.
#   g1=acc len g2=acc tok/s g3=draft tok/s g4=accepted g5=drafted
#   g6,g7,g8=per-position acceptance g9=avg draft acceptance %
SPEC = re.compile(
    r"SpecDecoding metrics: Mean acceptance length: ([\d.]+), "
    r"Accepted throughput: ([\d.]+) tokens/s, Drafted throughput: ([\d.]+) tokens/s, "
    r"Accepted: (\d+) tokens, Drafted: (\d+) tokens, "
    r"Per-position acceptance rate: ([\d.]+), ([\d.]+), ([\d.]+), "
    r"Avg Draft acceptance rate: ([\d.]+)%")

# Uvicorn access line (APIServer): the only request-level signal. NO timestamp.
#   g1=client ip:port g2=method g3=path g4=status g5=reason-phrase
ACC = re.compile(r'INFO:\s+(\S+:\d+)\s+-\s+"([A-Z]+) (\S+) HTTP/[\d.]+"\s+(\d{3})\s+(\w+)')

# Startup one-shot facts (all live on a TS_A line; message matched in handle_startup).
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

# JIT compilation during inference (a real perf signal: first-token latency spike).
JIT = re.compile(r"Triton kernel JIT compilation during inference: (\S+)\.")

# Known repetitive boilerplate. A line matching one of these is recognized and
# counted under its family name (S6) instead of landing in the S7 canary.
# Order matters only for reporting; the first match wins.
NOISE_RE = [
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
# SMALL HELPERS
# =====================================================================

def pctl(vals, p):
    """Nearest-rank percentile (p in 0..100), numpy-free.

    Ranks sorted values and picks index ceil(p/100 * n) - 1, clamped to
    [0, n-1] so p=0 -> min and p=100 -> max. Returns None for empty input.
    """
    if not vals:
        return None
    v = sorted(vals)
    return v[max(0, min(len(v) - 1, math.ceil(p / 100 * len(v)) - 1))]


def stat_row(label, vals, unit, nd=1):
    """Render one S4 table row: n / mean / median / min / max / p95.

    nd   = decimals (0 for tok/ms, 1 for tok/s and %).
    unit = free-text unit label; empty vals -> dash-filled row.
    """
    if not vals:
        return f"| {label} | 0 | — | — | — | — | — | {unit} |"
    return (f"| {label} | {len(vals)} | {sum(vals)/len(vals):.{nd}f} | {statistics.median(vals):.{nd}f} | "
            f"{min(vals):.{nd}f} | {max(vals):.{nd}f} | {pctl(vals, 95):.{nd}f} | {unit} |")


def mean(vals):
    return sum(vals) / len(vals) if vals else None


def noise_match(text):
    """Return the family name of the first matching NOISE_RE entry, else None."""
    for name, rx in NOISE_RE:
        if rx.search(text):
            return name
    return None


def extract_args(s):
    """Pull the few keys worth reporting out of the `non-default args` dict repr.

    The dict is too large to show verbatim and contains enum reprs
    (`<CompilationMode.NONE: 0>`) so it is not a valid Python literal; we
    regex each key of interest instead of parsing the whole thing.
    """
    def g(rx, cast=str):
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


def handle_startup(st, msg):
    """Record one-shot startup facts from a TS_A message. Return True on a hit.

    Each startup fact appears exactly once in a normal boot; we keep first
    wins for single-valued fields and append for the (rare) repeated ones
    (weights-load timing fires once per loader pass).
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
# PARSER
# =====================================================================

def parse(path):
    """Single pass over the log file; returns a dict of parsed structures.

    Returned keys (see build_report() for how each is rendered):
        startup      {version, model, arch[], args{}, kv_*, weights_took[],
                      model_load, init_engine_s, graphs, ple_*, server_url, ...}
        engines      [{ts, prompt, gen, running, waiting, kv, prefix, mm}, ...]  (log order)
        specs        [{ts, acc_len, acc_tps, draft_tps, accepted, drafted,
                      p1, p2, p3, draft_acc}, ...]  (log order)
        accesses     [{seq, client, method, path, status, reason}, ...]  (log order)
        jit          [{ts, kernel}, ...]
        warnings     [{level, ts, msg}, ...]  (pre-dedup; deduped at render)
        noise        Counter{family: count}
        info_by_source Counter{file.py: count}   # benign INFO lines (family "vllm-info")
        unrecognized [(line_no, raw), ...]  -> S7 canary
        total        non-empty line count
        first/last   min/max container timestamp seen (either style)
    """
    with open(path) as f:
        lines = f.read().splitlines()

    # Infer the year for style-A timestamps from the first full-date line.
    ym = re.search(r"\b(\d{4})-\d{2}-\d{2}\b", "\n".join(lines))
    year = int(ym.group(1)) if ym else datetime.now().year

    startup, engines, specs, accesses = {}, [], [], []
    jit, warnings = [], []
    noise, unrecognized = Counter(), []
    info_by_source = Counter()            # file.py -> count of benign INFO lines
    total, first, last = 0, None, None

    def track(t):
        nonlocal first, last
        first = t if first is None else min(first, t)
        last = t if last is None else max(last, t)

    for n, raw in enumerate(lines, 1):
        raw = raw.rstrip("\n")
        if not raw.strip():
            continue                       # blank lines skipped, not counted
        total += 1

        pm = PROCESS.match(raw)
        payload = pm.group(3) if pm else raw

        # A bare process tag with an empty payload is the first physical line of a
        # two-line progress-bar entry: the bar text (e.g. "Loading safetensors ...")
        # lands on the NEXT line, untagged. Count the orphan tag as noise so it
        # doesn't reach the S7 canary.
        if pm and not payload.strip():
            noise["tag-only-prefix"] += 1
            continue

        # ---- layer 1: vLLM logger line with a style-A timestamp -----------
        a = TS_A.match(payload)
        if a:
            level = a.group(1)
            ts = datetime(year, int(a.group(2)), int(a.group(3)),
                          int(a.group(4)), int(a.group(5)), int(a.group(6)))
            msg = a.group(8)
            track(ts)

            e = ENG.search(msg)
            if e:
                engines.append(dict(ts=ts, prompt=float(e[1]), gen=float(e[2]),
                                    running=int(e[3]), waiting=int(e[4]),
                                    kv=float(e[5]), prefix=float(e[6]),
                                    mm=float(e[7]) if e[7] is not None else None))
                continue
            s = SPEC.search(msg)
            if s:
                specs.append(dict(ts=ts, acc_len=float(s[1]), acc_tps=float(s[2]),
                                  draft_tps=float(s[3]), accepted=int(s[4]),
                                  drafted=int(s[5]), p1=float(s[6]), p2=float(s[7]),
                                  p3=float(s[8]), draft_acc=float(s[9])))
                continue
            j = JIT.search(msg)
            if j:
                jit.append(dict(ts=ts, kernel=j[1]))
                continue
            if handle_startup(startup, msg):
                continue
            fam = noise_match(msg)
            if fam:
                noise[fam] += 1
                continue
            if level in ("WARNING", "ERROR", "CRITICAL"):
                warnings.append(dict(level=level, ts=ts, msg=msg))
            else:
                # Benign one-line INFO facts we don't model individually (config
                # echoes, kernel/backend selection, model-runner notes, ...).
                # They are EXPECTED in any vLLM boot+serve log, so counting them
                # here (with a per-source-file breakdown in S6) keeps the S7
                # canary reserved for genuinely unexpected structures.
                noise["vllm-info"] += 1
                info_by_source[a.group(7).rsplit(":", 1)[0]] += 1
            continue

        # ---- layer 2: full-date (style-B) line -> FlashInfer autotuner ------
        b = TS_B.search(payload)
        if b:
            ts = datetime(int(b.group(1)), int(b.group(2)), int(b.group(3)),
                          int(b.group(4)), int(b.group(5)), int(b.group(6)),
                          int(b.group(7)) * 1000)
            track(ts)
            noise["autotuner"] += 1
            continue

        # ---- layer 3: no timestamp ----------------------------------------
        acc = ACC.search(payload)
        if acc:
            accesses.append(dict(seq=len(accesses) + 1, client=acc[1], method=acc[2],
                                 path=acc[3], status=int(acc[4]), reason=acc[5]))
            continue
        fam = noise_match(payload)
        if fam:
            noise[fam] += 1
            continue
        unrecognized.append((n, raw))

    return dict(startup=startup, engines=engines, specs=specs, accesses=accesses,
                jit=jit, warnings=warnings, noise=noise, info_by_source=info_by_source,
                unrecognized=unrecognized,
                total=total, first=first, last=last)


# =====================================================================
# SESSION AGGREGATES
# =====================================================================

def activity_windows(engines):
    """Collapse the engine samples into contiguous active-serving windows.

    A window is a run of consecutive samples with Running > 0. Because samples
    are ~10 s apart, a window's span is (n-1) * interval; we report the first
    and last sample timestamps plus the sample count and peak concurrency.
    """
    wins, cur = [], None
    for e in engines:
        if e["running"] > 0:
            if cur is None:
                cur = dict(start=e["ts"], end=e["ts"], n=1, peak=e["running"])
            else:
                cur["end"] = e["ts"]; cur["n"] += 1
                cur["peak"] = max(cur["peak"], e["running"])
        else:
            if cur:
                wins.append(cur); cur = None
    if cur:
        wins.append(cur)
    for w in wins:
        w["dur"] = (w["end"] - w["start"]).total_seconds()
    return wins


def single_session(d):
    """Compute the S4.1 session / throughput numbers from the engine samples.

    vLLM does not log total token counts, so "throughput" here means the
    per-sample rate averages. Busy samples = generation throughput > 0.
    The serving window is the first->last sample with Running > 0.
    """
    eng = d["engines"]
    if not eng:
        return None
    busy = [e for e in eng if e["gen"] > 0]
    run = [e for e in eng if e["running"] > 0]
    serving_span = (max(e["ts"] for e in run) - min(e["ts"] for e in run)).total_seconds() if run else 0.0
    return dict(
        n_samples=len(eng),
        first_sample=eng[0]["ts"], last_sample=eng[-1]["ts"],
        span=(eng[-1]["ts"] - eng[0]["ts"]).total_seconds(),
        peak_gen=max(e["gen"] for e in eng),
        peak_prompt=max(e["prompt"] for e in eng),
        mean_gen_busy=mean([e["gen"] for e in busy]),
        busy_samples=len(busy),
        serving_span=serving_span,
        n_active_windows=len(activity_windows(eng)))


# =====================================================================
# REPORT BUILDER
# =====================================================================

def build_report(d, src):
    """Assemble the final Markdown string from parse() output (sections S1-S7)."""
    L = []
    st = d["startup"]
    ts = lambda t: t.strftime("%H:%M:%S") if t else "—"

    # ---- header / summary line -------------------------------------------
    L.append(f"# vLLM Docker Log Report — `{src}`\n")
    L.append(f"- generated: {datetime.now():%Y-%m-%d %H:%M:%S}")
    rng = f"{d['first']:%Y-%m-%d %H:%M:%S} → {d['last']:%Y-%m-%d %H:%M:%S}" if d['first'] else "n/a"
    L.append(f"- input lines: {d['total']} | log range: {rng} (container clock)")
    L.append(f"- engine samples: {len(d['engines'])} | spec samples: {len(d['specs'])} | "
             f"http access: {len(d['accesses'])} | warnings: {len(d['warnings'])} | "
             f"noise families: {sum(d['noise'].values())}\n")

    # ---- S1 startup facts -------------------------------------------------
    L.append("## 1. Startup\n")
    rows = []
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
    # non-default args (selected keys)
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
        rows += arows
    # engine-level toggles captured from the engine-config line
    for k, lab in (("prefix_caching", "prefix caching"), ("chunked_prefill", "chunked prefill"),
                   ("dtype", "dtype")):
        if st.get(k) is not None:
            rows.append(f"| {lab} | `{st[k]}` |")
    if st.get("max_len"):
        rows.append(f"| max model len | {st['max_len']:,} |")
    # KV sizing
    if st.get("kv_avail") is not None:
        rows.append(f"| available KV memory | {st['kv_avail']} GiB |")
    if st.get("kv_tokens"):
        rows.append(f"| GPU KV cache size | {st['kv_tokens']:,} tokens (max concurrency {st.get('kv_concurrency', '—')}× for {st.get('max_len', st.get('args', {}).get('max_model_len', '?')):,} tok/req) |")
    # timings
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
    # PLE offload
    if st.get("ple_table"):
        pt = st["ple_table"]
        rows.append(f"| PLE n-gram table | {pt['rows']:,} rows × {pt['bytes']} B = {pt['gib']} GiB (mmap) |")
    if st.get("ple_match"):
        pm = st["ple_match"]
        rows.append(f"| PLE offload | matched {pm['tensors']} tensors, {pm['entries']} entries |")
    if st.get("ple_done"):
        rows.append(f"| PLE weight load | complete |")
    if st.get("sampling_override"):
        rows.append(f"| sampling override | {st['sampling_override']} |")
    if rows:
        L += ["| field | value |", "|---|---|"] + rows + [""]
    else:
        L.append("_no startup lines found_\n")

    # ---- S2 requests ------------------------------------------------------
    L.append("## 2. Requests\n")
    L.append("_vLLM INFO logs carry no per-request token counts; a request is only visible "
             "via its HTTP access line and the engine's `Running` gauge._\n")
    L.append("### 2.1 Active-serving windows\n")
    L.append("Consecutive engine samples with `Running > 0` (samples are ~10 s apart).\n")
    wins = activity_windows(d["engines"])
    if wins:
        L.append("| # | start | end | samples | est. span | peak running |")
        L.append("|---|---|---|---|---|---|")
        for i, w in enumerate(wins, 1):
            L.append(f"| {i} | {ts(w['start'])} | {ts(w['end'])} | {w['n']} | {w['dur']:.0f} s | {w['peak']} |")
        L.append("")
    else:
        L.append("_no active-serving samples_\n")

    L.append("### 2.2 HTTP access summary\n")
    acc = d["accesses"]
    if acc:
        c = Counter((x["method"], x["path"], x["status"]) for x in acc)
        L.append("| method | path | status | count |")
        L.append("|---|---|---|---|")
        for (m, p, s), cnt in sorted(c.items(), key=lambda kv: (-kv[1], kv[0])):
            L.append(f"| {m} | `{p}` | {s} | {cnt} |")
        fails = [x for x in acc if x["status"] >= 400]
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

    # ---- S3 timeline (engine + spec, paired by timestamp) -----------------
    L.append("## 3. Engine & speculative-decode timeline\n")
    L.append("One row per 10 s engine sample; the companion SpecDecoding line is joined on "
             "the same timestamp (`—` when that interval had no speculation).\n")
    spec_by_ts = {s["ts"]: s for s in d["specs"]}
    L.append("| time | prompt t/s | gen t/s | run | wait | KV% | prefix% | acc-len | acc t/s | draft t/s | acc tok | draft tok | pos1 | pos2 | pos3 | draft acc% |")
    L.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for e in d["engines"]:
        s = spec_by_ts.get(e["ts"])
        if s:
            spec_cells = (f"{s['acc_len']:.2f} | {s['acc_tps']:.1f} | {s['draft_tps']:.1f} | "
                          f"{s['accepted']} | {s['drafted']} | {s['p1']:.3f} | {s['p2']:.3f} | {s['p3']:.3f} | {s['draft_acc']:.1f}")
        else:
            spec_cells = "— | — | — | — | — | — | — | — | —"   # 9 dash columns
        L.append(f"| {ts(e['ts'])} | {e['prompt']:.1f} | {e['gen']:.1f} | {e['running']} | {e['waiting']} | "
                 f"{e['kv']:.1f} | {e['prefix']:.1f} | {spec_cells} |")
    L.append("")

    # ---- S4 aggregates ----------------------------------------------------
    L.append("## 4. Aggregate statistics\n")
    L.append("### 4.1 Session & throughput\n")
    ss = single_session(d)
    if ss:
        L += ["| metric | value |", "|---|---|",
              f"| engine samples | {ss['n_samples']} |",
              f"| sample window | {ts(ss['first_sample'])} → {ts(ss['last_sample'])} ({ss['span']:.0f} s) |",
              f"| peak prompt throughput | {ss['peak_prompt']:.1f} tok/s |",
              f"| peak generation throughput | {ss['peak_gen']:.1f} tok/s |",
              f"| mean generation throughput (busy samples) | {ss['mean_gen_busy']:.1f} tok/s |" if ss["mean_gen_busy"] is not None else "| mean generation throughput (busy) | — |",
              f"| busy samples (gen > 0) | {ss['busy_samples']} / {ss['n_samples']} |",
              f"| active-serving windows | {ss['n_active_windows']} |",
              f"| serving window (first→last active) | {ss['serving_span']:.0f} s |",
              ""]
    else:
        L.append("_not enough data_\n")

    L.append("### 4.2 Speculative decoding\n")
    sp = d["specs"]
    if sp:
        tot_acc = sum(s["accepted"] for s in sp)
        tot_dr = sum(s["drafted"] for s in sp)
        ratio = 100.0 * tot_acc / tot_dr if tot_dr else 0.0
        L.append("| metric | n | mean | median | min | max | p95 | unit |")
        L.append("|---|---|---|---|---|---|---|---|")
        L.append(stat_row("acceptance length", [s["acc_len"] for s in sp], "tok", 2))
        L.append(stat_row("draft acceptance rate", [s["draft_acc"] for s in sp], "%", 1))
        L.append(stat_row("accepted throughput", [s["acc_tps"] for s in sp], "tok/s", 1))
        L.append(stat_row("drafted throughput", [s["draft_tps"] for s in sp], "tok/s", 1))
        L.append("")
        L.append(f"- per-position acceptance (mean): p1 = {mean([s['p1'] for s in sp]):.3f}, "
                 f"p2 = {mean([s['p2'] for s in sp]):.3f}, p3 = {mean([s['p3'] for s in sp]):.3f}")
        L.append(f"- session totals: **{tot_acc}** accepted / **{tot_dr}** drafted tokens "
                 f"→ {ratio:.1f}% overall acceptance")
        L.append("")
    else:
        L.append("_no SpecDecoding samples (speculative decoding off)_\n")

    L.append("### 4.3 KV cache & concurrency\n")
    eng = d["engines"]
    if eng:
        dist = Counter(e["running"] for e in eng)
        mm_vals = [e["mm"] for e in eng if e["mm"] is not None]
        L.append("| metric | value |")
        L.append("|---|---|")
        L.append(f"| peak GPU KV cache usage | {max(e['kv'] for e in eng):.1f}% |")
        pv = [e["prefix"] for e in eng]
        L.append(f"| prefix cache hit rate | {min(pv):.1f}% – {max(pv):.1f}% (mean {mean(pv):.1f}%) |")
        if mm_vals:
            L.append(f"| MM cache hit rate (mean) | {mean(mm_vals):.1f}% |")
        L.append(f"| concurrency distribution | " +
                 ", ".join(f"{k} req(s): {v}" for k, v in sorted(dist.items())) + " |")
        L.append("")
    else:
        L.append("_no engine samples_\n")

    # ---- S5 warnings & errors --------------------------------------------
    L.append("## 5. Warnings & errors\n")
    L.append("### 5.1 JIT compilation during inference\n")
    if d["jit"]:
        L.append("First-use Triton kernels compiled mid-serve cause a one-time latency spike.\n")
        L.append("| time | kernel |")
        L.append("|---|---|")
        for j in d["jit"]:
            L.append(f"| {ts(j['ts'])} | `{j['kernel']}` |")
        L.append("")
    else:
        L.append("_none_\n")

    L.append("### 5.2 HTTP failures\n")
    fails = [x for x in d["accesses"] if x["status"] >= 400]
    if fails:
        fc = Counter((x["method"], x["path"], x["status"]) for x in fails)
        for (m, p, s), cnt in sorted(fc.items()):
            L.append(f"- {m} `{p}` → {s} ({cnt}×)")
        L.append("")
    else:
        L.append("_none_\n")

    L.append("### 5.3 Other warnings (deduped)\n")
    if d["warnings"]:
        wc = {}
        for w in d["warnings"]:
            key = (w["level"], w["msg"])
            e = wc.setdefault(key, [0, w["ts"]])
            e[0] += 1
            e[1] = min(e[1], w["ts"])
        L.append("| level | count | first seen | message |")
        L.append("|---|---|---|---|")
        for (level, msg), (cnt, first_ts) in sorted(wc.items(), key=lambda kv: (-kv[1][0], kv[0][1])):
            L.append(f"| {level} | {cnt} | {ts(first_ts)} | {msg} |")
        L.append("")
    else:
        L.append("_none_\n")

    # ---- S6 recognized noise ---------------------------------------------
    L.append("## 6. Recognized noise (counted, not shown)\n")
    boiler = {f: c for f, c in d["noise"].items() if f != "vllm-info"}
    n_info = d["noise"].get("vllm-info", 0)
    if not d["noise"]:
        L.append("_none_\n")
    else:
        if boiler:
            L.append("Repetitive warmup boilerplate, recognized so it doesn't pollute "
                     "the S7 canary.\n")
            L.append("| family | count |")
            L.append("|---|---|")
            for fam, cnt in sorted(boiler.items(), key=lambda kv: -kv[1]):
                L.append(f"| {fam} | {cnt} |")
            L.append("")
        if n_info:
            src = d.get("info_by_source", Counter())
            L.append(f"Benign one-line `INFO` facts without an individual matcher "
                     f"({n_info} total), grouped by source file:\n")
            L.append("| source file | count |")
            L.append("|---|---|")
            for sfile, cnt in sorted(src.items(), key=lambda kv: (-kv[1], kv[0])):
                L.append(f"| `{sfile}` | {cnt} |")
            L.append("")

    # ---- S7 unrecognized lines (the canary) --------------------------------
    L.append("## 7. Unrecognized lines (canary)\n")
    u = d["unrecognized"]
    if u:
        L.append(f"{len(u)} lines did not match any known pattern — inspect these if they "
                 "look like a real (new) log format:\n")
        L.append("```")
        for n, raw in u[:15]:
            L.append(f"L{n}: {raw}")
        if len(u) > 15:
            L.append(f"... and {len(u)-15} more")
        L.append("```")
    else:
        L.append("_none — every line matched a known pattern_")
    return "\n".join(L) + "\n"


# =====================================================================
# CLI ENTRY POINT
# =====================================================================

def main():
    """parse -> build_report -> write -> print a one-line count summary.

    The printed counts double as a quick sanity check: compare them with
    `grep -c "Engine 000:"`, `grep -c "SpecDecoding metrics"`,
    `grep -cE '"[A-Z]+ .+ HTTP/"'` and `grep -c "JIT compilation during inference"`
    on the raw log to confirm nothing was misclassified.
    """
    ap = argparse.ArgumentParser(description="Parse a vLLM docker-log dump into a Markdown report.")
    ap.add_argument("log_file")
    ap.add_argument("-o", "--output", default=None, help="output markdown (default: <input>.report.md)")
    a = ap.parse_args()
    out = a.output or (a.log_file[:-4] + ".report.md" if a.log_file.endswith(".txt") else a.log_file + ".report.md")
    d = parse(a.log_file)
    with open(out, "w") as f:
        f.write(build_report(d, a.log_file))
    print(f"wrote {out}  (lines={d['total']} engines={len(d['engines'])} specs={len(d['specs'])} "
          f"access={len(d['accesses'])} jit={len(d['jit'])} warnings={len(d['warnings'])} "
          f"noise={sum(d['noise'].values())} unrecognized={len(d['unrecognized'])})")


if __name__ == "__main__":
    main()