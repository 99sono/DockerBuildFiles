# vLLM Docker Log Report — `../qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/worker/metadata/2026-09-05/01_vllm_worker_log.txt`

- generated: 2026-09-05 22:54:30
- input lines: 348 | log range: 2026-09-05 20:06:33 → 2026-09-05 20:24:30 (container clock)
- engine samples: 0 | spec samples: 0 | http access: 0 | warnings: 19 | noise families: 310

## 1. Startup

| field | value |
|---|---|
| architecture(s) | `Qwen3_8FlashNextForConditionalGeneration`, `Qwen3_8FlashNextMTP` |
| max model len | 262,144 |
| available KV memory | 44.04 GiB |
| weight-load time | 398.9 s, 11.2 s |
| model load | 51.58 GiB, 416.2 s |
| CUDA-graph capture | 6 s, 0.51 GiB |
| torch threads | 20 → 1 |
| attention block size | 3200 tokens |
| encoder cache budget | 16,384 tokens |

## 2. Requests

_vLLM INFO logs carry no per-request token counts; a request is only visible via its HTTP access line and the engine's `Running` gauge._

### 2.1 Active-serving windows

Consecutive engine samples with `Running > 0` (samples are ~10 s apart).

_no active-serving samples_

### 2.2 HTTP access summary

_no access lines_

## 3. Engine & speculative-decode timeline

One row per 10 s engine sample; the companion SpecDecoding line is joined on the same timestamp (`—` when that interval had no speculation).

| time | prompt t/s | gen t/s | run | wait | KV% | prefix% | acc-len | acc t/s | draft t/s | acc tok | draft tok | pos1 | pos2 | pos3 | draft acc% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

## 4. Aggregate statistics

### 4.1 Session & throughput

_not enough data_

### 4.2 Speculative decoding

_no SpecDecoding samples (speculative decoding off)_

### 4.3 KV cache & concurrency

_no engine samples_

## 5. Warnings & errors

### 5.1 JIT compilation during inference

First-use Triton kernels compiled mid-serve cause a one-time latency spike.

| time | kernel |
|---|---|
| 20:19:22 | `_qsa_mqa_paged_kernel` |
| 20:19:22 | `_expand_qsa_indices_kernel` |
| 20:19:22 | `_qsa_sparse_paged_gqa_splitk_kernel` |
| 20:19:23 | `layer_norm_fwd_kernel` |
| 20:19:27 | `_qsa_merge_splitk_kernel` |
| 20:24:30 | `_topk_topp_kernel` |

### 5.2 HTTP failures

_none_

### 5.3 Other warnings (deduped)

| level | count | first seen | message |
|---|---|---|---|
| WARNING | 2 | 20:06:52 | Detected ModelOpt MXFP8 checkpoint. Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:06:52 | Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:06:52 | Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future. |
| WARNING | 2 | 20:06:52 | Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change. |
| WARNING | 2 | 20:06:52 | Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored. |
| WARNING | 2 | 20:15:11 | Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads. |
| WARNING | 1 | 20:08:27 | Custom collectives are disabled because this multi-node group does not support MNNVL multicast. |
| WARNING | 1 | 20:15:24 | Draft model Qwen3_8FlashNextMTP does not support external multimodal embeddings. Embeddings from the target model will not be passed to the drafter; using text-only draft inputs instead. |
| WARNING | 1 | 20:06:52 | Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate |
| WARNING | 1 | 20:08:28 | MXFP8 layer [N=48, K=2560] is not supported by FlashInferCutlassMxfp8LinearKernel (needs N,K >= 128 and divisible by 32); falling back to BF16 emulation for this shape. |
| WARNING | 1 | 20:15:11 | Marlin requires thread-tile padding for some weight shapes in this model. Activations and/or outputs of the padded layers are padded/sliced on every forward; performance may be degraded. |
| WARNING | 1 | 20:08:27 | SymmMemCommunicator: Device capability 12.1 not supported, communicator is not available. |
| WARNING | 1 | 20:06:33 | With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version. |

## 6. Recognized noise (counted, not shown)

Repetitive warmup boilerplate, recognized so it doesn't pollute the S7 canary.

| family | count |
|---|---|
| autotuner | 163 |
| tag-only-prefix | 84 |
| transformers-rope | 24 |
| docstring-not-documented | 4 |
| triton-make_block_ptr | 2 |
| transformers-use_fast | 1 |

Benign one-line `INFO` facts without an individual matcher (32 total), grouped by source file:

| source file | count |
|---|---|
| `nvfp4.py` | 3 |
| `__init__.py` | 2 |
| `arg_utils.py` | 2 |
| `gpu_worker.py` | 2 |
| `kernel.py` | 2 |
| `parallel_state.py` | 2 |
| `qwen_gdn_linear_attn.py` | 2 |
| `speculator.py` | 2 |
| `weight_utils.py` | 2 |
| `cache.py` | 1 |
| `compilation.py` | 1 |
| `config.py` | 1 |
| `cuda.py` | 1 |
| `expert_map_manager.py` | 1 |
| `flash_attn.py` | 1 |
| `interface.py` | 1 |
| `jit_monitor.py` | 1 |
| `mm_encoder_attention.py` | 1 |
| `model_runner.py` | 1 |
| `ple_layer.py` | 1 |
| `scheduler.py` | 1 |
| `serve.py` | 1 |

## 7. Unrecognized lines (canary)

_none — every line matched a known pattern_
