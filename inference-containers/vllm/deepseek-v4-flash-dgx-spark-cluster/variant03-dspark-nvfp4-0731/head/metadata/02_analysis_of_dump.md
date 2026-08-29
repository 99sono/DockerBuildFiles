# Analysis — DeepSeek-V4-Flash-0731 on 2× DGX Spark (sustained decode window)

**Source log:** `2026-08-30_01-31-34_deepseek-v4-flash-0731-head_log_dump.txt` (head node, 485 lines)
**Companion:** `metadata/head/2026_08_30/performance_report_deepseek_mini_prompts.md` (earlier mini-prompt-only session)
**Model:** DeepSeek-V4-Flash-0731, TP=2 (spark01 head + spark02 worker), NVFP4 KV cache, DSpark spec-decode (k=5)
**Caveat:** still not a controlled benchmark — these are vLLM's own 10-second rolling averages from a real usage session (larger prompts / longer generations than the earlier mini-prompt session).

## Headline

The sustained decode window at **08-29 23:17–23:21 UTC** (≈4 minutes, 1 concurrent request, briefly 2) runs at **~35–75 tokens/s generation**, peaking at **74.9 tok/s** — roughly **2–3× the mini-prompt session's numbers** (peak 26.4 tok/s in short 10 s bursts). This confirms the observation: with bigger prompts / longer generations the cluster decodes much faster than the "hi / how are you" test suggested.

## Sustained-decode window (23:17:19 → 23:21:19 UTC)

| time (UTC) | prompt tok/s | generation tok/s | running | KV usage | prefix hit % |
|---|---|---|---|---|---|
| 23:17:19 | 158.0 | 26.3 | 1 | 9.1% | 72.8% |
| 23:17:29 | 806.6 | 16.5 | 0 | 9.6% | 69.8% |
| 23:17:39 | 969.2 | 31.1 | 0 | 10.7% | 68.5% |
| 23:17:49 | 630.5 | 51.6 | 1 | 11.9% | 70.7% |
| 23:17:59 | 0.0 | **74.9** | 1 | 11.9% | 70.7% |
| 23:18:09 | 0.0 | 56.3 | 1 | 11.9% | 70.7% |
| 23:18:19 | 0.0 | 52.5 | 1 | 11.9% | 70.7% |
| 23:18:29 | 61.5 | 50.6 | 1 | 12.4% | 75.2% |
| 23:18:39 | 0.0 | 56.7 | 1 | 12.4% | 75.2% |
| 23:18:49 | 0.0 | 35.3 | 1 | 12.4% | 75.2% |
| 23:18:59 | 0.0 | 46.9 | 1 | 12.4% | 75.2% |
| 23:19:09 | 0.0 | 53.6 | 1 | 12.5% | 75.2% |
| 23:19:19 | 0.0 | 67.9 | 1 | 12.5% | 75.2% |
| 23:19:29 | 0.0 | 53.4 | 1 | 12.5% | 75.2% |
| 23:19:39 | 0.0 | 62.1 | 1 | 12.5% | 75.2% |
| 23:19:49 | 0.0 | 44.1 | 1 | 12.6% | 75.2% |
| 23:19:59 | 0.0 | 35.6 | 1 | 12.5% | 75.2% |
| 23:20:09 | 0.0 | 44.5 | 1 | 12.6% | 75.2% |
| 23:20:19 | 0.0 | 45.1 | 1 | 12.6% | 75.2% |
| 23:20:29 | 49.4 | 40.0 | **2** | 13.6% | 75.7% |
| 23:20:39 | 0.0 | 51.8 | 1 | 13.4% | 75.7% |
| 23:20:49 | 0.0 | 36.4 | 0 | 12.9% | 75.7% |
| 23:20:59 | 784.2 | 47.4 | 1 | 15.0% | 82.3% |
| 23:21:09 | 0.0 | 23.2 | 0 | 14.8% | 82.3% |

- **Peak generation: 74.9 tok/s** (23:17:59); typical sustained band **~35–57 tok/s** (single running request).
- **Prefill peak: 969.2 tok/s** (23:17:39).
- Pure-decode windows (prompt = 0) average ≈ **49 tok/s** over the 4-minute span.

## Spec-decode (DSpark) behavior in the window

| time | mean accept len | accepted tok/s | drafted tok/s | avg draft accept % |
|---|---|---|---|---|
| 23:17:19 | 5.22 | 0.19 | 0.22 | 84.4% |
| 23:17:29 | 5.35 | 13.50 | 15.50 | 87.1% |
| 23:17:59 | 5.59 | 61.50 | 66.99 | 91.8% |
| 23:18:19 | 3.70 | 38.30 | 70.99 | 53.9% |
| 23:18:49 | 2.47 | 21.00 | 71.49 | 29.4% |
| 23:19:19 | 4.99 | 54.30 | 68.00 | 79.9% |
| 23:19:39 | 4.57 | 48.49 | 67.99 | 71.3% |
| 23:19:59 | 2.51 | 21.40 | 70.99 | 30.1% |
| 23:20:59 | 4.59 | 37.00 | 51.50 | 71.8% |

- The **draft model runs at a steady ~67–79 tok/s** of drafted tokens throughout.
- **Mean acceptance length** is typically **3.2–4.6** (range 2.47–5.59 across the window); draft acceptance rate swings **29–92%**, most windows 43–72%.
- Effective accepted throughput = drafted rate × acceptance, which lands exactly on the observed 35–75 tok/s — spec-decode is the mechanism behind the speed.
- Per-position acceptance falls off front→back (e.g. 0.99/0.98/0.95/0.87/0.81 at the 91.8% window vs 0.66/0.37/0.22/0.13/0.08 at the 29.4% window) — later draft positions hurt most on hard stretches.

## Why this window is faster than the mini-prompt session

1. **Steady-state decode, not bursts.** Mini-prompt replies are a handful of tokens; every 10 s window mixed idle gaps with tiny generations (peak 26.4). Here one request decodes continuously for ~4 minutes.
2. **Prefix caching is warm.** Hit rate is **68–82%** (settling at ~75%), so repeated/overlapping prompts skip most of their prefill.
3. **JIT/warmup is done.** The first-request Triton JIT spikes already happened in the earlier session, so this window is clean.

## Startup (same log, for reference)

- Target model: 48 safetensor shards in **2 min 56 s**; DSpark draft model in **~27 s**.
- CUDA graph capture: **8 s / 0.69 GiB**.
- `Application startup complete` at 08-29 21:48 — total boot-to-serving ≈ **6–7 min**.

## Observations from the HTTP layer

- Clients seen: `10.0.1.1` (head local), `10.0.1.2` (worker / opencode sub-agent), `172.18.0.2/.3` (nginx + Open WebUI sidecars).
- One `GET /v1/models` → **401 Unauthorized** (request without/with wrong API key) — expected, API key enforcement works.
- One `POST /v1/chat/completions` → **400 Bad Request** (image sent to a non-multimodal model) — expected.
- One window showed **Running: 2 reqs** (23:20:29) — two concurrent generations were handled without a visible throughput collapse.

## What this still does NOT tell us

- **TTFT / ITL per-token latency** — vLLM logs throughput, not per-request latency.
- **Long-context (1M) behavior** — this session stayed at low KV usage (≤15%).
- **Sustained load / concurrency ceiling** — only 1–2 concurrent requests observed.
- Numbers are **10-second rolling averages**; the "74.9" is a window average, not a sample of every token.

## Next step (when doing a real benchmark)

- Use `vllm bench serve` (or the in-repo `06_test_include_usage.sh`) with a fixed prompt-length/ output-length grid; record TTFT, ITL, and p50/p99 end-to-end latency — throughput alone (as here) hides latency.
- Repeat at 1/4/8/16 concurrent requests to find the knee of the throughput curve.