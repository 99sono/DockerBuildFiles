# compose
```yml
# Nemotron-Cascade-2-30B-A3B-NVFP4 (Optimized Speed Path)
# Hardware: RTX 5090 (Blackwell) + WSL2
# Strategy: Native Blackwell FP4 execution with high batching
version: "3.9"

services:
  nemotron-cascade:
    image: vllm/vllm-openai:nightly
    container_name: nemotron-cascade-2-nvfp4
    hostname: nemotron-cascade-2-nvfp4
    platform: linux/amd64

    ports:
      - "8000:8000"

    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface

    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      # Stable process model on Blackwell + WSL2
      VLLM_WORKER_MULTIPROC_METHOD: spawn

      # ✅ REQUIRED for NVFP4 MoE (this was the missing piece)
      VLLM_USE_FLASHINFER_MOE_FP4: "1"
      VLLM_FLASHINFER_MOE_BACKEND: throughput

      # Optional but useful for debugging kernel selection
      # VLLM_LOGGING_LEVEL: INFO

    command:
      # Model
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--served-model-name"
      - "nemotron-cascade-2-nvfp4"

      # Trust model code (required for Nemotron)
      - "--trust-remote-code"

      # Quantization
      - "--quantization"
      - "modelopt_fp4"

      # KV cache
      - "--kv-cache-dtype"
      - "fp8_e4m3"

      # Memory management
      - "--gpu-memory-utilization"
      - "0.85"

      # ⚠️ Performance‑safe context for testing
      # (you can raise later once batching looks healthy)
      - "--max-model-len"
      - "65536"

      # Enable meaningful batching
      - "--max-num-seqs"
      - "128"
      - "--max-num-batched-tokens"
      - "32768"

      # ✅ CUDA Graph capture (critical for decode speed)
      - "--max-cudagraph-capture-size"
      - "512"

      # Nemotron specifics
      - "--mamba-ssm-cache-dtype"
      - "float32"
      - "--reasoning-parser"
      - "nemotron_v3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # Server
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

    networks:
      - development-network

networks:
  development-network:
    external: true

```

# vllm crash log
(EngineCore pid=176) ERROR 04-23 21:09:12 [dump_input.py:79] Dumping scheduler output for model execution: SchedulerOutput(scheduled_new_reqs=[], scheduled_cached_reqs=CachedRequestData(req_ids=['chatcmpl-a63edc53871ca0b0-8587678b'],resumed_req_ids=set(),new_token_ids_lens=[],all_token_ids_lens={},new_block_ids=[None],num_computed_tokens=[29622],num_output_tokens=[2]), num_scheduled_tokens={chatcmpl-a63edc53871ca0b0-8587678b: 1}, total_num_scheduled_tokens=1, scheduled_spec_decode_tokens={}, scheduled_encoder_inputs={}, num_common_prefix_blocks=[0, 0, 0, 0, 0], finished_req_ids=[], free_encoder_mm_hashes=[], preempted_req_ids=[], has_structured_output_requests=false, pending_structured_output_tokens=false, num_invalid_spec_tokens=null, kv_connector_metadata=null, ec_connector_metadata=null, new_block_ids_to_zero=null)

(EngineCore pid=176) ERROR 04-23 21:09:12 [dump_input.py:81] Dumping scheduler stats: SchedulerStats(num_running_reqs=1, num_waiting_reqs=0, num_skipped_waiting_reqs=0, step_counter=0, current_wave=0, kv_cache_usage=0.040000000000000036, prefix_cache_stats=PrefixCacheStats(reset=False, requests=0, queries=0, hits=0, preempted_requests=0, preempted_queries=0, preempted_hits=0), connector_prefix_cache_stats=None, kv_cache_eviction_events=[], spec_decoding_stats=None, kv_connector_stats=None, waiting_lora_adapters={}, running_lora_adapters={}, cudagraph_stats=None, perf_stats=None)

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] EngineCore encountered a fatal error.

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] Traceback (most recent call last):

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1125, in run_engine_core

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     engine_core.run_busy_loop()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1166, in run_busy_loop

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     self._process_engine_step()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1205, in _process_engine_step

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     outputs, model_executed = self.step_fn()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]                               ^^^^^^^^^^^^^^

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 523, in step_with_batch_queue

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     model_output = future.result()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]                    ^^^^^^^^^^^^^^^

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/lib/python3.12/concurrent/futures/_base.py", line 449, in result

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     return self.__get_result()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]            ^^^^^^^^^^^^^^^^^^^

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/lib/python3.12/concurrent/futures/_base.py", line 401, in __get_result

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     raise self._exception

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/lib/python3.12/concurrent/futures/thread.py", line 59, in run

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     result = self.fn(*self.args, **self.kwargs)

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 269, in get_output

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134]     self.async_copy_ready_event.synchronize()

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] torch.AcceleratorError: CUDA error: an illegal instruction was encountered

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] Search for `cudaErrorIllegalInstruction' in https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html for more information.

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] For debugging consider passing CUDA_LAUNCH_BLOCKING=1

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] Compile with `TORCH_USE_CUDA_DSA` to enable device-side assertions.

(EngineCore pid=176) ERROR 04-23 21:09:12 [core.py:1134] 

(EngineCore pid=176) Process EngineCore:

(EngineCore pid=176) Traceback (most recent call last):

(EngineCore pid=176)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap

(EngineCore pid=176)     self.run()

(EngineCore pid=176)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run

(EngineCore pid=176)     self._target(*self._args, **self._kwargs)

(EngineCore pid=176)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core

(EngineCore pid=176)     raise e

(EngineCore pid=176)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1125, in run_engine_core

(EngineCore pid=176)     engine_core.run_busy_loop()

(EngineCore pid=176)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1166, in run_busy_loop

(EngineCore pid=176)     self._process_engine_step()

(EngineCore pid=176)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1205, in _process_engine_step

