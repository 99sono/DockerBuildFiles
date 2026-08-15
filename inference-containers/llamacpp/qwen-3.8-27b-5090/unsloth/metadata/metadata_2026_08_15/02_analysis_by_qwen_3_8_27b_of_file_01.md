# Analysis of `01_docker_logs.txt` — qwen-3.8-27b-5090 llama.cpp server

## 1. Header

| Item | Value |
|---|---|
| File analyzed | `inference-containers/llamacpp/qwen-3.8-27b-5090/unsloth/metadata/metadata_2026_08_15/01_docker_logs.txt` (212 lines, 25,526 bytes) |
| Source | `docker logs qwen-3.8-27b-5090` dump produced by `05_b_dump_logs.sh` (sensitive values masked), moved here from `2026-08-15_08-44-39_qwen-3.8-27b-5090_log_dump.txt` |
| Container / image | `qwen-3.8-27b-5090` — `ghcr.io/ggml-org/llama.cpp:server-cuda13` |
| Dump date | 2026-08-15 08:44:39 (supersedes the earlier `2026-08-15_07-53-26` dump; this dump contains the latest benchmark timings, tasks 0 → 3609) |
| Process uptime covered | t=0.00.2 s (startup) to t=49.57.0 s (last release), single continuous process — no restarts |

**One-line summary:** Healthy single-process llama.cpp MTP serving session: 18 request tasks over ~50 min, generation 57–132 t/s (median 95.9), draft acceptance 91.1–100% (aggregate 95.6%), no errors, two config warnings (`--mlock` deprecated, `LLAMA_ARG_HOST` env overwrite); short-context throughput matches/exceeds the README's expected table, but deep-context (>47K tokens) generation drops below the README's 85–90 t/s band.

---

## 2. Startup / configuration

Quoted from the log (lines 1–10):

```
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.00.230.659 W DEPRECATED: --mlock is deprecated. use --load-mode mlock instead
0.00.230.904 I cmn  common_param: common_params_print_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.00.436.253 I srv    load_model: loading model '/models/Qwen3.8-27B-UD-Q4_K_XL.gguf'
0.04.649.097 I cmn          init: llama threadpool init, n_threads = 12
0.04.755.304 I common_speculative_init_result: creating MTP draft context against the target model '/models/Qwen3.8-27B-UD-Q4_K_XL.gguf'
0.05.141.440 I srv    load_model: initializing, n_slots = 1, n_ctx_slot = 262144, kv_unified = 'false'
0.05.411.120 I srv          init: chat template supports preserving reasoning, consider enabling it via --reasoning-preserve
0.05.411.178 I srv  llama_server: model loaded
0.05.411.182 I srv  llama_server: listening on http://0.0.0.0:8000
```

Confirmed by the log:

| Setting | Value | Log line |
|---|---|---|
| Model path | `/models/Qwen3.8-27B-UD-Q4_K_XL.gguf` | line 4 |
| `n_ctx_slot` | `262144` (full native 256K) | line 7 |
| `n_slots` | `1` (single slot) | line 7 |
| `kv_unified` | `false` | line 7 |
| `n_threads` | `12` | line 5 |
| MTP / speculative decoding | active — "creating MTP draft context against the target model" (draft model = target model, i.e. baked-in MTP head) | line 6 |
| Endpoint | `http://0.0.0.0:8000` | line 10 |

Warnings at startup:

1. `DEPRECATED: --mlock is deprecated. use --load-mode mlock instead` — the compose file still passes `--mlock`.
2. `LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host` — an env var (likely from `.env`) conflicts with the explicit `--host 0.0.0.0`; cosmetic only.
3. Info: `chat template supports preserving reasoning, consider enabling it via --reasoning-preserve` — suggestion, not a fault.

**Not present in log** (the dump starts at the point of model loading; the initial banner with system info, build flags, backend/KV allocation was not captured in this container log snapshot):
KV cache types (`--cache-type-k/q8_0`, `--cache-type-v/q8_0`), FlashAttention flag, `n_gpu_layers`, `threads_batch`, the spec flags themselves (`--spec-type draft-mtp`, `--spec-draft-n-max 2`, `--spec-draft-p-min 0.8`), and the README's expected Blackwell verification lines `BLACKWELL_NATIVE_FP4 = 1` / `USE_GRAPHS = 1`. MTP is *operationally* confirmed active by the per-task `draft acceptance =` lines, and CUDA graph usage is *operationally* confirmed by the monotonic `graphs reused` counter (12 → 2249 across the session). The intended values of the absent flags are known from `docker-compose.yml`.

---

## 3. Performance metrics (per task)

18 completed task cycles (`print_timing` + `release`), all `truncated = 0`. "Rel. n_tokens" = slot context size at release time (proxy for conversation depth during the request); prompt-eval figures cover only tokens **newly** evaluated (KV prefix reused via LCP, see `f_keep` lines).

| Task | Prompt tok | Prompt time (ms) | Prompt t/s | Gen tok | Eval time (ms) | Gen t/s | Total time (ms) | Graphs reused | Draft accept (acc/gen) | Mean len | Rel. n_tokens |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| 0 | 6111 | 2713.77 | 2251.85 | 46 | 639.03 | 70.42 | 3352.81 | 12 | 29/29 (1.00000) | 2.81 | 6158 |
| 25 | 35 | 322.06 | 108.68 | 31 | 227.93 | 131.62 | 549.99 | 21 | 20/20 (1.00000) | 3.00 | 6223 |
| 38 | 1334 | 1229.15 | 1085.30 | 184 | 1691.41 | 108.19 | 2920.56 | 76 | 114/117 (0.97436) | 2.87 | 7112 |
| 112 | 6634 | 2617.81 | 2534.18 | 268 | 2223.28 | 120.09 | 4841.08 | 158 | 173/175 (0.98857) | 2.97 | 13826 |
| 212 | 14894 | 5595.67 | 2661.70 | 479 | 3960.55 | 120.69 | 9556.22 | 305 | 316/317 (0.99685) | 2.96 | 20969 |
| 387 | 12630 | 5277.22 | 2393.31 | 458 | 3837.29 | 119.09 | 9114.51 | 447 | 300/303 (0.99010) | 2.96 | 26068 |
| 554 | 10881 | 4836.25 | 2249.88 | 207 | 2123.22 | 97.02 | 6959.47 | 497 | 131/132 (0.99242) | 2.87 | 29191 |
| 639 | 15114 | 6894.15 | 2192.29 | 164 | 1648.44 | 98.88 | 8542.59 | 545 | 106/107 (0.99065) | 2.96 | 36753 |
| 707 | 10449 | 5858.80 | 1783.47 | 226 | 2199.53 | 102.29 | 8058.33 | 616 | 148/151 (0.98013) | 2.95 | 39756 |
| 793 | 15069 | 8473.97 | 1778.27 | 222 | 2227.58 | 99.21 | 10701.56 | 683 | 146/146 (1.00000) | 2.97 | 47313 |
| 879 | 7621 | 5100.74 | 1494.10 | 333 | 3732.92 | 88.94 | 8833.65 | 779 | 209/214 (0.97664) | 2.88 | 55041 |
| 1009 | 2169 | 2005.81 | 1081.36 | 329 | 4305.41 | 76.18 | 6311.23 | 862 | 191/201 (0.95025) | 2.79 | 57538 |
| 1150 | 1825 | 1702.19 | 1072.15 | 381 | 5631.13 | 67.48 | 7333.32 | 971 | 200/209 (0.95694) | 2.65 | 59743 |
| 1334 | 544 | 984.45 | 552.59 | 3829 | 57377.92 | 66.72 | 58362.37 | 1888 | 2171/2318 (0.93658) | 2.71 | 64115 |
| 2995 | 21 | 791.87 | 26.52 | 246 | 3979.02 | 61.57 | 4770.89 | 1952 | 135/138 (0.97826) | 2.80 | 64383 |
| 3110 | 17 | 974.46 | 17.45 | 858 | 14894.34 | 57.54 | 15868.79 | 2150 | 453/497 (0.91147) | 2.57 | 65257 |
| 3517 | 1532 | 1005.05 | 1524.30 | 214 | 2247.21 | 94.78 | 3252.26 | 2208 | 126/127 (0.99213) | 2.85 | 7340 |
| 3609 | 510 | 469.72 | 1085.75 | 162 | 1735.53 | 92.77 | 2205.25 | 2249 | 95/95 (1.00000) | 2.86 | 8011 |

### Min / max / median (18 tasks)

| Metric | Min | Max | Median |
|---|---:|---:|---:|
| Generation t/s | 57.54 (task 3110) | 131.62 (task 25) | 95.90 |
| Prompt t/s | 17.45 (task 3110, 17 tok) | 2661.70 (task 212) | 1509.20 |
| Gen tokens / task | 31 (task 25) | 3829 (task 1334) | — |
| Total time (ms) / task | 549.99 (task 25) | 58362.37 (task 1334) | 7146.40 |
| Draft acceptance | 0.91147 (task 3110) | 1.00000 (tasks 0, 25, 793, 3609) | 0.9893 |
| Acceptance mean len | 2.57 (task 3110) | 3.00 (task 25) | — |

### Aggregates

- Generation: **8637 tokens in 114,681.74 ms → 75.32 t/s weighted average**.
- Prompt eval: **107,390 tokens in 56,853.14 ms → 1888.9 t/s weighted average**.
- Drafts: **5063 accepted / 5296 generated → 95.60% aggregate acceptance**; mean len 2.57–3.00, i.e. speculative chains of up to 3 tokens (2 MTP drafts + 1 bonus) complete almost fully.

### Depth-bucket summary (bucketed by slot context at release)

| Bucket (rel. n_tokens) | Tasks | Gen t/s range | Mean gen t/s | Acceptance range |
|---|---|---|---:|---|
| ≤14K ("short") | 0, 25, 38, 112, 3517, 3609 | 70.42–131.62 | 102.98 (111.84 excl. task 0) | 0.97436–1.00000 |
| 15K–47K | 212, 387, 554, 639, 707, 793 | 97.02–120.69 | 106.20 | 0.98013–0.99685 |
| ≥47K ("deep") | 793, 879, 1009, 1150, 1334, 2995, 3110 | 57.54–99.21 | 73.95 | 0.91147–1.00000 |

Intra-task generation traces (progress `tg` lines) confirm the trend: task 1334 (64K context, 3829 gen tokens) runs `tg = 90.31 → 59.64 → 65.71 → 56.69 → …` t/s over its life; tasks 2995/3110 sustain 60.18 / 55–59 t/s at 64–65K.

---

## 4. Comparison with the README "Expected performance"

README (`README.md:120–125`, projected from Qwen3.6-27B MTP benchmarks):

| Context Depth | README expected gen | Observed gen | README expected acceptance | Observed acceptance |
|---|---|---|---|---|
| Short (<8K tokens) | ~90–95 t/s | 92.77–131.62 typical (task 0: 70.42, first request) | ~79% | 97.4–100% |
| Deep (>15K tokens) | ~85–90 t/s | 97–121 t/s at 15–47K; **57.5–88.9 t/s at ≥55K** | 60–80% | 91.1–100% |

**Generation.** Short context **meets or exceeds** the 90–95 t/s band (five of six ≤14K tasks are 92.8–131.6 t/s). Task 0 (70.42 t/s, 46 gen tokens) is the session's first request after model load — a cold-start artifact. At 15–47K the server is *above* the expected deep band (97–121 t/s). The deviation appears only at ≥47K live context, where throughput falls to 57.5–88.9 t/s (tasks 879→3110, context 55K→65K), i.e. **15–32% below the README's 85–90 t/s floor**. The README's "deep" bucket (">15K") under-specified the regime where degradation sets in (~55K+); the table should be revisited (suggested values: ~90–130 t/s ≤15K, ~95–120 t/s 15–47K, ~57–90 t/s ≥47K).

**Acceptance.** Far better than expected everywhere: README predicted ~79% short and 60–80% deep; observed is 91.1–100% on every one of the 18 tasks (median 0.989, aggregate 95.6%). The README's "~52% per-token acceptance at deep context" assumption is pessimistic for this model/quant — with `--spec-draft-n-max 2` and `--spec-draft-p-min 0.8`, chains are near-fully accepted (mean len 2.57–3.00 vs max 3) even at 65K context, where acceptance only dips to 0.91147 (task 3110). The conservative spec settings are not costing throughput.

**Notable observations.**

- **Prompt-heavy tasks:** large-batch prompt eval is the standout number — 15,114 tokens in 6894.15 ms (2192.29 t/s, task 639); up to 2661.70 t/s (task 212). This is consistent with MMQ-optimized batch processing on Blackwell (the README's 5.7× claim). Tiny-prompt follow-ups (17–35 tokens, tasks 25/2995/3110) show low *absolute* prompt t/s (17–108 t/s) only because the batch doesn't amortize overhead; the 17-token prompt of task 3110 alone took 974.46 ms.
- **KV cache / 262144 context implications:** `n_ctx_slot = 262144` means the slot reserves 256K of headroom at all times. The hybrid-attention claim (16/64 full-attention layers) keeps footprint viable on 32 GB — but the data still shows full-attention KV read cost dominating single-token generation: sustained gen t/s declines monotonically as live context grows 20K → 65K (120.7 → 57.5 t/s), and within long tasks degrades further as tokens accumulate (task 1334: tg 90.3 → 59.6 → 65 t/s over 3.8K generated tokens). KV cache sizes/types are not printed in this dump, so VRAM usage at 256K slots cannot be verified from the log (not present in log); the compose config uses q8_0 K+V, doubling cache read bandwidth vs 4-bit but protecting reasoning quality.
- **KV prefix reuse is working:** every task after the first was selected "by LCP similarity" with `f_keep` up to 1.000, so follow-up turns re-evaluated only new deltas (e.g. task 3110 re-processed just 17 of ~65K tokens). Tasks 3517/3609 (after the ~22-min idle gap) show `f_keep = 0.093` then 1.000 — a fresh conversation plus its follow-up; their 92.8–94.8 t/s confirms the server returns to the short-context band when context resets.
- **CUDA graphs:** `graphs reused` grows monotonically 12 → 2249 across the 18 tasks — graphs are captured once and reused for every step; no recapture cost appears. The long task 1334 alone reused 1888 graphs.
- **First-request cost:** task 0 (6111-token prompt, 46 gen tokens, 3352.81 ms total) includes cold-start effects; its 70.42 t/s gen is an outlier low for short context.

---

## 5. Health / operational

- **Errors:** none. No `E`-level lines, no exceptions, no OOM messages, no CUDA errors in the 212-line dump.
- **Completeness:** all 18 sessions ended with `stop processing: truncated = 0` (tasks 0…3609) — no mid-generation aborts, no retries visible.
- **Availability:** single continuous process from t=0.00.2 s to t=49.57.0 s (≈49 min 57 s). Model load took ~4.7 s (0.00.4 s → 0.05.4 s "model loaded"). The only idle gap is t=27.42.9 s → 49.51.4 s (~22 min between task 3110 and the new conversation 3517) — normal inactivity, not a fault.
- **Warnings (non-fatal):** (1) `--mlock` deprecation; (2) `LLAMA_ARG_HOST` env var overwritten by `--host`; (3) suggestion to consider `--reasoning-preserve`.
- **Caveat:** the dump does not include the initial startup banner (system info, backend build flags such as `BLACKWELL_NATIVE_FP4`/`USE_GRAPHS`, KV buffer allocation), so those lines cited in the README cannot be verified from this log (not present in log). Operationally, graph reuse and MTP acceptance lines confirm the expected code paths are in use.

**Verdict: server is healthy.**

---

## 6. Recommendations

1. **Fix the deprecation now:** replace `--mlock` with `--load-mode mlock` in `docker-compose.yml` (flagged verbatim by the log: `DEPRECATED: --mlock is deprecated. use --load-mode mlock instead`).
2. **Silence the env conflict:** remove `LLAMA_ARG_HOST` from the environment (likely exported from `.env`); `--host 0.0.0.0` is already on the command line, so this only removes a startup warning.
3. **Consider `--reasoning-preserve`:** the server explicitly notes the chat template supports preserving reasoning; for a hybrid thinking model this prevents downstream clients from losing/re-wrapping reasoning text.
4. **Leave the MTP config as-is:** acceptance of 91–100% (aggregate 95.6%) with `--spec-draft-n-max 2` / `--spec-draft-p-min 0.8` is excellent and far above the README's 60–80% deep-context expectation; there is no case for loosening `n-max` — quality is protected at no throughput penalty.
5. **Reset the README expectations table with measured numbers:** short (≤15K) ~95–130 t/s; mid (15–47K) ~97–121 t/s; deep (≥47K) ~57–90 t/s. The current "85–90 t/s deep" is only valid below ~55K live context and overstates what ≥55K sessions deliver.
6. **If deep-context throughput (≥55K) needs to improve:** (a) lower `--ctx-size` from 262144 to the real working set (e.g. 65536) — the measured slowdown tracks live token count, and a smaller allocation reduces worst-case KV pressure on the 32 GB card; (b) or trial `--cache-type-k/v q4_0/q4_1` to halve KV read bandwidth, accepting a quality risk that the README explicitly guards against with q8_0 ("doom loop" mitigation) — validate on the long-thinking tasks before adopting. Keep `--flash-attn on`.
7. **No concurrency change:** with `n_slots = 1` the measurements are clean single-user numbers; if multi-user serving is added, re-benchmark, as per-request t/s will drop.
8. **Logging completeness (minor):** the container log lost/omitted the initial startup banner; if verifying Blackwell flags (`BLACKWELL_NATIVE_FP4`, `USE_GRAPHS`) is a goal, capture a fresh full startup (e.g. restart and dump immediately) in a future metadata run.
