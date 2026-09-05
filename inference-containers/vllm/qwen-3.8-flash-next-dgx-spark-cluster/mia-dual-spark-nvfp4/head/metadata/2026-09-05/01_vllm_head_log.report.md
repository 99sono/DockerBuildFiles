# vLLM Docker Log Report — `/home/sono99/dev/DockerBuildFiles/inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.txt`

- generated: 2026-09-05 22:37:29
- input lines: 614 | log range: 2026-09-05 20:07:34 → 2026-09-05 20:35:47 (container clock)
- engine samples: 33 | spec samples: 25 | http access: 33 | warnings: 21 | noise families: 476

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

### 2.2 HTTP access summary

| method | path | status | count |
|---|---|---|---|
| POST | `/v1/chat/completions` | 200 | 27 |
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

## 4. Aggregate statistics

### 4.1 Session & throughput

| metric | value |
|---|---|
| engine samples | 33 |
| sample window | 20:19:27 → 20:35:47 (980 s) |
| peak prompt throughput | 2493.0 tok/s |
| peak generation throughput | 53.8 tok/s |
| mean generation throughput (busy samples) | 29.5 tok/s |
| busy samples (gen > 0) | 26 / 33 |
| active-serving windows | 5 |
| serving window (first→last active) | 960 s |

### 4.2 Speculative decoding

| metric | n | mean | median | min | max | p95 | unit |
|---|---|---|---|---|---|---|---|
| acceptance length | 25 | 2.86 | 2.78 | 2.13 | 3.58 | 3.50 | tok |
| draft acceptance rate | 25 | 61.9 | 59.5 | 37.6 | 85.9 | 83.3 | % |
| accepted throughput | 25 | 16.3 | 19.0 | 0.8 | 37.5 | 35.5 | tok/s |
| drafted throughput | 25 | 26.5 | 27.6 | 1.0 | 55.8 | 55.5 | tok/s |

- per-position acceptance (mean): p1 = 0.776, p2 = 0.604, p3 = 0.475
- session totals: **4972** accepted / **8133** drafted tokens → 61.1% overall acceptance

### 4.3 KV cache & concurrency

| metric | value |
|---|---|
| peak GPU KV cache usage | 1.9% |
| prefix cache hit rate | 0.0% – 54.8% (mean 22.2%) |
| concurrency distribution | 0 req(s): 15, 1 req(s): 17, 2 req(s): 1 |

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
