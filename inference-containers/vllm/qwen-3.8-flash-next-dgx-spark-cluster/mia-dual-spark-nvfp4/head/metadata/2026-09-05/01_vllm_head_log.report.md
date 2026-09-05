# vLLM Docker Log Report — `/home/sono99/dev/DockerBuildFiles/inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.txt`

- generated: 2026-09-05 23:15:18
- input lines: 764 | log range: 2026-09-05 20:07:34 → 2026-09-05 21:07:18 (container clock)
- engine samples: 98 | spec samples: 89 | http access: 54 | warnings: 21 | noise families: 476

## 1. Startup

| field | value |
|---|---|
| vLLM version | `0.1.dev20073+g8e685d198` |
| model | `/root/.cache/huggingface/hub/models--Mia-AiLab--Qwen3.8-Flash-Next-NVFP4/snapshots/925d7be6c14c6c9442ef83e8f05b5a3c39304f69` |
| architecture(s) | `Qwen3_8FlashNextForConditionalGeneration`, `Qwen3_8FlashNextMTP` |
| server | http://0.0.0.0:8000 |
| supported tasks | ['generate'] |
| non-default args |
  - `model` = Mia-AiLab/Qwen3.8-Flash-Next-NVFP4
  - `served_model_name` = qwen3.8-flash-next
  - `max_model_len` = 262144
  - `gpu_memory_utilization` = 0.835
  - `kv_cache_dtype` = fp8
  - `max_num_batched_tokens` = 8192
  - `max_num_seqs` = 8
  - `enable_chunked_prefill` = True
  - `spec_method` = mtp
  - `spec_tokens` = 3
  - `reasoning_parser` = qwen3
  - `tool_call_parser` = qwen3_coder
  - `load_strategy` = lazy
| prefix caching | `True` |
| chunked prefill | `True` |
| dtype | `torch` |
| max model len | 262,144 |
| available KV memory | 46.45 GiB |
| GPU KV cache size | 5,021,457 tokens (max concurrency 19.16× for 262,144 tok/req) |
| weight-load time | 367.1 s, 27.2 s |
| model load | 51.58 GiB, 404.4 s |
| init engine (profile+KV+warmup) | 132.38 s |
| CUDA-graph capture | 6 s, 0.58 GiB |
| multi-modal warmup | 14.742 s |
| torch threads | 20 → 1 |
| attention block size | 3200 tokens |
| encoder cache budget | 16,384 tokens |

## 2. Requests

_vLLM INFO logs carry no per-request token counts; a request is only visible via its HTTP access line and the engine's `Running` gauge._

### 2.1 Active-serving windows

Consecutive engine samples with `Running > 0` (samples are ~10 s apart).

| # | start | end | samples | est. span | peak running |
|---|---|---|---|---|---|
| 1 | 20:19:27 | 20:19:27 | 1 | 0 s | 1 |
| 2 | 20:24:27 | 20:24:37 | 2 | 10 s | 2 |
| 3 | 20:28:17 | 20:28:27 | 2 | 10 s | 1 |
| 4 | 20:33:17 | 20:33:37 | 3 | 20 s | 1 |
| 5 | 20:33:57 | 20:35:27 | 10 | 90 s | 1 |
| 6 | 20:56:38 | 20:56:38 | 1 | 0 s | 1 |
| 7 | 20:56:58 | 20:57:08 | 2 | 10 s | 1 |
| 8 | 20:57:28 | 21:02:48 | 33 | 320 s | 1 |
| 9 | 21:03:08 | 21:04:18 | 8 | 70 s | 1 |
| 10 | 21:04:38 | 21:06:58 | 15 | 140 s | 1 |

### 2.2 HTTP access summary

| method | path | status | count |
|---|---|---|---|
| POST | `/v1/chat/completions` | 200 | 48 |
| GET | `/v1/models` | 200 | 4 |
| GET | `/health` | 200 | 1 |
| GET | `/v1/models` | 401 | 1 |

**Failures (status ≥ 400): 1**

| # | method | path | status | reason |
|---|---|---|---|---|
| 2 | GET | `/v1/models` | 401 | Unauthorized |

## 3. Engine & speculative-decode timeline

One row per 10 s engine sample; the companion SpecDecoding line is joined on the same timestamp (`—` when that interval had no speculation).

| time | prompt t/s | gen t/s | run | wait | KV% | prefix% | acc-len | acc t/s | draft t/s | acc tok | draft tok | pos1 | pos2 | pos3 | draft acc% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 20:19:27 | 39.7 | 16.0 | 1 | 0 | 0.9 | 0.0 | 3.22 | 1.1 | 1.4 | 109 | 147 | 0.878 | 0.776 | 0.571 | 74.1 |
| 20:19:37 | 0.0 | 6.0 | 0 | 0 | 0.0 | 0.0 | 3.05 | 4.1 | 6.0 | 41 | 60 | 0.950 | 0.600 | 0.500 | 68.3 |
| 20:19:47 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 20:24:27 | 31.6 | 0.1 | 2 | 0 | 1.9 | 0.0 | — | — | — | — | — | — | — | — | — |
| 20:24:37 | 664.6 | 37.0 | 1 | 0 | 0.9 | 0.0 | 2.55 | 0.8 | 1.5 | 227 | 438 | 0.671 | 0.500 | 0.384 | 51.8 |
| 20:24:47 | 29.7 | 6.6 | 0 | 0 | 0.0 | 0.0 | 2.13 | 3.5 | 9.3 | 35 | 93 | 0.516 | 0.323 | 0.290 | 37.6 |
| 20:24:57 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 20:26:47 | 2493.0 | 26.3 | 0 | 0 | 0.0 | 0.0 | 2.92 | 1.4 | 2.2 | 173 | 270 | 0.789 | 0.678 | 0.456 | 64.1 |
| 20:26:57 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 20:28:17 | 1286.2 | 31.7 | 1 | 0 | 1.2 | 0.0 | 2.69 | 2.2 | 3.9 | 198 | 351 | 0.735 | 0.521 | 0.436 | 56.4 |
| 20:28:27 | 1014.4 | 36.2 | 1 | 0 | 1.0 | 5.4 | 2.47 | 21.5 | 43.8 | 215 | 438 | 0.705 | 0.452 | 0.315 | 49.1 |
| 20:28:37 | 50.5 | 38.0 | 0 | 0 | 0.0 | 5.4 | 2.42 | 22.4 | 47.4 | 224 | 474 | 0.677 | 0.468 | 0.272 | 47.3 |
| 20:28:47 | 0.0 | 0.0 | 0 | 0 | 0.0 | 5.4 | — | — | — | — | — | — | — | — | — |
| 20:30:07 | 978.2 | 10.9 | 0 | 0 | 0.0 | 4.6 | 2.87 | 0.8 | 1.3 | 71 | 114 | 0.763 | 0.658 | 0.447 | 62.3 |
| 20:30:17 | 0.0 | 0.0 | 0 | 0 | 0.0 | 4.6 | — | — | — | — | — | — | — | — | — |
| 20:30:27 | 610.7 | 19.1 | 0 | 0 | 0.0 | 8.2 | 2.49 | 5.8 | 11.6 | 115 | 231 | 0.701 | 0.468 | 0.325 | 49.8 |
| 20:30:37 | 0.0 | 0.0 | 0 | 0 | 0.0 | 8.2 | — | — | — | — | — | — | — | — | — |
| 20:33:17 | 1981.7 | 19.6 | 1 | 0 | 1.1 | 17.3 | 3.36 | 0.8 | 1.0 | 137 | 174 | 0.879 | 0.793 | 0.690 | 78.7 |
| 20:33:27 | 1306.3 | 36.3 | 1 | 0 | 1.4 | 19.6 | 3.50 | 26.0 | 31.2 | 260 | 312 | 0.913 | 0.837 | 0.750 | 83.3 |
| 20:33:37 | 1502.2 | 32.7 | 1 | 0 | 1.5 | 22.7 | 3.58 | 23.7 | 27.6 | 237 | 276 | 0.924 | 0.848 | 0.804 | 85.9 |
| 20:33:47 | 945.2 | 38.2 | 0 | 0 | 0.0 | 29.6 | 3.16 | 26.3 | 36.6 | 263 | 366 | 0.770 | 0.713 | 0.672 | 71.9 |
| 20:33:57 | 1203.5 | 29.2 | 1 | 0 | 1.6 | 34.2 | 2.60 | 17.9 | 33.6 | 179 | 336 | 0.741 | 0.518 | 0.339 | 53.3 |
| 20:34:07 | 633.9 | 48.5 | 1 | 0 | 1.4 | 40.2 | 3.39 | 34.2 | 42.9 | 342 | 429 | 0.909 | 0.790 | 0.692 | 79.7 |
| 20:34:17 | 415.3 | 52.8 | 1 | 0 | 1.4 | 45.7 | 3.44 | 37.5 | 46.2 | 375 | 462 | 0.857 | 0.812 | 0.766 | 81.2 |
| 20:34:27 | 993.3 | 31.9 | 1 | 0 | 1.7 | 49.2 | 2.67 | 19.9 | 35.7 | 199 | 357 | 0.739 | 0.521 | 0.412 | 55.7 |
| 20:34:37 | 1419.0 | 28.0 | 1 | 0 | 1.8 | 51.8 | 3.09 | 19.0 | 27.3 | 190 | 273 | 0.835 | 0.681 | 0.571 | 69.6 |
| 20:34:47 | 0.0 | 51.5 | 1 | 0 | 1.8 | 51.8 | 2.78 | 33.0 | 55.5 | 330 | 555 | 0.773 | 0.578 | 0.432 | 59.5 |
| 20:34:57 | 1149.1 | 21.4 | 1 | 0 | 1.7 | 54.8 | 2.74 | 13.6 | 23.4 | 136 | 234 | 0.795 | 0.551 | 0.397 | 58.1 |
| 20:35:07 | 0.0 | 43.4 | 1 | 0 | 1.7 | 54.8 | 2.35 | 24.9 | 55.5 | 249 | 555 | 0.703 | 0.389 | 0.254 | 44.9 |
| 20:35:17 | 0.0 | 45.7 | 1 | 0 | 1.7 | 54.8 | 2.46 | 27.1 | 55.8 | 271 | 558 | 0.699 | 0.462 | 0.296 | 48.6 |
| 20:35:27 | 0.0 | 53.8 | 1 | 0 | 1.7 | 54.8 | 2.94 | 35.5 | 54.9 | 355 | 549 | 0.820 | 0.639 | 0.481 | 64.7 |
| 20:35:37 | 0.0 | 6.6 | 0 | 0 | 0.0 | 54.8 | 2.52 | 4.1 | 8.1 | 41 | 81 | 0.667 | 0.519 | 0.333 | 50.6 |
| 20:35:47 | 0.0 | 0.0 | 0 | 0 | 0.0 | 54.8 | — | — | — | — | — | — | — | — | — |
| 20:56:38 | 741.8 | 44.0 | 1 | 0 | 1.7 | 58.3 | 2.99 | 0.2 | 0.3 | 292 | 441 | 0.830 | 0.639 | 0.517 | 66.2 |
| 20:56:48 | 512.2 | 43.0 | 0 | 0 | 0.0 | 61.5 | 3.28 | 30.1 | 39.6 | 301 | 396 | 0.886 | 0.773 | 0.621 | 76.0 |
| 20:56:58 | 1051.0 | 29.1 | 1 | 0 | 2.0 | 63.6 | 2.30 | 16.4 | 37.8 | 164 | 378 | 0.619 | 0.413 | 0.270 | 43.4 |
| 20:57:08 | 0.0 | 35.3 | 1 | 0 | 2.2 | 65.7 | 2.42 | 20.7 | 43.8 | 207 | 438 | 0.692 | 0.438 | 0.288 | 47.3 |
| 20:57:18 | 1455.0 | 26.0 | 0 | 0 | 0.0 | 67.8 | 3.00 | 17.4 | 26.1 | 174 | 261 | 0.862 | 0.621 | 0.517 | 66.7 |
| 20:57:28 | 707.9 | 38.5 | 1 | 0 | 1.9 | 69.5 | 2.31 | 21.8 | 49.8 | 218 | 498 | 0.627 | 0.434 | 0.253 | 43.8 |
| 20:57:38 | 0.0 | 56.8 | 1 | 0 | 1.9 | 69.5 | 3.09 | 38.4 | 55.2 | 384 | 552 | 0.880 | 0.663 | 0.543 | 69.6 |
| 20:57:48 | 1261.9 | 24.7 | 1 | 0 | 2.2 | 70.5 | 2.65 | 15.3 | 27.9 | 153 | 279 | 0.677 | 0.548 | 0.419 | 54.8 |
| 20:57:58 | 554.7 | 44.0 | 1 | 0 | 2.0 | 72.3 | 3.16 | 30.0 | 41.7 | 300 | 417 | 0.842 | 0.705 | 0.612 | 71.9 |
| 20:58:08 | 0.0 | 64.6 | 1 | 0 | 2.0 | 72.3 | 3.55 | 46.4 | 54.6 | 464 | 546 | 0.956 | 0.835 | 0.758 | 85.0 |
| 20:58:18 | 907.7 | 29.3 | 1 | 0 | 2.1 | 73.5 | 2.50 | 17.5 | 35.1 | 175 | 351 | 0.684 | 0.470 | 0.342 | 49.9 |
| 20:58:28 | 0.0 | 47.7 | 1 | 0 | 2.1 | 73.5 | 2.59 | 29.3 | 55.2 | 293 | 552 | 0.707 | 0.511 | 0.375 | 53.1 |
| 20:58:38 | 0.0 | 46.0 | 1 | 0 | 2.1 | 73.5 | 2.46 | 27.3 | 56.1 | 273 | 561 | 0.717 | 0.465 | 0.278 | 48.7 |
| 20:58:48 | 0.0 | 45.2 | 1 | 0 | 2.1 | 73.5 | 2.47 | 26.9 | 54.9 | 269 | 549 | 0.705 | 0.448 | 0.317 | 49.0 |
| 20:58:58 | 0.0 | 52.2 | 1 | 0 | 2.1 | 73.5 | 2.82 | 33.7 | 55.5 | 337 | 555 | 0.778 | 0.600 | 0.443 | 60.7 |
| 20:59:08 | 0.0 | 47.3 | 1 | 0 | 2.1 | 73.5 | 2.60 | 29.1 | 54.6 | 291 | 546 | 0.687 | 0.500 | 0.412 | 53.3 |
| 20:59:18 | 0.0 | 45.4 | 1 | 0 | 2.1 | 73.5 | 2.47 | 27.0 | 55.2 | 270 | 552 | 0.685 | 0.446 | 0.337 | 48.9 |
| 20:59:28 | 0.0 | 39.0 | 1 | 0 | 2.1 | 73.5 | 2.13 | 20.7 | 54.9 | 207 | 549 | 0.607 | 0.328 | 0.197 | 37.7 |
| 20:59:38 | 0.0 | 45.2 | 1 | 0 | 2.2 | 73.5 | 2.46 | 26.8 | 55.2 | 268 | 552 | 0.717 | 0.440 | 0.299 | 48.6 |
| 20:59:48 | 0.0 | 44.0 | 1 | 0 | 2.2 | 73.5 | 2.42 | 25.8 | 54.6 | 258 | 546 | 0.643 | 0.451 | 0.324 | 47.3 |
| 20:59:58 | 0.0 | 50.8 | 1 | 0 | 2.2 | 73.5 | 2.76 | 32.4 | 55.2 | 324 | 552 | 0.777 | 0.565 | 0.418 | 58.7 |
| 21:00:08 | 0.0 | 42.9 | 1 | 0 | 2.2 | 73.5 | 2.32 | 24.4 | 55.5 | 244 | 555 | 0.643 | 0.400 | 0.276 | 44.0 |
| 21:00:18 | 932.1 | 35.1 | 1 | 0 | 2.2 | 74.8 | 3.05 | 23.6 | 34.5 | 236 | 345 | 0.817 | 0.678 | 0.557 | 68.4 |
| 21:00:28 | 0.0 | 44.5 | 1 | 0 | 2.3 | 74.8 | 2.43 | 26.2 | 54.9 | 262 | 549 | 0.661 | 0.448 | 0.322 | 47.7 |
| 21:00:38 | 0.0 | 48.5 | 1 | 0 | 2.3 | 74.8 | 2.66 | 30.3 | 54.6 | 303 | 546 | 0.731 | 0.533 | 0.401 | 55.5 |
| 21:00:48 | 910.6 | 44.7 | 1 | 0 | 2.3 | 75.9 | 3.85 | 33.1 | 34.8 | 331 | 348 | 0.983 | 0.948 | 0.922 | 95.1 |
| 21:00:58 | 0.0 | 54.3 | 1 | 0 | 2.3 | 75.9 | 3.02 | 36.3 | 54.0 | 363 | 540 | 0.806 | 0.678 | 0.533 | 67.2 |
| 21:01:08 | 0.0 | 54.7 | 1 | 0 | 2.3 | 75.9 | 3.01 | 36.5 | 54.6 | 365 | 546 | 0.797 | 0.659 | 0.549 | 66.8 |
| 21:01:18 | 0.0 | 60.3 | 1 | 0 | 2.3 | 75.9 | 3.30 | 42.0 | 54.9 | 420 | 549 | 0.934 | 0.765 | 0.596 | 76.5 |
| 21:01:28 | 0.0 | 49.7 | 1 | 0 | 2.3 | 75.9 | 2.70 | 31.3 | 55.2 | 313 | 552 | 0.739 | 0.554 | 0.408 | 56.7 |
| 21:01:38 | 0.0 | 32.0 | 1 | 0 | 2.3 | 75.9 | 1.73 | 13.5 | 55.5 | 135 | 555 | 0.465 | 0.195 | 0.070 | 24.3 |
| 21:01:48 | 0.0 | 40.4 | 1 | 0 | 2.3 | 75.9 | 2.16 | 21.7 | 56.1 | 217 | 561 | 0.588 | 0.353 | 0.219 | 38.7 |
| 21:01:58 | 0.0 | 50.4 | 1 | 0 | 2.3 | 75.9 | 2.75 | 32.1 | 54.9 | 321 | 549 | 0.765 | 0.579 | 0.410 | 58.5 |
| 21:02:08 | 0.0 | 45.7 | 1 | 0 | 2.4 | 75.9 | 2.50 | 27.4 | 54.9 | 274 | 549 | 0.661 | 0.497 | 0.339 | 49.9 |
| 21:02:18 | 0.0 | 38.9 | 1 | 0 | 2.4 | 75.9 | 2.14 | 20.7 | 54.6 | 207 | 546 | 0.599 | 0.324 | 0.214 | 37.9 |
| 21:02:28 | 0.0 | 39.9 | 1 | 0 | 2.4 | 75.9 | 2.18 | 21.6 | 54.9 | 216 | 549 | 0.579 | 0.366 | 0.235 | 39.3 |
| 21:02:38 | 0.0 | 47.1 | 1 | 0 | 2.4 | 75.9 | 2.60 | 29.0 | 54.3 | 290 | 543 | 0.718 | 0.514 | 0.370 | 53.4 |
| 21:02:48 | 0.0 | 56.7 | 1 | 0 | 2.4 | 75.9 | 3.15 | 38.7 | 54.0 | 387 | 540 | 0.894 | 0.694 | 0.561 | 71.7 |
| 21:02:58 | 0.0 | 59.7 | 0 | 0 | 0.0 | 75.9 | 3.52 | 42.8 | 51.0 | 428 | 510 | 0.988 | 0.829 | 0.700 | 83.9 |
| 21:03:08 | 1193.2 | 26.0 | 1 | 0 | 2.4 | 78.5 | 2.63 | 16.0 | 29.4 | 160 | 294 | 0.704 | 0.531 | 0.398 | 54.4 |
| 21:03:18 | 0.0 | 58.0 | 1 | 0 | 2.4 | 78.5 | 3.22 | 40.0 | 54.0 | 400 | 540 | 0.894 | 0.700 | 0.628 | 74.1 |
| 21:03:28 | 0.0 | 68.7 | 1 | 0 | 2.4 | 78.5 | 3.77 | 50.5 | 54.6 | 505 | 546 | 0.978 | 0.912 | 0.885 | 92.5 |
| 21:03:38 | 445.5 | 40.1 | 1 | 0 | 2.4 | 79.6 | 2.76 | 25.5 | 43.5 | 255 | 435 | 0.793 | 0.552 | 0.414 | 58.6 |
| 21:03:48 | 536.0 | 40.4 | 1 | 0 | 2.4 | 80.6 | 2.94 | 26.8 | 41.4 | 268 | 414 | 0.804 | 0.623 | 0.514 | 64.7 |
| 21:03:58 | 0.0 | 66.3 | 1 | 0 | 2.4 | 80.6 | 3.66 | 48.2 | 54.3 | 482 | 543 | 0.994 | 0.878 | 0.790 | 88.8 |
| 21:04:08 | 329.9 | 47.5 | 1 | 0 | 2.5 | 81.5 | 3.16 | 32.4 | 45.0 | 324 | 450 | 0.867 | 0.687 | 0.607 | 72.0 |
| 21:04:18 | 0.0 | 65.8 | 1 | 0 | 2.5 | 81.5 | 3.66 | 47.8 | 54.0 | 478 | 540 | 1.000 | 0.883 | 0.772 | 88.5 |
| 21:04:28 | 462.3 | 44.7 | 0 | 0 | 0.0 | 82.3 | 3.75 | 33.0 | 36.0 | 330 | 360 | 0.992 | 0.925 | 0.833 | 91.7 |
| 21:04:38 | 1080.7 | 30.7 | 1 | 0 | 2.5 | 83.6 | 2.56 | 18.6 | 35.7 | 186 | 357 | 0.714 | 0.496 | 0.353 | 52.1 |
| 21:04:48 | 0.0 | 41.4 | 1 | 0 | 2.5 | 83.6 | 2.24 | 22.9 | 55.5 | 229 | 555 | 0.632 | 0.357 | 0.249 | 41.3 |
| 21:04:58 | 0.0 | 36.5 | 1 | 0 | 2.5 | 83.6 | 1.97 | 18.0 | 55.5 | 180 | 555 | 0.535 | 0.292 | 0.146 | 32.4 |
| 21:05:08 | 0.0 | 39.5 | 1 | 0 | 2.5 | 83.6 | 2.14 | 21.0 | 55.5 | 210 | 555 | 0.589 | 0.351 | 0.195 | 37.8 |
| 21:05:18 | 455.2 | 40.2 | 1 | 0 | 2.5 | 84.2 | 2.75 | 25.6 | 43.8 | 256 | 438 | 0.767 | 0.562 | 0.425 | 58.4 |
| 21:05:28 | 0.0 | 42.9 | 1 | 0 | 2.5 | 84.2 | 2.33 | 24.5 | 55.2 | 245 | 552 | 0.636 | 0.418 | 0.277 | 44.4 |
| 21:05:38 | 0.0 | 47.3 | 1 | 0 | 2.5 | 84.2 | 2.53 | 28.6 | 56.1 | 286 | 561 | 0.743 | 0.481 | 0.305 | 51.0 |
| 21:05:48 | 0.0 | 44.6 | 1 | 0 | 2.5 | 84.2 | 2.40 | 26.0 | 55.8 | 260 | 558 | 0.677 | 0.452 | 0.269 | 46.6 |
| 21:05:58 | 0.0 | 43.1 | 1 | 0 | 2.5 | 84.2 | 2.30 | 24.4 | 56.1 | 244 | 561 | 0.663 | 0.406 | 0.235 | 43.5 |
| 21:06:08 | 0.0 | 47.3 | 1 | 0 | 2.6 | 84.2 | 2.54 | 28.7 | 55.8 | 287 | 558 | 0.661 | 0.500 | 0.382 | 51.4 |
| 21:06:18 | 0.0 | 41.7 | 1 | 0 | 2.6 | 84.2 | 2.22 | 22.9 | 56.4 | 229 | 564 | 0.606 | 0.383 | 0.229 | 40.6 |
| 21:06:28 | 0.0 | 38.9 | 1 | 0 | 2.6 | 84.2 | 2.10 | 20.4 | 55.5 | 204 | 555 | 0.589 | 0.324 | 0.189 | 36.8 |
| 21:06:38 | 492.3 | 41.6 | 1 | 0 | 2.6 | 84.8 | 2.92 | 27.4 | 42.9 | 274 | 429 | 0.762 | 0.629 | 0.524 | 63.9 |
| 21:06:48 | 0.0 | 42.8 | 1 | 0 | 2.6 | 84.8 | 2.36 | 24.7 | 54.3 | 247 | 543 | 0.691 | 0.436 | 0.238 | 45.5 |
| 21:06:58 | 0.0 | 45.7 | 1 | 0 | 2.6 | 84.8 | 2.50 | 27.4 | 54.9 | 274 | 549 | 0.710 | 0.481 | 0.306 | 49.9 |
| 21:07:08 | 0.0 | 19.9 | 0 | 0 | 0.0 | 84.8 | 2.45 | 11.9 | 24.6 | 119 | 246 | 0.646 | 0.439 | 0.366 | 48.4 |
| 21:07:18 | 0.0 | 0.0 | 0 | 0 | 0.0 | 84.8 | — | — | — | — | — | — | — | — | — |

## 4. Aggregate statistics

### 4.1 Session & throughput

| metric | value |
|---|---|
| engine samples | 98 |
| sample window | 20:19:27 → 21:07:18 (2871 s) |
| peak prompt throughput | 2493.0 tok/s |
| peak generation throughput | 68.7 tok/s |
| mean generation throughput (busy samples) | 40.1 tok/s |
| busy samples (gen > 0) | 90 / 98 |
| active-serving windows | 10 |
| serving window (first→last active) | 2851 s |

### 4.2 Speculative decoding

| metric | n | mean | median | min | max | p95 | unit |
|---|---|---|---|---|---|---|---|
| acceptance length | 89 | 2.75 | 2.65 | 1.73 | 3.85 | 3.66 | tok |
| draft acceptance rate | 89 | 58.3 | 54.8 | 24.3 | 95.1 | 88.5 | % |
| accepted throughput | 89 | 24.3 | 25.6 | 0.2 | 50.5 | 42.8 | tok/s |
| drafted throughput | 89 | 42.6 | 54.0 | 0.3 | 56.4 | 56.1 | tok/s |

- per-position acceptance (mean): p1 = 0.753, p2 = 0.563, p3 = 0.434
- session totals: **22838** accepted / **39894** drafted tokens → 57.2% overall acceptance

### 4.3 KV cache & concurrency

| metric | value |
|---|---|
| peak GPU KV cache usage | 2.6% |
| prefix cache hit rate | 0.0% – 84.8% (mean 58.4%) |
| concurrency distribution | 0 req(s): 21, 1 req(s): 76, 2 req(s): 1 |

## 5. Warnings & errors

### 5.1 JIT compilation during inference

First-use Triton kernels compiled mid-serve cause a one-time latency spike.

| time | kernel |
|---|---|
| 20:19:22 | `_qsa_mqa_paged_kernel` |
| 20:19:22 | `_expand_qsa_indices_kernel` |
| 20:19:23 | `_qsa_sparse_paged_gqa_splitk_kernel` |
| 20:19:23 | `layer_norm_fwd_kernel` |
| 20:19:27 | `_qsa_merge_splitk_kernel` |
| 20:24:30 | `_topk_topp_kernel` |

### 5.2 HTTP failures

- GET `/v1/models` → 401 (1×)

### 5.3 Other warnings (deduped)

| level | count | first seen | message |
|---|---|---|---|
| WARNING | 3 | 20:07:51 | Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored. |
| WARNING | 2 | 20:07:51 | Detected ModelOpt MXFP8 checkpoint. Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:07:51 | Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:07:51 | Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:07:51 | Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change. |
| WARNING | 2 | 20:14:39 | Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads. |
| WARNING | 1 | 20:08:27 | Custom collectives are disabled because this multi-node group does not support MNNVL multicast. |
| WARNING | 1 | 20:18:04 | Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`. |
| WARNING | 1 | 20:15:10 | Draft model Qwen3_8FlashNextMTP does not support external multimodal embeddings. Embeddings from the target model will not be passed to the drafter; using text-only draft inputs instead. |
| WARNING | 1 | 20:07:51 | Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate |
| WARNING | 1 | 20:08:28 | MXFP8 layer [N=48, K=2560] is not supported by FlashInferCutlassMxfp8LinearKernel (needs N,K >= 128 and divisible by 32); falling back to BF16 emulation for this shape. |
| WARNING | 1 | 20:14:39 | Marlin requires thread-tile padding for some weight shapes in this model. Activations and/or outputs of the padded layers are padded/sliced on every forward; performance may be degraded. |
| WARNING | 1 | 20:08:27 | SymmMemCommunicator: Device capability 12.1 not supported, communicator is not available. |
| WARNING | 1 | 20:07:34 | With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version. |

## 6. Recognized noise (counted, not shown)

Repetitive warmup boilerplate, recognized so it doesn't pollute the S7 canary.

| family | count |
|---|---|
| autotuner | 162 |
| tag-only-prefix | 128 |
| transformers-rope | 41 |
| load-progress-bar | 36 |
| cudagraph-capture | 13 |
| docstring-not-documented | 6 |
| banner-art | 4 |
| transformers-use_fast | 3 |
| uvicorn-server | 3 |
| triton-make_block_ptr | 2 |
| shm-broadcast-wait | 1 |

Benign one-line `INFO` facts without an individual matcher (77 total), grouped by source file:

| source file | count |
|---|---|
| `launcher.py` | 31 |
| `compilation.py` | 3 |
| `kernel.py` | 3 |
| `nvfp4.py` | 3 |
| `__init__.py` | 2 |
| `api_utils.py` | 2 |
| `arg_utils.py` | 2 |
| `cuda_communicator.py` | 2 |
| `gpu_worker.py` | 2 |
| `parallel_state.py` | 2 |
| `qwen_gdn_linear_attn.py` | 2 |
| `speculator.py` | 2 |
| `weight_utils.py` | 2 |
| `base.py` | 1 |
| `cache.py` | 1 |
| `config.py` | 1 |
| `cuda.py` | 1 |
| `expert_map_manager.py` | 1 |
| `flash_attn.py` | 1 |
| `hf.py` | 1 |
| `interface.py` | 1 |
| `jit_monitor.py` | 1 |
| `kernel_warmup.py` | 1 |
| `marlin_utils.py` | 1 |
| `mm_encoder_attention.py` | 1 |
| `model_runner.py` | 1 |
| `multiproc_executor.py` | 1 |
| `parser_manager.py` | 1 |
| `ple_layer.py` | 1 |
| `pynccl.py` | 1 |
| `scheduler.py` | 1 |
| `topk_topp_sampler.py` | 1 |

## 7. Unrecognized lines (canary)

_none — every line matched a known pattern_
