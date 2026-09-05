#!/usr/bin/env python3
"""NInfer docker-log -> Markdown performance report.

WHAT THIS TOOL DOES
===================
Takes a raw `docker logs <container>` dump of the NInfer serve container
(NVFP4 Qwen3.8-27B on the RTX 5090) and turns it into one self-contained
Markdown report:

    S1  Startup       - model load time, endpoint, KV arena sizing
    S2  Per-request   - one row per request (submitted + done, paired by req id)
    S3  Timeline      - the 5-second throughput-interval samples, verbatim
    S4  Aggregates    - single-session performance, per-request distributions,
                        KV-reuse mode breakdown, speculative-decode vs prompt size
    S5  Errors        - every "[req N] error ..." line
    S6  Unrecognized  - every line no pattern matched. THIS IS THE CANARY:
                        if S6 grows, the log format changed and a pattern
                        below needs updating.

INPUT LINE GRAMMAR
==================
Every non-empty log line looks like:

    <host-timestamp> | <payload>

The payload is one of:

    [2026-08-25 20:04:48.367] [info] ninfer-serve: [req 1] openai_chat_completions stream msgs=2 max_tokens=32000 tool_history=no
    [2026-08-25 20:04:51.428] [info] ninfer-serve: [req 1] done finish=stop_token prompt=4120 gen=356 cache=0 reuse=full_reset ttft=645ms prefill=6483.9tok/s decode=147.2tok/s wall=3.06s speculative=mtp 2.73tok/round (57.7%)
    [2026-08-25 20:04:55.000] [info] ninfer-serve: throughput interval=5.0s prefill=... decode=... running=1 ...
    ============ NVIDIA banner / weight-load progress (boilerplate, -> S6)

TWO CLOCKS: the *host* timestamp left of the "|" is written by `docker logs`;
the *inner* timestamp in the brackets is the container's own clock. They drift
(UTC offset / NTP). The INNER timestamp is the source of truth for all timing
math in this file; lines without one (bare banner lines) fall back to host.

DESIGN DECISIONS
================
* Pure stdlib (re / datetime / math / statistics / argparse): no pip packages,
  so the conda env is reproducible with zero network dependencies.
* Request pairing: `submitted` and `done` lines are keyed by the integer
  request id "[req N]", so a request that errored still shows up if it also
  emitted a `done ... finish=cancelled` line (req 31, client disconnected).
* Nothing is silently dropped: any line matching the outer "| " format but no
  message pattern lands in S6 with its 1-based line number.

USAGE
=====
    python3 parse_docker_log.py <log_file> [-o output.md]
    # default output: <log_file>.report.md (01_docker_logs.txt -> ...report.md)
"""
import argparse    # CLI: log path + optional -o output path
import math        # pctl() nearest-rank percentile (no numpy dependency)
import re          # line-grammar patterns defined below
import statistics  # median for the S4.2 distribution table
from datetime import datetime  # timestamp parsing + session-span math

# =====================================================================
# LINE-GRAMMAR PATTERNS
# =====================================================================
# LINE / INNER split the raw line into (timestamp, message); the rest match
# against the message only. Group numbers referenced below (d[1], d[4]...)
# are the capture groups of these patterns, in order.
# Keep in sync if ninfer-serve changes its log format; report section S6
# (unrecognized lines) is the canary that tells you when they diverged.

LINE   = re.compile(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\s*\|\s*(.*)$")
#   <host-ts> | <payload>  -- splits every raw line; host ts = docker's clock
INNER  = re.compile(r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]\s*\[\w+\]\s*ninfer-serve:\s*(.*)$")
#   [inner-ts] [level] ninfer-serve: <msg>  -- inner ts = container's clock
DONE   = re.compile(r"\[req (\d+)\] done finish=(\w+)(?: tool_calls=(\d+))? prompt=(\d+) gen=(\d+) cache=(\d+) reuse=(\w+) ttft=(\d+)ms prefill=([\d.]+)tok/s decode=([\d.]+)tok/s wall=([\d.]+)s")
#   request completion. g1=req  g2=finish(stop_token|tool_calls|cancelled)
#   g3=tool_calls (optional)  g4=prompt tok  g5=gen tok  g6=cached tok
#   g7=reuse mode  g8=ttft ms  g9=prefill tok/s  g10=decode tok/s  g11=wall s
SUB    = re.compile(r"\[req (\d+)\] (\w+) stream msgs=(\d+) max_tokens=(\d+)")
#   request submission. g1=req  g2=api method (openai_chat_completions)
#   g3=messages in the prompt  g4=max_tokens the client allowed
SUB_TH = re.compile(r"tool_history=(\w+)")
#   optional tail of the SUB line: whether the KV frontier was kept (yes/no)
SPEC   = re.compile(r"speculative=\S+ ([\d.]+)tok/round \(([\d.]+)%\)")
#   optional tail of the DONE line: MTP acceptance: g1=tok/round g2=accept %
THR    = re.compile(r"throughput interval=([\d.]+)s prefill=([\d.]+)tok/s decode=([\d.]+)tok/s running=(\d+) prefilling=(\d+) decode_ready=(\d+) waiting=(\d+) avg_decode_batch=([\d.]+|n/a)")
#   periodic 5s server sample: g1=interval g2=prefill g3=decode g4..g7=queues
#   g8=avg decode batch ("n/a" when the decode queue was empty that interval)
ERR    = re.compile(r"\[req (\d+)\] error (.*)$")
#   request failure, e.g. "client disconnected"; a done line may still follow
KV     = re.compile(r"KV capacity auto resolved=(\d+) tokens pages=(\d+)/(\d+) runtime=([\d.]+) GiB free-after-weights=([\d.]+) GiB free-after-startup=([\d.]+) GiB headroom=([\d.]+) GiB slack=([\d.]+) GiB")
#   boot-time KV arena sizing (max_concurrency * max_context/64 pages)
LOADED = re.compile(r"model loaded in ([\d.]+) s")
#   boot: total weight-load time
LISTEN = re.compile(r"listening on (\S+) \(model id: ([\w.-]+), auth: (\w+)\)")
#   boot: serve endpoint + registered model id + auth mode
BUCKETS = [("<10k", 0, 10000), ("10-30k", 10000, 30000), ("30-60k", 30000, 60000), (">60k", 60000, 10**9)]
#   prompt-size buckets for the S4.4 speculative-decoding table


# =====================================================================
# SMALL HELPERS
# =====================================================================

def pctl(vals, p):
    """Nearest-rank percentile (p in 0..100), numpy-free.

    Ranks sorted values and picks index ceil(p/100 * n) - 1, clamped to
    [0, n-1] so p=0 -> min and p=100 -> max. Returns None for empty
    input so callers can render a dash instead of crashing.
    """
    if not vals:
        return None
    v = sorted(vals)
    return v[max(0, min(len(v) - 1, math.ceil(p / 100 * len(v)) - 1))]


def stat_row(label, vals, unit, nd=1):
    """Render one S4.2 table row: n / mean / median / min / max / p95.

    nd  = decimals to show (0 for ms/tokens, 1 for tok/s and %, 2 for s)
    unit = free-text unit label; empty vals -> dash-filled row.
    """
    if not vals:
        return f"| {label} | 0 | — | — | — | — | — | {unit} |"
    return (f"| {label} | {len(vals)} | {sum(vals)/len(vals):.{nd}f} | {statistics.median(vals):.{nd}f} | "
            f"{min(vals):.{nd}f} | {max(vals):.{nd}f} | {pctl(vals, 95):.{nd}f} | {unit} |")


# =====================================================================
# PARSER
# =====================================================================

def parse(path):
    """Single pass over the log file; returns a dict of parsed structures.

    Returned keys (see build_report() for how each is rendered):
        subs         {req_id: {req, msgs, max_tokens, tool_history, ts}}
        dones        {req_id: {req, finish, tool_calls, prompt, gen, cache,
                               reuse, ttft_ms, prefill, decode, wall,
                               spec_tr, spec_pct, ts}}
        thrs         [{ts, interval, prefill, decode, running, prefilling,
                       decode_ready, waiting, batch}, ...]  (log order)
        errs         [{req, what, ts}, ...]
        kv           boot-time KV arena facts (dict or None)
        loaded       model load time in seconds (float or None)
        listen       {url, model, auth} (dict or None)
        unrecognized [(line_no, raw_text), ...]  -> report section S6
        total        non-empty line count
        first/last   min/max inner timestamp seen (container clock)

    All timestamps are the INNER (container) clock; host clock is only used
    as a fallback for banner lines that lack an inner timestamp.
    """
    # Requests keyed by id so a `done` line can be joined to its (much
    # earlier) `submitted` line; thrs/errs keep log order (they're a timeline).
    subs, dones, thrs, errs = {}, {}, [], []
    kv = loaded = listen = None      # single-valued boot facts (last wins;
                                      # in practice each appears exactly once)
    unrecognized, total = [], 0      # S6 canary + non-empty line count
    first, last = None, None         # log-range bounds on the inner clock
    with open(path) as f:
        for n, raw in enumerate(f, 1):
            raw = raw.rstrip("\n")
            if not raw.strip():
                continue             # blank lines are skipped, not counted
            total += 1

            # -- layer 1: split "<host-ts> | <payload>" ----------------------
            m = LINE.match(raw)
            if not m:
                # No host timestamp at all (wrapped banner continuation):
                # capture it for S6 rather than dropping it.
                unrecognized.append((n, raw))
                continue
            host, rest = m.groups()

            # -- layer 2: split "[inner-ts] [level] ninfer-serve: <msg>" -----
            # Bare banner payloads have no inner ts -> fall back to host ts.
            im = INNER.match(rest)
            ts, msg = (im.group(1), im.group(2)) if im else (host, rest.strip())
            if not msg:
                continue             # timestamp with an empty payload
            t = datetime.strptime(ts, "%Y-%m-%d %H:%M:%S.%f")
            first = t if first is None else min(first, t)   # track range
            last = t if last is None else max(last, t)

            # -- layer 3: classify the message -------------------------------
            # Most-specific anchor first; `continue` at the first hit means
            # each line is counted exactly once.
            d = DONE.search(msg)
            if d:
                # "[req N] done ..." — completion line. SPEC is an optional
                # trailing fragment on the same line -> separate search.
                sm = SPEC.search(msg)
                dones[int(d[1])] = dict(req=int(d[1]), finish=d[2], tool_calls=d[3],
                                        prompt=int(d[4]), gen=int(d[5]), cache=int(d[6]),
                                        reuse=d[7], ttft_ms=int(d[8]), prefill=float(d[9]),
                                        decode=float(d[10]), wall=float(d[11]),
                                        spec_tr=float(sm[1]) if sm else None,
                                        spec_pct=float(sm[2]) if sm else None, ts=t)
                continue
            s = SUB.search(msg)
            if s:
                # "[req N] <method> stream ..." — submission line; pair it
                # with its done line later via the shared req id.
                th = SUB_TH.search(msg)
                subs[int(s[1])] = dict(req=int(s[1]), msgs=int(s[3]),
                                       max_tokens=int(s[4]),
                                       tool_history=th.group(1) if th else "?", ts=t)
                continue
            p = THR.search(msg)
            if p:
                # 5s periodic sample; appended in log order, no dedup.
                thrs.append(dict(ts=t, interval=float(p[1]), prefill=float(p[2]),
                                 decode=float(p[3]), running=int(p[4]), prefilling=int(p[5]),
                                 decode_ready=int(p[6]), waiting=int(p[7]), batch=p[8]))
                continue
            e = ERR.search(msg)
            if e:
                # Failure line; keep req id so S2/S5 can cross-reference it.
                errs.append(dict(req=int(e[1]), what=e[2], ts=t))
                continue
            k = KV.search(msg)
            if k:
                # Boot-time KV arena sizing (one-shot).
                kv = dict(tokens=int(k[1]), pages=k[2], pages_max=k[3], runtime=k[4],
                          free_weights=k[5], free_startup=k[6], headroom=k[7], slack=k[8])
                continue
            l = LOADED.search(msg)
            if l:
                # Boot: weight-load time (one-shot).
                loaded = float(l[1])
                continue
            ls = LISTEN.search(msg)
            if ls:
                # Boot: endpoint / model id / auth (one-shot).
                listen = dict(url=ls[1], model=ls[2], auth=ls[3])
                continue
            # Fallback: outer format matched but no message pattern did ->
            # section S6 (canary; never silently dropped).
            unrecognized.append((n, raw))
    return dict(subs=subs, dones=dones, thrs=thrs, errs=errs, kv=kv, loaded=loaded,
                listen=listen, unrecognized=unrecognized, total=total, first=first, last=last)


# =====================================================================
# SESSION AGGREGATES
# =====================================================================

def single_session(d):
    """Compute the S4.1 single-session numbers.

    Assumes the log covers ONE chat session (it does: max_concurrency=1,
    one Open WebUI user). Returns None if there is nothing to aggregate.

    Key insight: in a `done` line, `prompt` is the FULL context re-sent to
    the API that turn, while `cache` is the part NInfer did NOT have to
    re-prefill (KV prefix reuse). Hence:

        actual work    = sum(prompt - cache)   tokens truly pre-filled
        effective rate = actual work / sum((prompt - cache) / prefill)
        busy time      = sum(wall)             GPU time spent serving
    which separates "how fast is the hardware" from "how much did the
    KV cache save us".
    """
    subs, dones = d["subs"], d["dones"]
    if not subs or not dones:
        return None
    t0 = min(s["ts"] for s in subs.values())    # first submitted (inner clock)
    t1 = max(x["ts"] for x in dones.values())   # last done
    span = (t1 - t0).total_seconds()            # active window of the session (s)
    sp = sum(x["prompt"] for x in dones.values())   # total prompt tok (with overlap)
    sg = sum(x["gen"]    for x in dones.values())   # total generated tok
    sc = sum(x["cache"]  for x in dones.values())   # total cached (skipped) tok
    sw = sum(x["wall"]   for x in dones.values())   # total serving time (s)
    actual = sp - sc                              # tokens actually re-prefilled
    # Sum of prefill time for the uncached part of each request:
    # (prompt - cache) tokens at that request's measured prefill tok/s.
    # Requests fully served from cache (prefill==0 or prompt<=cache) contribute 0.
    pt = sum((x["prompt"] - x["cache"]) / x["prefill"]
             for x in dones.values() if x["prefill"] > 0 and x["prompt"] > x["cache"])
    return dict(span=span, sp=sp, sg=sg, sc=sc, sw=sw, actual=actual,
                hit=100.0 * sc / sp if sp else 0.0,        # session cache-hit %
                busy=100.0 * sw / span if span else 0.0,   # GPU busy % of span
                gen_rate=sg / sw if sw else 0.0,           # tok/s while generating
                eff_prefill=actual / pt if pt else None,   # tok/s truly prefilling
                t0=t0, t1=t1)


# =====================================================================
# REPORT BUILDER
# =====================================================================

def build_report(d, src):
    """Assemble the final Markdown string from parse() output.

    Layout is fixed (sections S1-S6, see the module docstring). Every cell
    that could be missing renders an em-dash / "_none_" so the report never
    crashes on a log lacking a startup line or an errored-only request.
    """
    L = []                              # report lines; joined with \n at the end
    subs, dones = d["subs"], d["dones"]
    ts = lambda t: t.strftime("%H:%M:%S")   # table cells only need H:M:S

    # ---- header / summary line -------------------------------------------
    L.append(f"# NInfer Docker Log Report — `{src}`\n")
    L.append(f"- generated: {datetime.now():%Y-%m-%d %H:%M:%S}")
    L.append(f"- input lines: {d['total']} | log range: {d['first']} → {d['last']} (container clock)")
    L.append(f"- requests: {len(subs)} submitted / {len(dones)} completed / {len(d['errs'])} errored | throughput samples: {len(d['thrs'])}\n")

    # ---- S1 startup facts (all optional; skip the table if none found) ----
    L.append("## 1. Startup\n")
    rows = []
    if d["loaded"]:
        rows.append(f"| model loaded in | {d['loaded']} s |")
    if d["listen"]:
        rows.append(f"| endpoint | {d['listen']['url']} (model id: {d['listen']['model']}, auth: {d['listen']['auth']}) |")
    if d["kv"]:
        k = d["kv"]
        rows += [f"| KV capacity | {k['tokens']} tokens |",
                 f"| KV pages | {k['pages']}/{k['pages_max']} |",
                 f"| KV runtime reservation | {k['runtime']} GiB |",
                 f"| free-after-weights | {k['free_weights']} GiB |",
                 f"| free-after-startup | {k['free_startup']} GiB |",
                 f"| headroom (policy reserve) | {k['headroom']} GiB |",
                 f"| slack | {k['slack']} GiB |"]
    if rows:
        L += ["| field | value |", "|---|---|"] + rows + [""]
    else:
        L.append("_no startup lines found_\n")

    # ---- S2 one row per request -------------------------------------------
    # Iterate the UNION of submitted and done ids so a request that was
    # submitted but never completed (or only errored) still gets a row.
    L.append("## 2. Per-request table\n")
    L.append("| req | status | finish | tc | msgs | thist | prompt | gen | cache | reuse | ttft ms | prefill t/s | decode t/s | wall s | spec t/r | spec % |")
    L.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for req in sorted(set(subs) | set(dones)):
        s, x = subs.get(req), dones.get(req)
        if x is None:
            # No done line at all: mark incomplete, naming the error if any.
            e = next((e for e in d["errs"] if e["req"] == req), None)
            L.append(f"| {req} | **{e['what'] if e else 'incomplete'}** | {'—' * 14} |")
            continue
        spec = f"{x['spec_tr']:.2f} | {x['spec_pct']:.1f}" if x['spec_tr'] is not None else "— | —"
        # dagger: request completed AND also logged an error (e.g. client
        # disconnected mid-generation -> done finish=cancelled); S5 cross-refs it.
        e = next((e for e in d["errs"] if e["req"] == req), None)
        L.append("| " + " | ".join([str(req), "done†" if e else "done", x['finish'], x['tool_calls'] or '—',
                                    str(s['msgs']) if s else '—', s['tool_history'] if s else '—',
                                    str(x['prompt']), str(x['gen']), str(x['cache']), x['reuse'],
                                    str(x['ttft_ms']), f"{x['prefill']:.1f}", f"{x['decode']:.1f}",
                                    f"{x['wall']:.2f}", spec]) + " |")
    L.append("")
    L.append("_† request also recorded an error (see §5)_\n")

    # ---- S3 verbatim 5s samples, log order (deliberately NOT aggregated:
    #      the reader can spot prefill/decode interleaving and queue buildup)
    L.append("## 3. Throughput interval timeline\n")
    L.append("| time | prefill t/s | decode t/s | running | prefilling | decode_ready | waiting | avg batch |")
    L.append("|---|---|---|---|---|---|---|---|")
    for p in d["thrs"]:
        L.append(f"| {ts(p['ts'])} | {p['prefill']:.1f} | {p['decode']:.1f} | {p['running']} | {p['prefilling']} | {p['decode_ready']} | {p['waiting']} | {p['batch']} |")
    L.append("")

    # ---- S4 aggregates ------------------------------------------------------
    L.append("## 4. Aggregate statistics\n")
    L.append("### 4.1 Single-session performance\n")
    ss = single_session(d)
    if ss:
        # Math explained in single_session()'s docstring; "busy time" and
        # "effective prefill rate" are the two numbers that separate hardware
        # speed from KV-cache savings.
        L += ["| metric | value |", "|---|---|",
              f"| active span (first submitted → last done) | {ss['span']:.1f} s |",
              f"| total prompt tokens | {ss['sp']} |",
              f"| total generated tokens | {ss['sg']} |",
              f"| tokens actually re-prefilled (prompt − cache) | {ss['actual']} |",
              f"| session cache-hit rate | {ss['hit']:.1f}% |",
              f"| busy time (Σ wall) | {ss['sw']:.1f} s ({ss['busy']:.1f}% of span) |",
              f"| effective prefill rate | {ss['eff_prefill']:.1f} tok/s |",
              f"| busy-time generation rate (Σgen / Σwall) | {ss['gen_rate']:.1f} tok/s |",
              f"| wall-clock generation rate (Σgen / span) | {ss['sg']/ss['span']:.1f} tok/s |",
              ""]
    else:
        L.append("_not enough data_\n")

    # ---- S4.2 per-request distributions: one stat_row per metric ------------
    L.append("### 4.2 Per-request distributions\n")
    L.append("| metric | n | mean | median | min | max | p95 | unit |")
    L.append("|---|---|---|---|---|---|---|---|")
    L.append(stat_row("ttft", [x['ttft_ms'] for x in dones.values()], "ms", 0))
    L.append(stat_row("prefill", [x['prefill'] for x in dones.values()], "tok/s", 0))
    L.append(stat_row("decode", [x['decode'] for x in dones.values()], "tok/s", 1))
    L.append(stat_row("wall", [x['wall'] for x in dones.values()], "s", 2))
    L.append(stat_row("prompt size", [x['prompt'] for x in dones.values()], "tok", 0))
    L.append(stat_row("gen size", [x['gen'] for x in dones.values()], "tok", 0))
    L.append(stat_row("speculative acceptance", [x['spec_pct'] for x in dones.values() if x['spec_pct'] is not None], "%", 1))
    L.append("")

    # ---- S4.3 KV reuse mode breakdown: group done lines by reuse= mode and
    #      show what each mode actually saved (cached tok + mean ttft).
    #      Rows sorted by count, so the dominant mode comes first.
    L.append("### 4.3 KV reuse mode breakdown\n")
    L.append("| reuse mode | n | prompt tok | gen tok | cached tok | cache hit % | mean ttft ms |")
    L.append("|---|---|---|---|---|---|---|")
    modes = {}
    for x in dones.values():
        # per-mode accumulators: [n, Σprompt, Σgen, Σcache, Σttft_ms]
        m = modes.setdefault(x["reuse"], [0, 0, 0, 0, 0.0])
        m[0] += 1; m[1] += x['prompt']; m[2] += x['gen']; m[3] += x['cache']; m[4] += x['ttft_ms']
    for mode in sorted(modes, key=lambda k: -modes[k][0]):
        n, p, g, c, t = modes[mode]
        L.append(f"| {mode} | {n} | {p} | {g} | {c} | {100*c/p:.1f}% | {t/n:.0f} |")
    L.append("")

    # ---- S4.4 MTP speculative-decode acceptance vs prompt size --------------
    #      Acceptance dropping in big buckets would hint at KV pressure;
    #      a roughly flat table means MTP is unaffected by context length.
    L.append("### 4.4 Speculative acceptance vs prompt size\n")
    L.append("| prompt bucket | n | mean prompt | mean spec % | mean spec t/round | mean decode t/s |")
    L.append("|---|---|---|---|---|---|")
    for label, lo, hi in BUCKETS:
        sel = [x for x in dones.values() if lo <= x['prompt'] < hi and x['spec_pct'] is not None]
        if not sel:
            continue              # empty bucket -> no row (not a zero row)
        L.append(f"| {label} | {len(sel)} | {sum(x['prompt'] for x in sel)/len(sel):.0f} | "
                 f"{sum(x['spec_pct'] for x in sel)/len(sel):.1f} | {sum(x['spec_tr'] for x in sel)/len(sel):.2f} | "
                 f"{sum(x['decode'] for x in sel)/len(sel):.1f} |")
    L.append("")

    # ---- S5 errors: one bullet per failure; the request is cross-referenced
    #      via the dagger in S2. An errored request may or may not have a
    #      done line (cancelled ones do; hard failures may not).
    L.append("## 5. Errors\n")
    if d["errs"]:
        for e in d["errs"]:
            L.append(f"- req {e['req']}: {e['what']} at {e['ts']}")
    else:
        L.append("_none_")
    L.append("")

    # ---- S6 unrecognized lines (the canary). Truncated to 15 so a log full
    #      of banner/weight-load boilerplate can't drown the report; the
    #      count is always shown.
    L.append("## 6. Unrecognized lines\n")
    u = d["unrecognized"]
    if u:
        L.append(f"{len(u)} lines did not match any known pattern (typically container boilerplate/banner):\n")
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
    `grep -c "req ... done"` / `grep -c "throughput interval"` on the raw
    log to confirm nothing was misclassified.
    """
    ap = argparse.ArgumentParser(description="Parse an NInfer docker-log dump into a Markdown report.")
    ap.add_argument("log_file")
    ap.add_argument("-o", "--output", default=None, help="output markdown (default: <input>.report.md)")
    a = ap.parse_args()
    # Default output sits next to the input:
    #   01_docker_logs.txt -> 01_docker_logs.report.md
    out = a.output or (a.log_file[:-4] + ".report.md" if a.log_file.endswith(".txt") else a.log_file + ".report.md")
    d = parse(a.log_file)
    with open(out, "w") as f:
        f.write(build_report(d, a.log_file))
    print(f"wrote {out}  (lines={d['total']} done={len(d['dones'])} submitted={len(d['subs'])} "
          f"intervals={len(d['thrs'])} errors={len(d['errs'])} unrecognized={len(d['unrecognized'])})")


if __name__ == "__main__":
    main()