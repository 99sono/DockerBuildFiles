# Agent Memory: Max-Context 131072 VRAM Analysis (Single-Session Cline Preset)

> **Date:** 2026-08-25  
> **Agent:** Cline (context-stress investigation session)  
> **Environment:** RTX 5090 (32 GB GDDR7), WSL2 Ubuntu, Docker  
> **NInfer Commit:** `feaf4dd0983fdaeb2ba4c06eec6da350e644fb3a`  
> **Model:** Qwen 3.8-27B NVFP4 (`qwen3_8_27b_nvfp4.ninfer`, 20.02 GiB)  
> **Config:** `--max-context 131072 --max-concurrency 1 --kv-capacity auto --kv-dtype int8`

---

## 1. Verdict

`--max-context 131072` with `--max-concurrency 1` is **coherent and VRAM-safe**:
the KV pool auto-resolves to exactly 131072 tokens, the prompt admission check
allows exactly that, and ~5 GiB of VRAM remains free after startup. A mid-request
OOM is structurally impossible — the KV arena is pre-allocated at boot as a
static device buffer.

## 2. KV pool sizing formula (key discovery)

The auto-resolved pool ceiling is **not** a fixed model constant:

```
maximum_pages = max_concurrency × (max_context / 64)   # 64 tokens per KV page
```

Evidence — both observed boot logs match the formula exactly:

| Preset               | max_context   | concurrency | ceiling                              | log line        |
|----------------------|---------------|-------------|--------------------------------------|-----------------|
| Benchmark (old)      | 8192 (default)| 8           | 8 × 128 = 1024 pages = 65536 tokens   | `pages=1024/1024` |
| Cline single-session | 131072        | 1           | 1 × 2048 = 2048 pages = 131072 tokens | `pages=2048/2048` |

So the pool is deliberately sized so **every** concurrent session can hold a full
`max_context`. With concurrency 1, a single session can genuinely use all 131k tokens.

## 3. Admission check vs pool — coherent, no trap zone

- Admission (`Engine::prepare` / `Engine::submit`) rejects prompts with
  `prompt_tokens > max_context`; `target->capacity` **is** `max_context`
  (`layouts_impl.h`: `impl->capacity = inputs.capacity = options.max_context`).
- Pool ceiling = `max_concurrency × max_context` (section 2).
- With `max_concurrency 1`: admission limit == pool size == 131072. Consistent.
  (An earlier working hypothesis of a 65k "trap zone" was **wrong** — 65536 only
  applied to the old concurrency-8 / max-context-8192 preset.)

## 4. VRAM budget (from the 2026-08-25 20:04 boot log)

```
KV capacity auto resolved=131072 tokens pages=2048/2048 runtime=4.94 GiB
free-after-weights=10.81 GiB free-after-startup=5.05 GiB
headroom=1.00 GiB slack=5.87 GiB graphs=2.00 MiB/82.00 MiB
```

- `headroom=1.00 GiB` is the auto policy's **mandatory reserve margin** (subtracted
  before the pool is sized) — it is **not** the actual slack.
- `free-after-startup=5.05 GiB` is the real headroom left after the 4.94 GiB
  runtime reservation. Comfortable.
- If a config ever didn't fit, the engine fails hard **at startup** (visible
  immediately) — never as a mid-request OOM.

## 5. Practical caveats at the top of the window

1. Prompt + generation **share** the 131072-token pool: a 130k prompt leaves only
   ~1k tokens for output.
2. The main KV cache is **cyclic**: right at the edge, oldest context may be
   silently evicted (quality degradation, not a hard error).
3. TTFT at 131k: 131072 / 1024 (`--prefill-chunk 1024`) = 128 chunks ≈ 1.5–3 min
   at the 400–1400 tok/s prefill rates seen in the benchmark logs.
4. Watch `cache=` / `reuse=` in the request log lines: if consecutive Cline turns
   re-prefill the whole conversation (`reuse=full_reset`), per-turn cost grows
   linearly with conversation length.

## 6. Source map (for future digs)

- `src/serve/serve_options.h:29` — `max_context = 8192` hard default (see sibling memory)
- `src/serve/serve_options.cpp:55` — `--kv-capacity auto|N` parsing
- `src/targets/qwen3_6/impl/runtime/layouts_impl.h`
  - `:549-552` / `:704-712` — page curve: `minimum_pages = max(logical_pages, max_concurrency)`, `maximum_pages = max_concurrency × logical_pages`
  - `:611` — `impl->capacity = inputs.capacity` (admission capacity = max_context)
  - `:688-700` — `make_sequence_planner_impl` wires `options.max_context` into the plan
  - `:736-753` — `finalize_sequence_plan_impl`
- `src/runtime/engine/kv_capacity.cpp:77` — `resolve_kv_capacity` (auto sizing, headroom deduction, ceiling clamp)
- `src/runtime/engine/engine.cpp:187,208,255` — `prompt_tokens > capacity` admission throw
- `src/core/cyclic_kv_cache.cpp` — static per-lane KV arena (fixed size, pre-allocated)