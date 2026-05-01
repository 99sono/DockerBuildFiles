# docker compsoe

```yml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    platform: linux/amd64
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - /dev/shm:/dev/shm
    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      # 1. FIX: REMOVED `expandable_segments:True`
      # We need PyTorch to keep memory contiguous so the TMA hardware 
      # can map the Cutlass FP4 kernels without crashing.
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      VLLM_USE_V2_MODEL_RUNNER: "1"

      # 2. FIX: Turn autotuning BACK ON so it can find the native hardware paths
      FLASHINFER_AUTOTUNE: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 3. Memory budget set to standard safe levels
      - "--gpu-memory-utilization"
      - "0.85"  

      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "4"
      - "--max-num-batched-tokens"
      - "4096" 

      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # 4. FIX: Use Red Hat's specific hybrid backend
      - "--moe-backend"
      - "flashinfer_cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 5. Bring back CUDA graphs to eliminate CPU bottlenecks
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```
    
# vllm crash

2026-05-01 21:26:40.538 | WARNING 05-01 19:26:40 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:26:40.638 | WARNING 05-01 19:26:40 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299] 
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 21:26:40.640 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:299] 
2026-05-01 21:26:40.644 | (APIServer pid=1) INFO 05-01 19:26:40 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 4096, 'max_num_seqs': 4, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 4, 'moe_backend': 'flashinfer_cutlass'}
2026-05-01 21:26:41.572 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:26:51.223 | (APIServer pid=1) INFO 05-01 19:26:51 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 21:26:51.265 | (APIServer pid=1) INFO 05-01 19:26:51 [nixl_utils.py:32] NIXL is available
2026-05-01 21:26:51.483 | (APIServer pid=1) INFO 05-01 19:26:51 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 21:26:51.484 | (APIServer pid=1) INFO 05-01 19:26:51 [model.py:1680] Using max model len 8192
2026-05-01 21:26:51.849 | (APIServer pid=1) INFO 05-01 19:26:51 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 21:26:51.850 | (APIServer pid=1) INFO 05-01 19:26:51 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=4096.
2026-05-01 21:26:51.850 | (APIServer pid=1) WARNING 05-01 19:26:51 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 21:26:51.850 | (APIServer pid=1) INFO 05-01 19:26:51 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 21:26:51.850 | (APIServer pid=1) INFO 05-01 19:26:51 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:26:51.851 | (APIServer pid=1) INFO 05-01 19:26:51 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:26:54.505 | (APIServer pid=1) INFO 05-01 19:26:54 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:26:54.659 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:27:02.618 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:27:13.748 | INFO 05-01 19:27:13 [nixl_utils.py:32] NIXL is available
2026-05-01 21:27:13.814 | (EngineCore pid=188) INFO 05-01 19:27:13 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [4096], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-05-01 21:27:13.981 | (EngineCore pid=188) WARNING 05-01 19:27:13 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:27:14.098 | (EngineCore pid=188) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:27:14.389 | (EngineCore pid=188) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:27:17.146 | (EngineCore pid=188) INFO 05-01 19:27:17 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:49889 backend=nccl
2026-05-01 21:27:17.439 | (EngineCore pid=188) INFO 05-01 19:27:17 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 21:27:17.439 | (EngineCore pid=188) INFO 05-01 19:27:17 [gpu_worker.py:272] Using V2 Model Runner
2026-05-01 21:27:17.856 | (EngineCore pid=188) Process EngineCore:
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136] EngineCore failed to start.
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136] Traceback (most recent call last):
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     super().__init__(
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.model_executor = executor_class(vllm_config)
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self._init_executor()
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 47, in _init_executor
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.driver_worker.init_device()
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/worker_base.py", line 317, in init_device
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.worker.init_device()  # type: ignore
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 302, in init_device
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.model_runner: GPUModelRunner = GPUModelRunnerV2(  # type: ignore
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/model_runner.py", line 189, in __init__
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.req_states = RequestState(
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                       ^^^^^^^^^^^^^
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/states.py", line 33, in __init__
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self.all_token_ids = StagedWriteTensor(
2026-05-01 21:27:17.856 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                          ^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/buffer_utils.py", line 126, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     self._uva_buf = UvaBuffer(size, dtype)
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]                     ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/buffer_utils.py", line 39, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136]     raise RuntimeError("UVA is not available")
2026-05-01 21:27:17.857 | (EngineCore pid=188) ERROR 05-01 19:27:17 [core.py:1136] RuntimeError: UVA is not available
2026-05-01 21:27:17.857 | (EngineCore pid=188) Traceback (most recent call last):
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.run()
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self._target(*self._args, **self._kwargs)
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 21:27:17.857 | (EngineCore pid=188)     raise e
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 21:27:17.857 | (EngineCore pid=188)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 21:27:17.857 | (EngineCore pid=188)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.857 | (EngineCore pid=188)     return func(*args, **kwargs)
2026-05-01 21:27:17.857 | (EngineCore pid=188)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     super().__init__(
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.model_executor = executor_class(vllm_config)
2026-05-01 21:27:17.857 | (EngineCore pid=188)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.857 | (EngineCore pid=188)     return func(*args, **kwargs)
2026-05-01 21:27:17.857 | (EngineCore pid=188)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self._init_executor()
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 47, in _init_executor
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.driver_worker.init_device()
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/worker_base.py", line 317, in init_device
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.worker.init_device()  # type: ignore
2026-05-01 21:27:17.857 | (EngineCore pid=188)     ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:17.857 | (EngineCore pid=188)     return func(*args, **kwargs)
2026-05-01 21:27:17.857 | (EngineCore pid=188)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 302, in init_device
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.model_runner: GPUModelRunner = GPUModelRunnerV2(  # type: ignore
2026-05-01 21:27:17.857 | (EngineCore pid=188)                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/model_runner.py", line 189, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.req_states = RequestState(
2026-05-01 21:27:17.857 | (EngineCore pid=188)                       ^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/states.py", line 33, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self.all_token_ids = StagedWriteTensor(
2026-05-01 21:27:17.857 | (EngineCore pid=188)                          ^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/buffer_utils.py", line 126, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     self._uva_buf = UvaBuffer(size, dtype)
2026-05-01 21:27:17.857 | (EngineCore pid=188)                     ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:17.857 | (EngineCore pid=188)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu/buffer_utils.py", line 39, in __init__
2026-05-01 21:27:17.857 | (EngineCore pid=188)     raise RuntimeError("UVA is not available")
2026-05-01 21:27:17.857 | (EngineCore pid=188) RuntimeError: UVA is not available
2026-05-01 21:27:18.367 | [rank0]:[W501 19:27:18.700786274 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 21:27:19.056 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 21:27:19.056 | (APIServer pid=1)     sys.exit(main())
2026-05-01 21:27:19.056 | (APIServer pid=1)              ^^^^^^
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 21:27:19.056 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 21:27:19.056 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 21:27:19.056 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 21:27:19.056 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 21:27:19.056 | (APIServer pid=1)     return runner.run(main)
2026-05-01 21:27:19.056 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 21:27:19.056 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 21:27:19.056 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 21:27:19.056 | (APIServer pid=1)     return await main
2026-05-01 21:27:19.056 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 21:27:19.056 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 21:27:19.057 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 21:27:19.057 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 21:27:19.057 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 21:27:19.057 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 21:27:19.057 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 21:27:19.057 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 21:27:19.057 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 21:27:19.057 | (APIServer pid=1)     return cls(
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 21:27:19.057 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 21:27:19.057 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:19.057 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 21:27:19.057 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:27:19.057 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 21:27:19.057 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:27:19.057 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 21:27:19.058 | (APIServer pid=1)     super().__init__(
2026-05-01 21:27:19.058 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 21:27:19.058 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 21:27:19.058 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 21:27:19.058 | (APIServer pid=1)     next(self.gen)
2026-05-01 21:27:19.058 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 21:27:19.058 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 21:27:19.058 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 21:27:19.058 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 21:27:19.058 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}