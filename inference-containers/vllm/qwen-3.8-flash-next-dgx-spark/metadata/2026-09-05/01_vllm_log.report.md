# vLLM Docker Log Report — `inference-containers/vllm/qwen-3.8-flash-next-dgx-spark/mia-nvfp4/metadata/2026-09-05/01_vllm_log.txt`

- generated: 2026-09-05 19:35:28
- input lines: 702 | log range: 2026-09-05 14:18:36 → 2026-09-05 14:56:00 (container clock)
- engine samples: 46 | spec samples: 40 | http access: 30 | warnings: 25 | noise families: 532

## 1. Startup

| field | value |
|---|---|
| vLLM version | `0.1.dev20073+g8e685d198` |
| model | `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4` |
| architecture(s) | `Qwen3_8FlashNextForConditionalGeneration`, `Qwen3_8FlashNextMTP` |
| server | http://0.0.0.0:8000 |
| supported tasks | ['generate'] |
| non-default args |
  - `model` = Mia-AiLab/Qwen3.8-Flash-Next-NVFP4
  - `served_model_name` = qwen3.8-flash-next
  - `max_model_len` = 262144
  - `quantization` = modelopt
  - `gpu_memory_utilization` = 0.78
  - `kv_cache_dtype` = fp8
  - `max_num_batched_tokens` = 2048
  - `max_num_seqs` = 4
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
| available KV memory | 14.57 GiB |
| GPU KV cache size | 878,055 tokens (max concurrency 3.35× for 262,144 tok/req) |
| weight-load time | 488.5 s, 61.4 s |
| model load | 72.4 GiB, 563.0 s |
| init engine (profile+KV+warmup) | 123.96 s |
| CUDA-graph capture | 3 s, 0.19 GiB |
| multi-modal warmup | 17.469 s |
| torch threads | 20 → 1 |
| attention block size | 3200 tokens |
| encoder cache budget | 16,384 tokens |
| PLE n-gram table | 320,001,536 rows × 90 B = 26.82 GiB (mmap) |
| PLE offload | matched 260 tensors, 4 entries |
| PLE weight load | complete |

## 2. Requests

_vLLM INFO logs carry no per-request token counts; a request is only visible via its HTTP access line and the engine's `Running` gauge._

### 2.1 Active-serving windows

Consecutive engine samples with `Running > 0` (samples are ~10 s apart).

| # | start | end | samples | est. span | peak running |
|---|---|---|---|---|---|
| 1 | 14:32:10 | 14:32:10 | 1 | 0 s | 1 |
| 2 | 14:36:50 | 14:36:50 | 1 | 0 s | 1 |
| 3 | 14:41:50 | 14:42:00 | 2 | 10 s | 2 |
| 4 | 14:42:40 | 14:43:50 | 8 | 70 s | 1 |
| 5 | 14:48:50 | 14:49:00 | 2 | 10 s | 1 |
| 6 | 14:53:00 | 14:56:00 | 19 | 180 s | 1 |

### 2.2 HTTP access summary

| method | path | status | count |
|---|---|---|---|
| POST | `/v1/chat/completions` | 200 | 14 |
| GET | `/v1/models` | 200 | 7 |
| GET | `/health` | 200 | 6 |
| POST | `/v1/chat/completions` | 401 | 2 |
| GET | `/v1/models` | 401 | 1 |

**Failures (status ≥ 400): 3**

| # | method | path | status | reason |
|---|---|---|---|---|
| 6 | GET | `/v1/models` | 401 | Unauthorized |
| 7 | POST | `/v1/chat/completions` | 401 | Unauthorized |
| 8 | POST | `/v1/chat/completions` | 401 | Unauthorized |

## 3. Engine & speculative-decode timeline

One row per 10 s engine sample; the companion SpecDecoding line is joined on the same timestamp (`—` when that interval had no speculation).

| time | prompt t/s | gen t/s | run | wait | KV% | prefix% | acc-len | acc t/s | draft t/s | acc tok | draft tok | pos1 | pos2 | pos3 | draft acc% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 14:32:00 | 7.0 | 12.5 | 0 | 0 | 0.0 | 0.0 | 3.10 | 1.4 | 2.0 | 86 | 123 | 0.780 | 0.683 | 0.634 | 69.9 |
| 14:32:10 | 7.0 | 11.7 | 1 | 0 | 5.2 | 0.0 | 3.05 | 7.8 | 11.4 | 78 | 114 | 0.816 | 0.658 | 0.579 | 68.4 |
| 14:32:20 | 32.1 | 7.3 | 0 | 0 | 0.0 | 0.0 | 2.85 | 4.8 | 7.8 | 48 | 78 | 0.769 | 0.615 | 0.462 | 61.5 |
| 14:32:30 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:36:50 | 7.4 | 4.0 | 1 | 0 | 5.2 | 0.0 | 3.00 | 0.1 | 0.1 | 26 | 39 | 0.769 | 0.692 | 0.538 | 66.7 |
| 14:37:00 | 0.0 | 1.0 | 0 | 0 | 0.0 | 0.0 | 2.50 | 0.6 | 1.2 | 6 | 12 | 0.750 | 0.500 | 0.250 | 50.0 |
| 14:37:10 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:41:50 | 661.0 | 3.2 | 2 | 0 | 10.8 | 0.0 | 2.00 | 0.1 | 0.2 | 15 | 45 | 0.533 | 0.333 | 0.133 | 33.3 |
| 14:42:00 | 31.1 | 32.4 | 1 | 0 | 5.2 | 0.0 | 2.20 | 17.7 | 44.1 | 177 | 441 | 0.599 | 0.361 | 0.245 | 40.1 |
| 14:42:10 | 25.7 | 13.5 | 0 | 0 | 0.0 | 0.0 | 2.76 | 8.6 | 14.7 | 86 | 147 | 0.755 | 0.571 | 0.429 | 58.5 |
| 14:42:20 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:42:40 | 636.7 | 20.9 | 1 | 0 | 5.8 | 0.0 | 2.63 | 4.3 | 7.9 | 129 | 237 | 0.696 | 0.532 | 0.405 | 54.4 |
| 14:42:50 | 0.0 | 30.3 | 1 | 0 | 5.8 | 0.0 | 2.30 | 17.1 | 39.6 | 171 | 396 | 0.689 | 0.394 | 0.212 | 43.2 |
| 14:43:00 | 0.0 | 30.9 | 1 | 0 | 5.8 | 0.0 | 2.36 | 17.8 | 39.3 | 178 | 393 | 0.672 | 0.435 | 0.252 | 45.3 |
| 14:43:10 | 0.0 | 34.4 | 1 | 0 | 5.8 | 0.0 | 2.61 | 21.2 | 39.6 | 212 | 396 | 0.712 | 0.538 | 0.356 | 53.5 |
| 14:43:20 | 0.0 | 36.4 | 1 | 0 | 5.8 | 0.0 | 2.78 | 23.3 | 39.3 | 233 | 393 | 0.748 | 0.573 | 0.458 | 59.3 |
| 14:43:30 | 0.0 | 36.5 | 1 | 0 | 5.8 | 0.0 | 2.79 | 23.4 | 39.3 | 234 | 393 | 0.786 | 0.595 | 0.405 | 59.5 |
| 14:43:40 | 71.7 | 27.0 | 1 | 0 | 5.2 | 0.0 | 2.23 | 15.0 | 36.6 | 150 | 366 | 0.590 | 0.402 | 0.238 | 41.0 |
| 14:43:50 | 0.0 | 28.2 | 1 | 0 | 5.2 | 0.0 | 2.17 | 15.2 | 39.0 | 152 | 390 | 0.585 | 0.354 | 0.231 | 39.0 |
| 14:44:00 | 0.0 | 1.8 | 0 | 0 | 0.0 | 0.0 | 4.00 | 1.5 | 1.5 | 15 | 15 | 1.000 | 1.000 | 1.000 | 100.0 |
| 14:44:10 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:45:00 | 66.3 | 19.2 | 0 | 0 | 0.0 | 0.0 | 2.23 | 1.8 | 4.3 | 107 | 261 | 0.598 | 0.391 | 0.241 | 41.0 |
| 14:45:10 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:48:50 | 674.9 | 23.9 | 1 | 0 | 5.8 | 0.0 | 2.33 | 0.6 | 1.3 | 136 | 306 | 0.686 | 0.402 | 0.245 | 44.4 |
| 14:49:00 | 91.0 | 24.0 | 1 | 0 | 5.2 | 0.0 | 1.96 | 11.7 | 36.6 | 117 | 366 | 0.508 | 0.287 | 0.164 | 32.0 |
| 14:49:10 | 0.0 | 15.7 | 0 | 0 | 0.0 | 0.0 | 2.71 | 9.9 | 17.4 | 99 | 174 | 0.793 | 0.552 | 0.362 | 56.9 |
| 14:49:20 | 0.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | — | — | — | — | — | — | — | — | — |
| 14:53:00 | 537.2 | 12.9 | 1 | 0 | 5.8 | 10.1 | 2.78 | 0.4 | 0.6 | 82 | 138 | 0.804 | 0.587 | 0.391 | 59.4 |
| 14:53:10 | 0.0 | 43.4 | 1 | 0 | 5.8 | 10.1 | 3.31 | 30.3 | 39.3 | 303 | 393 | 0.947 | 0.786 | 0.580 | 77.1 |
| 14:53:20 | 0.0 | 31.7 | 1 | 0 | 5.8 | 10.1 | 2.40 | 18.5 | 39.6 | 185 | 396 | 0.674 | 0.424 | 0.303 | 46.7 |
| 14:53:30 | 0.0 | 35.1 | 1 | 0 | 6.1 | 10.1 | 2.64 | 21.8 | 39.9 | 218 | 399 | 0.759 | 0.556 | 0.323 | 54.6 |
| 14:53:40 | 0.0 | 27.1 | 1 | 0 | 6.1 | 10.1 | 2.05 | 13.9 | 39.6 | 139 | 396 | 0.530 | 0.318 | 0.205 | 35.1 |
| 14:53:50 | 0.0 | 31.3 | 1 | 0 | 6.1 | 10.1 | 2.39 | 18.2 | 39.3 | 182 | 393 | 0.626 | 0.443 | 0.321 | 46.3 |
| 14:54:00 | 0.0 | 31.3 | 1 | 0 | 6.1 | 10.1 | 2.39 | 18.2 | 39.3 | 182 | 393 | 0.649 | 0.427 | 0.313 | 46.3 |
| 14:54:10 | 0.0 | 28.9 | 1 | 0 | 6.1 | 10.1 | 2.19 | 15.7 | 39.6 | 157 | 396 | 0.606 | 0.371 | 0.212 | 39.6 |
| 14:54:20 | 0.0 | 28.6 | 1 | 0 | 6.1 | 10.1 | 2.15 | 15.3 | 39.9 | 153 | 399 | 0.571 | 0.368 | 0.211 | 38.3 |
| 14:54:30 | 0.0 | 30.7 | 1 | 0 | 6.1 | 10.1 | 2.33 | 17.5 | 39.6 | 175 | 396 | 0.629 | 0.402 | 0.295 | 44.2 |
| 14:54:40 | 0.0 | 28.3 | 1 | 0 | 6.1 | 10.1 | 2.16 | 15.2 | 39.3 | 152 | 393 | 0.573 | 0.351 | 0.237 | 38.7 |
| 14:54:50 | 0.0 | 32.8 | 1 | 0 | 6.1 | 10.1 | 2.52 | 19.8 | 39.0 | 198 | 390 | 0.723 | 0.477 | 0.323 | 50.8 |
| 14:55:00 | 0.0 | 27.2 | 1 | 0 | 6.1 | 10.1 | 2.12 | 14.4 | 38.4 | 144 | 384 | 0.555 | 0.344 | 0.227 | 37.5 |
| 14:55:10 | 0.0 | 26.5 | 1 | 0 | 6.1 | 10.1 | 2.10 | 13.9 | 37.8 | 139 | 378 | 0.524 | 0.349 | 0.230 | 36.8 |
| 14:55:20 | 0.0 | 28.7 | 1 | 0 | 6.4 | 10.1 | 2.26 | 16.0 | 38.1 | 160 | 381 | 0.567 | 0.402 | 0.291 | 42.0 |
| 14:55:30 | 0.0 | 27.5 | 1 | 0 | 6.4 | 10.1 | 2.13 | 14.6 | 38.7 | 146 | 387 | 0.589 | 0.333 | 0.209 | 37.7 |
| 14:55:40 | 0.0 | 30.9 | 1 | 0 | 6.4 | 10.1 | 2.43 | 18.2 | 38.1 | 182 | 381 | 0.630 | 0.480 | 0.323 | 47.8 |
| 14:55:50 | 0.0 | 29.7 | 1 | 0 | 6.4 | 10.1 | 2.34 | 17.0 | 38.1 | 170 | 381 | 0.654 | 0.433 | 0.252 | 44.6 |
| 14:56:00 | 0.0 | 29.6 | 1 | 0 | 6.4 | 10.1 | 2.33 | 16.9 | 38.1 | 169 | 381 | 0.598 | 0.402 | 0.331 | 44.4 |

## 4. Aggregate statistics

### 4.1 Session & throughput

| metric | value |
|---|---|
| engine samples | 46 |
| sample window | 14:32:00 → 14:56:00 (1440 s) |
| peak prompt throughput | 674.9 tok/s |
| peak generation throughput | 43.4 tok/s |
| mean generation throughput (busy samples) | 24.4 tok/s |
| busy samples (gen > 0) | 40 / 46 |
| active-serving windows | 6 |
| serving window (first→last active) | 1430 s |

### 4.2 Speculative decoding

| metric | n | mean | median | min | max | p95 | unit |
|---|---|---|---|---|---|---|---|
| acceptance length | 40 | 2.49 | 2.38 | 1.96 | 4.00 | 3.10 | tok |
| draft acceptance rate | 40 | 49.6 | 45.8 | 32.0 | 100.0 | 69.9 | % |
| accepted throughput | 40 | 13.0 | 15.2 | 0.1 | 30.3 | 23.3 | tok/s |
| drafted throughput | 40 | 28.1 | 38.2 | 0.1 | 44.1 | 39.9 | tok/s |

- per-position acceptance (mean): p1 = 0.676, p2 = 0.478, p3 = 0.335
- session totals: **5691** accepted / **12240** drafted tokens → 46.5% overall acceptance

### 4.3 KV cache & concurrency

| metric | value |
|---|---|
| peak GPU KV cache usage | 10.8% |
| prefix cache hit rate | 0.0% – 10.1% (mean 4.2%) |
| MM cache hit rate (mean) | 0.0% |
| concurrency distribution | 0 req(s): 13, 1 req(s): 32, 2 req(s): 1 |

## 5. Warnings & errors

### 5.1 JIT compilation during inference

First-use Triton kernels compiled mid-serve cause a one-time latency spike.

| time | kernel |
|---|---|
| 14:31:52 | `_qsa_mqa_paged_kernel` |
| 14:31:52 | `_qsa_sparse_paged_gqa_splitk_kernel` |
| 14:36:48 | `_expand_qsa_indices_kernel` |
| 14:41:47 | `_qsa_merge_splitk_kernel` |
| 14:41:49 | `_topk_topp_kernel` |
| 14:52:54 | `_bilinear_pos_embed_kernel` |

### 5.2 HTTP failures

- GET `/v1/models` → 401 (1×)
- POST `/v1/chat/completions` → 401 (2×)

### 5.3 Other warnings (deduped)

| level | count | first seen | message |
|---|---|---|---|
| WARNING | 3 | 14:18:55 | Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored. |
| WARNING | 3 | 14:18:55 | max_num_scheduled_tokens is set to 2048 based on the speculative decoding settings. This may lead to suboptimal performance. Consider increasing max_num_batched_tokens to accommodate the additional draft token slots, or decrease num_speculative_tokens. |
| WARNING | 2 | 14:18:55 | Detected ModelOpt MXFP8 checkpoint. Please note that the format is experimental and could change in future. |
| WARNING | 2 | 14:18:55 | Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 14:18:55 | Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 14:18:55 | Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change. |
| WARNING | 2 | 14:19:23 | MXFP8 layer [N=96, K=2560] is not supported by FlashInferCutlassMxfp8LinearKernel (needs N,K >= 128 and divisible by 32); falling back to BF16 emulation for this shape. |
| WARNING | 2 | 14:27:37 | Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads. |
| WARNING | 1 | 14:31:19 | Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`. |
| WARNING | 1 | 14:28:45 | Draft model Qwen3_8FlashNextMTP does not support external multimodal embeddings. Embeddings from the target model will not be passed to the drafter; using text-only draft inputs instead. |
| WARNING | 1 | 14:18:55 | Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate |
| WARNING | 1 | 14:27:37 | Marlin requires thread-tile padding for some weight shapes in this model. Activations and/or outputs of the padded layers are padded/sliced on every forward; performance may be degraded. |
| WARNING | 1 | 14:18:36 | Unknown vLLM environment variable detected: VLLM_PLE_OFFLOAD_STEP_TIMEOUT |
| WARNING | 1 | 14:18:36 | Unknown vLLM environment variable detected: VLLM_PLE_PACKED_TABLE_DIR |
| WARNING | 1 | 14:18:36 | With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version. |

## 6. Recognized noise (counted, not shown)

Repetitive warmup boilerplate, recognized so it doesn't pollute the S7 canary.

| family | count |
|---|---|
| autotuner | 156 |
| tag-only-prefix | 139 |
| load-progress-bar | 59 |
| transformers-rope | 46 |
| cudagraph-capture | 10 |
| docstring-not-documented | 8 |
| banner-art | 4 |
| hf-unauthenticated | 3 |
| transformers-use_fast | 3 |
| uvicorn-server | 3 |
| triton-make_block_ptr | 2 |
| ple-nonwritable-array | 1 |
| ple-code-snippet | 1 |
| shm-broadcast-wait | 1 |

Benign one-line `INFO` facts without an individual matcher (96 total), grouped by source file:

| source file | count |
|---|---|
| `launcher.py` | 31 |
| `worker.py` | 10 |
| `__init__.py` | 4 |
| `kernel.py` | 4 |
| `nvfp4.py` | 4 |
| `parallel_state.py` | 4 |
| `qwen_gdn_linear_attn.py` | 4 |
| `compilation.py` | 3 |
| `gpu_worker.py` | 3 |
| `weight_utils.py` | 3 |
| `api_utils.py` | 2 |
| `cuda.py` | 2 |
| `flash_attn.py` | 2 |
| `mm_encoder_attention.py` | 2 |
| `ple_layer.py` | 2 |
| `speculator.py` | 2 |
| `base.py` | 1 |
| `cache.py` | 1 |
| `config.py` | 1 |
| `connector.py` | 1 |
| `hf.py` | 1 |
| `interface.py` | 1 |
| `jit_monitor.py` | 1 |
| `kernel_warmup.py` | 1 |
| `marlin_utils.py` | 1 |
| `model_runner.py` | 1 |
| `multiproc_executor.py` | 1 |
| `parser_manager.py` | 1 |
| `scheduler.py` | 1 |
| `topk_topp_sampler.py` | 1 |

## 7. Unrecognized lines (canary)

_none — every line matched a known pattern_
