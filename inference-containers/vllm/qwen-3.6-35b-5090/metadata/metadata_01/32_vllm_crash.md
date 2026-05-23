2026-04-19 12:18:36.268 | WARNING 04-19 10:18:36 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299] 
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:18:36.353 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:299] 
2026-04-19 12:18:36.356 | (APIServer pid=1) INFO 04-19 10:18:36 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 32, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 12:18:36.755 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:18:46.489 | (APIServer pid=1) INFO 04-19 10:18:46 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 12:18:46.489 | (APIServer pid=1) INFO 04-19 10:18:46 [model.py:1685] Using max model len 8192
2026-04-19 12:18:46.756 | (APIServer pid=1) INFO 04-19 10:18:46 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 12:18:46.756 | (APIServer pid=1) INFO 04-19 10:18:46 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 12:18:46.757 | (APIServer pid=1) WARNING 04-19 10:18:46 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 12:18:46.757 | (APIServer pid=1) INFO 04-19 10:18:46 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 12:18:46.757 | (APIServer pid=1) INFO 04-19 10:18:46 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:18:46.757 | (APIServer pid=1) INFO 04-19 10:18:46 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:18:49.415 | (APIServer pid=1) INFO 04-19 10:18:49 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 12:18:49.473 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:18:57.285 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:19:08.142 | (EngineCore pid=207) INFO 04-19 10:19:08 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 64, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-04-19 12:19:08.339 | (EngineCore pid=207) WARNING 04-19 10:19:08 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:19:08.450 | (EngineCore pid=207) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:19:09.262 | (EngineCore pid=207) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:19:11.519 | (EngineCore pid=207) INFO 04-19 10:19:11 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:46559 backend=nccl
2026-04-19 12:19:11.810 | (EngineCore pid=207) INFO 04-19 10:19:11 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 12:19:18.182 | (EngineCore pid=207) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:19:23.355 | (EngineCore pid=207) INFO 04-19 10:19:23 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 12:19:23.694 | (EngineCore pid=207) INFO 04-19 10:19:23 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 12:19:23.695 | (EngineCore pid=207) INFO 04-19 10:19:23 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 12:19:23.745 | (EngineCore pid=207) INFO 04-19 10:19:23 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 12:19:23.746 | (EngineCore pid=207) INFO 04-19 10:19:23 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 12:19:24.098 | (EngineCore pid=207) INFO 04-19 10:19:24 [nvfp4.py:203] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 12:19:24.156 | (EngineCore pid=207) INFO 04-19 10:19:24 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-04-19 12:19:24.749 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 12:19:24.749 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 12:19:25.646 | (EngineCore pid=207) INFO 04-19 10:19:25 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 57.05 GiB.
2026-04-19 12:19:25.646 | (EngineCore pid=207) INFO 04-19 10:19:25 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 12:19:25.646 | (EngineCore pid=207) 
2026-04-19 12:19:25.646 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-04-19 12:19:51.770 | (EngineCore pid=207) 
2026-04-19 12:19:51.770 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:26<00:52, 26.12s/it]
2026-04-19 12:19:52.999 | (EngineCore pid=207) 
2026-04-19 12:19:52.999 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  7.23s/it]
2026-04-19 12:19:52.999 | (EngineCore pid=207) 
2026-04-19 12:19:52.999 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  9.12s/it]
2026-04-19 12:19:52.999 | (EngineCore pid=207) 
2026-04-19 12:19:53.040 | (EngineCore pid=207) INFO 04-19 10:19:53 [default_loader.py:384] Loading weights took 27.49 seconds
2026-04-19 12:19:53.244 | (EngineCore pid=207) INFO 04-19 10:19:53 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 12:19:53.877 | (EngineCore pid=207) INFO 04-19 10:19:53 [gpu_model_runner.py:4837] Model loading took 21.88 GiB memory and 29.848705 seconds
2026-04-19 12:19:53.878 | (EngineCore pid=207) INFO 04-19 10:19:53 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-04-19 12:19:54.125 | (EngineCore pid=207) INFO 04-19 10:19:54 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-04-19 12:20:12.002 | (EngineCore pid=207) INFO 04-19 10:20:12 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/543f5bda7d/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 12:20:12.002 | (EngineCore pid=207) INFO 04-19 10:20:12 [backends.py:1137] Dynamo bytecode transform time: 7.10 s
2026-04-19 12:20:14.532 | (EngineCore pid=207) INFO 04-19 10:20:14 [backends.py:377] Cache the graph of compile range (1, 8192) for later use
2026-04-19 12:20:52.090 | (EngineCore pid=207) INFO 04-19 10:20:52 [backends.py:398] Compiling a graph for compile range (1, 8192) takes 39.79 s
2026-04-19 12:20:55.046 | (EngineCore pid=207) INFO 04-19 10:20:55 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/90479c81d75874980bb6e05db966c192b86a88710c97540108a196ed87edc6c7/rank_0_0/model
2026-04-19 12:20:55.046 | (EngineCore pid=207) INFO 04-19 10:20:55 [monitor.py:48] torch.compile took 50.32 s in total
2026-04-19 12:21:45.867 | (EngineCore pid=207) INFO 04-19 10:21:45 [monitor.py:76] Initial profiling/warmup run took 50.92 s
2026-04-19 12:21:51.936 | (EngineCore pid=207) INFO 04-19 10:21:51 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=64
2026-04-19 12:21:51.943 | (EngineCore pid=207) INFO 04-19 10:21:51 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=11 (largest=64), FULL=7 (largest=32)
2026-04-19 12:21:55.199 | (EngineCore pid=207) INFO 04-19 10:21:55 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 1.21 GiB total
2026-04-19 12:21:55.609 | (EngineCore pid=207) INFO 04-19 10:21:55 [gpu_worker.py:436] Available KV cache memory: -0.12 GiB
2026-04-19 12:21:55.609 | (EngineCore pid=207) INFO 04-19 10:21:55 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.8000 to 0.8379 to maintain the same effective KV cache size.
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132] EngineCore failed to start.
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132] Traceback (most recent call last):
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     super().__init__(
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     kv_cache_configs = get_kv_cache_configs(
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     _check_enough_kv_cache_memory(
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 626, in _check_enough_kv_cache_memory
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132]     raise ValueError(
2026-04-19 12:21:55.611 | (EngineCore pid=207) ERROR 04-19 10:21:55 [core.py:1132] ValueError: No available memory for the cache blocks. Try increasing `gpu_memory_utilization` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 12:21:55.611 | (EngineCore pid=207) Process EngineCore:
2026-04-19 12:21:55.611 | (EngineCore pid=207) Traceback (most recent call last):
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 12:21:55.611 | (EngineCore pid=207)     self.run()
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 12:21:55.611 | (EngineCore pid=207)     self._target(*self._args, **self._kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 12:21:55.611 | (EngineCore pid=207)     raise e
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:21:55.611 | (EngineCore pid=207)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:55.611 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:21:55.611 | (EngineCore pid=207)     super().__init__(
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:21:55.611 | (EngineCore pid=207)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:21:55.611 | (EngineCore pid=207)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:55.611 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:21:55.611 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 12:21:55.611 | (EngineCore pid=207)     kv_cache_configs = get_kv_cache_configs(
2026-04-19 12:21:55.611 | (EngineCore pid=207)                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 12:21:55.611 | (EngineCore pid=207)     _check_enough_kv_cache_memory(
2026-04-19 12:21:55.611 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 626, in _check_enough_kv_cache_memory
2026-04-19 12:21:55.611 | (EngineCore pid=207)     raise ValueError(
2026-04-19 12:21:55.611 | (EngineCore pid=207) ValueError: No available memory for the cache blocks. Try increasing `gpu_memory_utilization` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 12:21:56.584 | [rank0]:[W419 10:21:56.406615179 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 12:21:58.280 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:21:58.281 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:21:58.281 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:21:58.281 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:21:58.281 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:21:58.281 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:21:58.281 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:21:58.281 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:21:58.281 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:21:58.281 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:21:58.281 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:21:58.281 | (APIServer pid=1)     return await main
2026-04-19 12:21:58.281 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:21:58.281 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 12:21:58.282 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 12:21:58.282 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:21:58.282 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:21:58.282 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:21:58.282 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:21:58.282 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:21:58.282 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:21:58.282 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:21:58.282 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 12:21:58.282 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 12:21:58.282 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 12:21:58.282 | (APIServer pid=1)     return cls(
2026-04-19 12:21:58.282 | (APIServer pid=1)            ^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 12:21:58.282 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 12:21:58.282 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:58.282 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:21:58.282 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.282 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 12:21:58.283 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 12:21:58.283 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:21:58.283 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:21:58.283 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 12:21:58.283 | (APIServer pid=1)     super().__init__(
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 12:21:58.283 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 12:21:58.283 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 12:21:58.283 | (APIServer pid=1)     next(self.gen)
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 12:21:58.283 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 12:21:58.283 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 12:21:58.283 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 12:21:58.283 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}