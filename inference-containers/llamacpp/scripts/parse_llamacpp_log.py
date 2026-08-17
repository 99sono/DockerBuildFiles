#!/usr/bin/env python3
"""parse_llamacpp_log.py — llama.cpp server log dump -> markdown performance report.

Usage:
    parse_llamacpp_log.py [--json] LOG_FILE

Reads a `docker logs` style dump of a llama.cpp server, extracts:
  * server/model info (model path, n_slots, n_ctx_slot, kv_unified, host/port,
    MTP/speculative context lines),
  * per-request final timing blocks (prompt eval, eval, total, graphs reused,
    MTP draft acceptance),
  * mid-generation throughput snapshots (`n_gen`/`tg`/`tg_3s`, older
    `n_decoded`/`tg` lines),
  * deduplicated warnings,
and prints a deterministic markdown report to stdout.
With `--json`, prints the raw parsed stats as JSON instead.

Python 3 standard library only. Malformed lines are skipped, never fatal.
"""

import argparse
import json
import re
import sys

VERSION = "1.0"

# ---------------------------------------------------------------------------
# line patterns
# ---------------------------------------------------------------------------

# timestamped line: "<ss.SS.mmm.ddd> <LEVEL> <message>"
RE_TIMED = re.compile(r"^(\d+\.\d+\.\d+\.\d+)\s+([A-Z])\s?(.*)$")
RE_WARN_BARE = re.compile(r"^warn(?:ing)?:\s*(.+)$")
RE_ERR_BARE = re.compile(r"^err(?:or)?:\s*(.+)$")

# slot/task line, e.g. "slot print_timing: id  0 | task 0 | <payload>"
RE_RELEASE = re.compile(
    r"release:\s*id\s+(\d+)\s*\|\s*task\s+(-?\d+)\s*\|\s*stop processing:\s*"
    r"n_tokens\s*=\s*(\d+)\s*,\s*truncated\s*=\s*(\d+)"
)
RE_SLOT_TASK = re.compile(r"id\s+(\d+)\s*\|\s*task\s+(-?\d+)\s*\|\s*(.*?)\s*$")

# print_timing payload kinds
RE_SNAP = re.compile(
    r"^n_(?:gen|decoded)\s*=\s*(\d+)\s*,\s*tg\s*=\s*([\d.]+)\s*t/s"
    r"(?:\s*,\s*tg_3s\s*=\s*([\d.]+)\s*t/s)?\s*$"
)
RE_PROMPT = re.compile(
    r"^prompt eval time =\s*([\d.]+)\s*ms\s*/\s*(\d+)\s*tokens"
    r"\s*\(\s*([\d.]+)\s*ms per token,\s*([\d.]+)\s*tokens per second\)\s*$"
)
RE_EVAL = re.compile(
    r"^\s*eval time =\s*([\d.]+)\s*ms\s*/\s*(\d+)\s*tokens"
    r"\s*\(\s*([\d.]+)\s*ms per token,\s*([\d.]+)\s*tokens per second\)\s*$"
)
RE_TOTAL = re.compile(r"^\s*total time =\s*([\d.]+)\s*ms\s*/\s*(\d+)\s*tokens\s*$")
RE_GRAPHS = re.compile(r"^\s*graphs reused =\s*(\d+)\s*$")
RE_DRAFT = re.compile(
    r"^\s*draft acceptance =\s*([\d.]+)\s*\(\s*(\d+)\s*accepted\s*/\s*(\d+)\s*"
    r"generated\)(?:\s*,\s*mean len =\s*([\d.]+))?\s*$"
)

# server / model info
RE_MODEL = re.compile(r"load_model:\s*loading model '(.+?)'")
RE_N_SLOTS = re.compile(r"n_slots = (\d+)")
RE_N_CTX_SLOT = re.compile(r"n_ctx_slot = (\d+)")
RE_KV_UNIFIED = re.compile(r"kv_unified = '(\w+)'")
RE_N_CTX = re.compile(r"new slot, n_ctx = (\d+)")
RE_LISTEN = re.compile(r"listening on\s+(\S+)")
RE_URL = re.compile(r"//([^:/]+):(\d+)")
RE_THREADS = re.compile(r"llama threadpool init, n_threads = (\d+)")
RE_MTP = re.compile(r"MTP|speculative")
RE_NUM = re.compile(r"\d+")


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _f(x, nd=2):
    return "—" if x is None else f"{x:,.{nd}f}"


def _i(x):
    return "—" if x is None else f"{x:,}"


def _mmx(vals):
    if not vals:
        return None
    return {"mean": sum(vals) / len(vals), "min": min(vals), "max": max(vals), "n": len(vals)}


def _mmx_str(m):
    if not m:
        return "—"
    return f"{m['mean']:.2f} / {m['min']:.2f} / {m['max']:.2f}"


def _count(store, msg):
    """Deduplicate by digit-normalized key so e.g. prompt_save lines with
    different sizes count as the same warning."""
    key = RE_NUM.sub("#", msg)
    e = store.get(key)
    if e is None:
        store[key] = {"count": 1, "message": msg, "key": key}
    else:
        e["count"] += 1


def _get_task(tasks, key):
    t = tasks.get(key)
    if t is None:
        t = {
            "slot": key[0],
            "task": key[1],
            "prompt": None,
            "eval": None,
            "total": None,
            "graphs_reused": None,
            "draft": None,
            "release": None,
            "snapshots": [],
            "snapshots_tg3s": [],
        }
        tasks[key] = t
    return t


def _classify(payload):
    """Return (kind, regex-groups) for a print_timing payload, else None."""
    for kind, rx in (
        ("snap", RE_SNAP),
        ("prompt", RE_PROMPT),
        ("eval", RE_EVAL),
        ("total", RE_TOTAL),
        ("graphs", RE_GRAPHS),
        ("draft", RE_DRAFT),
    ):
        m = rx.match(payload)
        if m:
            return kind, m.groups()
    return None


def _apply(task, kind, g):
    if kind == "snap":
        task["snapshots"].append(float(g[1]))
        if g[2] is not None:
            task["snapshots_tg3s"].append(float(g[2]))
    elif kind == "prompt":
        task["prompt"] = {"ms": float(g[0]), "tokens": int(g[1]), "tps": float(g[3])}
    elif kind == "eval":
        task["eval"] = {"ms": float(g[0]), "tokens": int(g[1]), "tps": float(g[3])}
    elif kind == "total":
        task["total"] = {"ms": float(g[0]), "tokens": int(g[1])}
    elif kind == "graphs":
        task["graphs_reused"] = int(g[0])
    elif kind == "draft":
        task["draft"] = {
            "acceptance": float(g[0]),
            "accepted": int(g[1]),
            "generated": int(g[2]),
            "mean_len": float(g[3]) if g[3] is not None else None,
        }


def _info(msg, server, mtp_lines, tasks):
    m = RE_MODEL.search(msg)
    if m:
        server["model"] = m.group(1)
    m = RE_N_SLOTS.search(msg)
    if m:
        server["n_slots"] = int(m.group(1))
    m = RE_N_CTX_SLOT.search(msg)
    if m:
        server["n_ctx_slot"] = int(m.group(1))
    m = RE_KV_UNIFIED.search(msg)
    if m:
        server["kv_unified"] = m.group(1)
    m = RE_N_CTX.search(msg)
    if m:
        server["n_ctx"] = int(m.group(1))
    m = RE_LISTEN.search(msg)
    if m:
        server["listen"] = m.group(1)
        u = RE_URL.search(m.group(1))
        if u:
            server["listen_host"] = u.group(1)
            server["listen_port"] = int(u.group(2))
    m = RE_THREADS.search(msg)
    if m:
        server["n_threads"] = int(m.group(1))
    if RE_MTP.search(msg):
        mtp_lines.append(msg)

    m = RE_RELEASE.search(msg)
    if m:
        t = _get_task(tasks, (int(m.group(1)), int(m.group(2))))
        t["release"] = {"n_tokens": int(m.group(3)), "truncated": int(m.group(4))}
        return

    m = RE_SLOT_TASK.search(msg)
    if m:
        payload = m.group(3).strip()
        cls = _classify(payload)
        if cls is None:
            return  # e.g. "selected slot by LRU" — not timing info
        kind, groups = cls
        _apply(_get_task(tasks, (int(m.group(1)), int(m.group(2)))), kind, groups)


def _process_line(line, server, mtp_lines, tasks, warnings, errors):
    m = RE_TIMED.match(line)
    if m:
        level, msg = m.group(2), m.group(3).strip()
        if level == "W":
            _count(warnings, msg)
        elif level == "E":
            _count(errors, msg)
        elif level == "I":
            _info(msg, server, mtp_lines, tasks)
        return
    m = RE_WARN_BARE.match(line)
    if m:
        _count(warnings, m.group(1).strip())
        return
    m = RE_ERR_BARE.match(line)
    if m:
        _count(errors, m.group(1).strip())
        return
    # anything else (chat echoes, compose config, ...) is ignored


# ---------------------------------------------------------------------------
# parsing
# ---------------------------------------------------------------------------

def parse_file(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()

    server = {
        "model": None,
        "n_slots": None,
        "n_ctx_slot": None,
        "n_ctx": None,
        "kv_unified": None,
        "listen": None,
        "listen_host": None,
        "listen_port": None,
        "n_threads": None,
    }
    mtp_lines = []
    tasks = {}
    warnings = {}
    errors = {}

    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        try:
            _process_line(line, server, mtp_lines, tasks, warnings, errors)
        except Exception:
            continue  # never crash on malformed input

    task_list = sorted(tasks.values(), key=lambda t: (t["task"], t["slot"]))
    stats = {
        "parser": f"parse_llamacpp_log.py v{VERSION}",
        "source": path,
        "line_count": len(lines),
        "server": server,
        "mtp_lines": mtp_lines,
        "tasks": task_list,
        "snapshots": {
            "tg": [v for t in task_list for v in t["snapshots"]],
            "tg_3s": [v for t in task_list for v in t["snapshots_tg3s"]],
        },
        "aggregates": _build_aggregates(task_list),
        "warnings": sorted(warnings.values(), key=lambda w: (-w["count"], w["key"])),
        "errors": sorted(errors.values(), key=lambda w: (-w["count"], w["key"])),
    }
    return stats


def _build_aggregates(task_list):
    completed = [t for t in task_list if t["prompt"] or t["eval"]]
    prompt_tps = [t["prompt"]["tps"] for t in completed if t["prompt"]]
    gen_tps = [t["eval"]["tps"] for t in completed if t["eval"]]
    sum_prompt_tok = sum(t["prompt"]["tokens"] for t in completed if t["prompt"])
    sum_prompt_ms = sum(t["prompt"]["ms"] for t in completed if t["prompt"])
    sum_gen_tok = sum(t["eval"]["tokens"] for t in completed if t["eval"])
    sum_gen_ms = sum(t["eval"]["ms"] for t in completed if t["eval"])

    agg = {
        "tasks_seen": len(task_list),
        "tasks_completed": len(completed),
        "tasks_snapshot_only": sum(
            1 for t in task_list
            if not (t["prompt"] or t["eval"]) and t["snapshots"]
        ),
        "total_prompt_tokens": sum_prompt_tok,
        "total_gen_tokens": sum_gen_tok,
        "total_prompt_ms": sum_prompt_ms if sum_prompt_ms else None,
        "total_gen_ms": sum_gen_ms if sum_gen_ms else None,
        "prompt_tps": _mmx(prompt_tps),
        "gen_tps_simple": _mmx(gen_tps),
        "overall_gen_tps": (sum_gen_tok / (sum_gen_ms / 1000.0)) if sum_gen_ms > 0 else None,
        "graphs_reused_total": sum(
            t["graphs_reused"] for t in completed if t["graphs_reused"] is not None
        ),
    }

    drafts = [t["draft"] for t in completed if t["draft"]]
    if drafts:
        acc = [d["acceptance"] for d in drafts]
        acc_sum = sum(d["accepted"] for d in drafts)
        gen_sum = sum(d["generated"] for d in drafts)
        lens = [d["mean_len"] for d in drafts if d["mean_len"] is not None]
        agg["mtp"] = {
            "tasks": len(drafts),
            "acceptance": _mmx(acc),
            "weighted_acceptance": (acc_sum / gen_sum) if gen_sum else None,
            "total_accepted": acc_sum,
            "total_generated": gen_sum,
            "mean_len": (sum(lens) / len(lens)) if lens else None,
        }
    else:
        agg["mtp"] = None
    return agg


# ---------------------------------------------------------------------------
# markdown rendering
# ---------------------------------------------------------------------------

def _md_escape(s):
    return s.replace("`", "'")


def render_markdown(stats):
    out = []
    srv = stats["server"]
    agg = stats["aggregates"]
    tasks = stats["tasks"]

    out.append("# llama.cpp Log Performance Report")
    out.append("")
    out.append(f"- **Source:** `{stats['source']}`")
    out.append(f"- **Lines read:** {stats['line_count']:,}")
    out.append(f"- **Generated by:** {stats['parser']}")
    out.append("")

    # -- 1. server & model ---------------------------------------------------
    out.append("## 1. Server & model")
    out.append("")
    rows = []
    if srv.get("model"):
        rows.append(("Model file", f"`{srv['model']}`"))
    if srv.get("n_slots") is not None:
        rows.append(("n_slots", _i(srv["n_slots"])))
    ctx = srv["n_ctx_slot"] if srv["n_ctx_slot"] is not None else srv.get("n_ctx")
    if ctx is not None:
        rows.append(("n_ctx_slot", _i(ctx)))
    if srv.get("kv_unified") is not None:
        rows.append(("kv_unified", srv["kv_unified"]))
    if srv.get("listen"):
        rows.append(("Listening", srv["listen"]))
    if srv.get("n_threads") is not None:
        rows.append(("CPU threads", _i(srv["n_threads"])))
    if rows:
        out.append("| Item | Value |")
        out.append("|---|---|")
        for label, val in rows:
            out.append(f"| {label} | {val} |")
    else:
        out.append("_No server/model info found in this log._")
    if stats["mtp_lines"]:
        out.append("")
        out.append("<details><summary>Speculative / MTP context lines</summary>")
        out.append("")
        out.append("```text")
        out.extend(stats["mtp_lines"])
        out.append("```")
        out.append("")
        out.append("</details>")
    out.append("")

    # -- 2. requests & per-task throughput -----------------------------------
    out.append("## 2. Requests & per-task throughput")
    out.append("")
    if not tasks:
        out.append("_No requests found — the log contains no `print_timing` or `release` lines._")
    else:
        n_completed = agg["tasks_completed"]
        n_snap = agg["tasks_snapshot_only"]
        extra = len(tasks) - n_completed - n_snap
        extra_str = f", {extra} other" if extra > 0 else ""
        out.append(
            f"- Tasks seen: **{len(tasks)}** "
            f"({n_completed} completed{extra_str}, {n_snap} snapshot-only)"
        )
        shown = tasks[-10:]
        if len(tasks) > 10:
            out.append(f"- Table shows the last {len(shown)} of {len(tasks)} tasks.")
        out.append("")
        out.append(
            "| Slot | Task | Prompt ms | Prompt tok | Prompt t/s "
            "| Eval ms | Gen tok | Eval t/s | Total ms | Draft acceptance |"
        )
        out.append("|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|")
        for t in shown:
            p, e, tot, d = t["prompt"], t["eval"], t["total"], t["draft"]
            acc = "—"
            if d:
                acc = f"{d['acceptance']:.3f} ({d['accepted']}/{d['generated']}"
                if d["mean_len"] is not None:
                    acc += f", len {d['mean_len']:.2f}"
                acc += ")"
            out.append(
                f"| {t['slot']} | {t['task']} "
                f"| {_f(p['ms']) if p else '—'} | {_i(p['tokens']) if p else '—'} "
                f"| {_f(p['tps']) if p else '—'} "
                f"| {_f(e['ms']) if e else '—'} | {_i(e['tokens']) if e else '—'} "
                f"| {_f(e['tps']) if e else '—'} "
                f"| {_f(tot['ms']) if tot else '—'} | {acc} |"
            )
    out.append("")

    # -- 3. aggregates --------------------------------------------------------
    out.append("## 3. Aggregates")
    out.append("")
    if not agg["tasks_completed"]:
        out.append("_No completed tasks to aggregate._")
    else:
        out.append(f"Across **{agg['tasks_completed']}** completed tasks:")
        out.append("")
        out.append("| Metric | Value |")
        out.append("|---|---|")
        out.append(f"| Total prompt tokens | {_i(agg['total_prompt_tokens'])} |")
        out.append(f"| Total generation tokens | {_i(agg['total_gen_tokens'])} |")
        out.append(f"| Total prompt eval time | {_f(agg['total_prompt_ms'])} ms |")
        out.append(f"| Total generation (eval) time | {_f(agg['total_gen_ms'])} ms |")
        out.append(f"| Prompt eval t/s — mean / min / max | {_mmx_str(agg['prompt_tps'])} |")
        out.append(f"| Generation t/s — simple mean / min / max | {_mmx_str(agg['gen_tps_simple'])} |")
        out.append(
            f"| **Overall generation t/s** (Σ gen tokens / Σ eval time) "
            f"| **{_f(agg['overall_gen_tps'])}** |"
        )
        out.append(f"| Graphs reused (total) | {_i(agg['graphs_reused_total'])} |")
        mtp = agg.get("mtp")
        if mtp:
            out.append("")
            out.append("### MTP draft acceptance")
            out.append("")
            out.append("| Metric | Value |")
            out.append("|---|---|")
            out.append(f"| Tasks with draft stats | {mtp['tasks']} |")
            out.append(f"| Acceptance — mean / min / max | {_mmx_str(mtp['acceptance'])} |")
            w = mtp["weighted_acceptance"]
            w_str = (
                f"{w:.4f} ({mtp['total_accepted']:,}/{mtp['total_generated']:,})"
                if w is not None
                else "—"
            )
            out.append(f"| Weighted acceptance (Σ acc / Σ gen) | {w_str} |")
            out.append(f"| Mean draft length | {_f(mtp['mean_len'])} |")
    out.append("")

    # -- 4. mid-generation snapshots ------------------------------------------
    out.append("## 4. Mid-generation snapshots")
    out.append("")
    sn = stats["snapshots"]
    tg, tg3 = sn.get("tg") or [], sn.get("tg_3s") or []
    if not tg and not tg3:
        out.append("_No mid-generation snapshot lines found._")
    else:
        out.append("| Sample | Min | Mean | Max | n |")
        out.append("|---|---:|---:|---:|---:|")
        for label, vals in (("tg (t/s)", tg), ("tg_3s (3s rolling, t/s)", tg3)):
            if vals:
                out.append(f"| {label} | {min(vals):.2f} | {sum(vals)/len(vals):.2f} | {max(vals):.2f} | {len(vals)} |")
    out.append("")

    # -- 5. warnings -----------------------------------------------------------
    out.append("## 5. Warnings")
    out.append("")
    if not stats["warnings"]:
        out.append("_No warnings found._")
    else:
        out.append("| Count | Warning |")
        out.append("|---:|---|")
        for w in stats["warnings"]:
            out.append(f"| {w['count']} | `{_md_escape(w['message'])}` |")
    if stats["errors"]:
        out.append("")
        out.append("### Errors")
        out.append("")
        out.append("| Count | Error |")
        out.append("|---:|---|")
        for e in stats["errors"]:
            out.append(f"| {e['count']} | `{_md_escape(e['message'])}` |")
    out.append("")

    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="parse_llamacpp_log.py",
        description="Parse a llama.cpp server log dump into a markdown performance report.",
    )
    ap.add_argument("log_file", nargs="?", help="path to the llama.cpp log dump")
    ap.add_argument(
        "--json", action="store_true",
        help="dump raw parsed stats as JSON instead of markdown",
    )
    args = ap.parse_args(argv)

    if not args.log_file:
        ap.print_usage(sys.stderr)
        print("error: LOG_FILE is required", file=sys.stderr)
        return 2
    try:
        stats = parse_file(args.log_file)
    except OSError as e:
        print(f"error: cannot read {args.log_file}: {e}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(stats, indent=2))
    else:
        print(render_markdown(stats))
    return 0


if __name__ == "__main__":
    sys.exit(main())
