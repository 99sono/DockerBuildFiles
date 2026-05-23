2026-04-19 11:19:42.429 | WARNING 04-19 09:19:42 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299] 
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 11:19:42.515 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:299] 
2026-04-19 11:19:42.518 | (APIServer pid=1) INFO 04-19 09:19:42 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 11:19:43.419 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:19:53.024 | (APIServer pid=1) INFO 04-19 09:19:53 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 11:19:53.024 | (APIServer pid=1) INFO 04-19 09:19:53 [model.py:1685] Using max model len 98304
2026-04-19 11:19:53.299 | (APIServer pid=1) INFO 04-19 09:19:53 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 11:19:53.300 | (APIServer pid=1) INFO 04-19 09:19:53 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 11:19:53.300 | (APIServer pid=1) WARNING 04-19 09:19:53 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 11:19:53.300 | (APIServer pid=1) INFO 04-19 09:19:53 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 11:19:53.300 | (APIServer pid=1) INFO 04-19 09:19:53 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 11:19:53.301 | (APIServer pid=1) INFO 04-19 09:19:53 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 11:19:56.087 | (APIServer pid=1) INFO 04-19 09:19:56 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 11:19:56.245 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:20:04.226 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:20:15.035 | (EngineCore pid=207) INFO 04-19 09:20:15 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-04-19 11:20:15.227 | (EngineCore pid=207) WARNING 04-19 09:20:15 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:20:15.341 | (EngineCore pid=207) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:20:15.639 | (EngineCore pid=207) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:20:18.539 | (EngineCore pid=207) INFO 04-19 09:20:18 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:40221 backend=nccl
2026-04-19 11:20:18.834 | (EngineCore pid=207) INFO 04-19 09:20:18 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 11:20:25.380 | (EngineCore pid=207) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:20:31.051 | (EngineCore pid=207) INFO 04-19 09:20:31 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 11:20:31.429 | (EngineCore pid=207) INFO 04-19 09:20:31 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 11:20:31.430 | (EngineCore pid=207) INFO 04-19 09:20:31 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 11:20:31.495 | (EngineCore pid=207) INFO 04-19 09:20:31 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 11:20:31.496 | (EngineCore pid=207) INFO 04-19 09:20:31 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 11:20:31.905 | (EngineCore pid=207) INFO 04-19 09:20:31 [nvfp4.py:203] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 11:20:31.970 | (EngineCore pid=207) INFO 04-19 09:20:31 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-04-19 11:20:32.425 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 11:20:32.425 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 11:20:33.151 | (EngineCore pid=207) INFO 04-19 09:20:33 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.91 GiB.
2026-04-19 11:20:33.151 | (EngineCore pid=207) INFO 04-19 09:20:33 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 11:20:33.151 | (EngineCore pid=207) 
2026-04-19 11:20:33.151 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-04-19 11:20:57.266 | (EngineCore pid=207) 
2026-04-19 11:20:57.266 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:24<00:48, 24.11s/it]
2026-04-19 11:21:00.882 | (EngineCore pid=207) 
2026-04-19 11:21:00.882 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  7.59s/it]
2026-04-19 11:21:00.882 | (EngineCore pid=207) 
2026-04-19 11:21:00.882 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  9.24s/it]
2026-04-19 11:21:00.882 | (EngineCore pid=207) 
2026-04-19 11:21:01.015 | (EngineCore pid=207) INFO 04-19 09:21:01 [default_loader.py:384] Loading weights took 27.86 seconds
2026-04-19 11:21:01.189 | (EngineCore pid=207) INFO 04-19 09:21:01 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 11:21:01.819 | (EngineCore pid=207) INFO 04-19 09:21:01 [gpu_model_runner.py:4837] Model loading took 21.88 GiB memory and 30.098010 seconds
2026-04-19 11:21:01.820 | (EngineCore pid=207) INFO 04-19 09:21:01 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-04-19 11:21:02.063 | (EngineCore pid=207) INFO 04-19 09:21:02 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
2026-04-19 11:21:19.529 | (EngineCore pid=207) INFO 04-19 09:21:19 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/5f91085db7/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 11:21:19.530 | (EngineCore pid=207) INFO 04-19 09:21:19 [backends.py:1137] Dynamo bytecode transform time: 6.81 s
2026-04-19 11:21:21.975 | (EngineCore pid=207) INFO 04-19 09:21:21 [backends.py:377] Cache the graph of compile range (1, 32768) for later use
2026-04-19 11:22:00.027 | (EngineCore pid=207) INFO 04-19 09:22:00 [backends.py:398] Compiling a graph for compile range (1, 32768) takes 40.19 s
2026-04-19 11:22:02.849 | (EngineCore pid=207) INFO 04-19 09:22:02 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/74f933275bddfbedbd2c21cf3c126e6ac3def9acd6f10b37199651a6e037f2b0/rank_0_0/model
2026-04-19 11:22:02.849 | (EngineCore pid=207) INFO 04-19 09:22:02 [monitor.py:48] torch.compile took 50.42 s in total
2026-04-19 11:22:54.921 | (EngineCore pid=207) INFO 04-19 09:22:54 [monitor.py:76] Initial profiling/warmup run took 52.22 s
2026-04-19 11:23:01.201 | (EngineCore pid=207) INFO 04-19 09:23:01 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=512
2026-04-19 11:23:02.797 | (EngineCore pid=207) INFO 04-19 09:23:02 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=51 (largest=512), FULL=35 (largest=256)
2026-04-19 11:23:07.949 | (EngineCore pid=207) INFO 04-19 09:23:07 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.08 GiB total
2026-04-19 11:23:08.488 | (EngineCore pid=207) INFO 04-19 09:23:08 [gpu_worker.py:436] Available KV cache memory: 0.47 GiB
2026-04-19 11:23:08.488 | (EngineCore pid=207) INFO 04-19 09:23:08 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.9000 to 0.9026 to maintain the same effective KV cache size.
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132] EngineCore failed to start.
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132] Traceback (most recent call last):
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     super().__init__(
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     kv_cache_configs = get_kv_cache_configs(
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     _check_enough_kv_cache_memory(
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 644, in _check_enough_kv_cache_memory
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132]     raise ValueError(
2026-04-19 11:23:08.490 | (EngineCore pid=207) ERROR 04-19 09:23:08 [core.py:1132] ValueError: To serve at least one request with the models's max seq len (98304), (1.06 GiB KV cache is needed, which is larger than the available KV cache memory (0.47 GiB). Based on the available memory, the estimated maximum model length is 35632. Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 11:23:08.490 | (EngineCore pid=207) Process EngineCore:
2026-04-19 11:23:08.490 | (EngineCore pid=207) Traceback (most recent call last):
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 11:23:08.491 | (EngineCore pid=207)     self.run()
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 11:23:08.491 | (EngineCore pid=207)     self._target(*self._args, **self._kwargs)
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 11:23:08.491 | (EngineCore pid=207)     raise e
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:23:08.491 | (EngineCore pid=207)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:23:08.491 | (EngineCore pid=207)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:08.491 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:23:08.491 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:23:08.491 | (EngineCore pid=207)     super().__init__(
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 11:23:08.491 | (EngineCore pid=207)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 11:23:08.491 | (EngineCore pid=207)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:08.491 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:23:08.491 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 11:23:08.491 | (EngineCore pid=207)     kv_cache_configs = get_kv_cache_configs(
2026-04-19 11:23:08.491 | (EngineCore pid=207)                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 11:23:08.491 | (EngineCore pid=207)     _check_enough_kv_cache_memory(
2026-04-19 11:23:08.491 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 644, in _check_enough_kv_cache_memory
2026-04-19 11:23:08.491 | (EngineCore pid=207)     raise ValueError(
2026-04-19 11:23:08.491 | (EngineCore pid=207) ValueError: To serve at least one request with the models's max seq len (98304), (1.06 GiB KV cache is needed, which is larger than the available KV cache memory (0.47 GiB). Based on the available memory, the estimated maximum model length is 35632. Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 11:23:09.544 | [rank0]:[W419 09:23:09.554008478 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 11:23:11.355 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 11:23:11.356 | (APIServer pid=1)     sys.exit(main())
2026-04-19 11:23:11.356 | (APIServer pid=1)              ^^^^^^
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 11:23:11.356 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 11:23:11.356 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 11:23:11.356 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 11:23:11.356 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 11:23:11.356 | (APIServer pid=1)     return runner.run(main)
2026-04-19 11:23:11.356 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 11:23:11.356 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 11:23:11.356 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 11:23:11.356 | (APIServer pid=1)     return await main
2026-04-19 11:23:11.356 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 11:23:11.356 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 11:23:11.357 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 11:23:11.357 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 11:23:11.357 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:23:11.357 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:23:11.357 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 11:23:11.357 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 11:23:11.357 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:23:11.357 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:23:11.357 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 11:23:11.357 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 11:23:11.357 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 11:23:11.357 | (APIServer pid=1)     return cls(
2026-04-19 11:23:11.357 | (APIServer pid=1)            ^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 11:23:11.357 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 11:23:11.357 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.357 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:11.358 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:23:11.358 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 11:23:11.358 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 11:23:11.358 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:23:11.358 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:23:11.358 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 11:23:11.358 | (APIServer pid=1)     super().__init__(
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 11:23:11.358 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 11:23:11.358 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 11:23:11.358 | (APIServer pid=1)     next(self.gen)
2026-04-19 11:23:11.358 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 11:23:11.359 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 11:23:11.359 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 11:23:11.359 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 11:23:11.359 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 11:23:19.530 | WARNING 04-19 09:23:19 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299] 
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 11:23:19.580 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:299] 
2026-04-19 11:23:19.582 | (APIServer pid=1) INFO 04-19 09:23:19 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 11:23:20.113 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:23:20.620 | (APIServer pid=1) INFO 04-19 09:23:20 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 11:23:20.620 | (APIServer pid=1) INFO 04-19 09:23:20 [model.py:1685] Using max model len 98304
2026-04-19 11:23:21.666 | (APIServer pid=1) INFO 04-19 09:23:21 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 11:23:21.667 | (APIServer pid=1) INFO 04-19 09:23:21 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 11:23:21.667 | (APIServer pid=1) WARNING 04-19 09:23:21 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 11:23:21.667 | (APIServer pid=1) INFO 04-19 09:23:21 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 11:23:21.668 | (APIServer pid=1) INFO 04-19 09:23:21 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 11:23:21.669 | (APIServer pid=1) INFO 04-19 09:23:21 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 11:23:24.562 | (APIServer pid=1) INFO 04-19 09:23:24 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 11:23:24.689 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:23:32.813 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:23:44.010 | (EngineCore pid=134) INFO 04-19 09:23:44 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-04-19 11:23:44.142 | (EngineCore pid=134) WARNING 04-19 09:23:44 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:23:44.280 | (EngineCore pid=134) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:23:44.589 | (EngineCore pid=134) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:23:47.659 | (EngineCore pid=134) INFO 04-19 09:23:47 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:46511 backend=nccl
2026-04-19 11:23:47.949 | (EngineCore pid=134) INFO 04-19 09:23:47 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 11:23:54.572 | (EngineCore pid=134) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:24:00.268 | (EngineCore pid=134) INFO 04-19 09:24:00 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 11:24:00.614 | (EngineCore pid=134) INFO 04-19 09:24:00 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 11:24:00.616 | (EngineCore pid=134) INFO 04-19 09:24:00 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 11:24:00.665 | (EngineCore pid=134) INFO 04-19 09:24:00 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 11:24:00.667 | (EngineCore pid=134) INFO 04-19 09:24:00 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 11:24:01.034 | (EngineCore pid=134) INFO 04-19 09:24:01 [nvfp4.py:203] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 11:24:01.081 | (EngineCore pid=134) INFO 04-19 09:24:01 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-04-19 11:24:01.535 | (EngineCore pid=134) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 11:24:01.535 | (EngineCore pid=134) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 11:24:02.287 | (EngineCore pid=134) INFO 04-19 09:24:02 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 57.04 GiB.
2026-04-19 11:24:02.287 | (EngineCore pid=134) INFO 04-19 09:24:02 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 11:24:02.287 | (EngineCore pid=134) 
2026-04-19 11:24:02.287 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-04-19 11:24:25.993 | (EngineCore pid=134) 
2026-04-19 11:24:25.993 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:23<00:47, 23.71s/it]
2026-04-19 11:24:27.171 | (EngineCore pid=134) 
2026-04-19 11:24:27.171 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:24<00:00,  6.58s/it]
2026-04-19 11:24:27.171 | (EngineCore pid=134) 
2026-04-19 11:24:27.171 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:24<00:00,  8.29s/it]
2026-04-19 11:24:27.171 | (EngineCore pid=134) 
2026-04-19 11:24:27.210 | (EngineCore pid=134) INFO 04-19 09:24:27 [default_loader.py:384] Loading weights took 24.92 seconds
2026-04-19 11:24:27.343 | (EngineCore pid=134) INFO 04-19 09:24:27 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 11:24:27.952 | (EngineCore pid=134) INFO 04-19 09:24:27 [gpu_model_runner.py:4837] Model loading took 21.88 GiB memory and 27.037188 seconds
2026-04-19 11:24:27.953 | (EngineCore pid=134) INFO 04-19 09:24:27 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-04-19 11:24:28.191 | (EngineCore pid=134) INFO 04-19 09:24:28 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
2026-04-19 11:24:31.425 | (EngineCore pid=134) INFO 04-19 09:24:31 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/5f91085db7/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 11:24:31.426 | (EngineCore pid=134) INFO 04-19 09:24:31 [backends.py:1137] Dynamo bytecode transform time: 1.63 s
2026-04-19 11:24:38.610 | (EngineCore pid=134) INFO 04-19 09:24:38 [backends.py:290] Directly load the compiled graph(s) for compile range (1, 32768) from the cache, took 6.630 s
2026-04-19 11:24:38.616 | (EngineCore pid=134) INFO 04-19 09:24:38 [decorators.py:305] Directly load AOT compilation from path /root/.cache/vllm/torch_compile_cache/torch_aot_compile/74f933275bddfbedbd2c21cf3c126e6ac3def9acd6f10b37199651a6e037f2b0/rank_0_0/model
2026-04-19 11:24:38.616 | (EngineCore pid=134) INFO 04-19 09:24:38 [monitor.py:48] torch.compile took 8.96 s in total
2026-04-19 11:25:27.814 | (EngineCore pid=134) INFO 04-19 09:25:27 [monitor.py:76] Initial profiling/warmup run took 49.34 s
2026-04-19 11:25:33.882 | (EngineCore pid=134) INFO 04-19 09:25:33 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=512
2026-04-19 11:25:35.566 | (EngineCore pid=134) INFO 04-19 09:25:35 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=51 (largest=512), FULL=35 (largest=256)
2026-04-19 11:25:39.968 | (EngineCore pid=134) INFO 04-19 09:25:39 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.08 GiB total
2026-04-19 11:25:40.400 | (EngineCore pid=134) INFO 04-19 09:25:40 [gpu_worker.py:436] Available KV cache memory: 0.61 GiB
2026-04-19 11:25:40.400 | (EngineCore pid=134) INFO 04-19 09:25:40 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.9000 to 0.9026 to maintain the same effective KV cache size.
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132] EngineCore failed to start.
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132] Traceback (most recent call last):
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:25:40.402 | (EngineCore pid=134) Process EngineCore:
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     super().__init__(
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     kv_cache_configs = get_kv_cache_configs(
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     _check_enough_kv_cache_memory(
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 644, in _check_enough_kv_cache_memory
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132]     raise ValueError(
2026-04-19 11:25:40.402 | (EngineCore pid=134) ERROR 04-19 09:25:40 [core.py:1132] ValueError: To serve at least one request with the models's max seq len (98304), (1.06 GiB KV cache is needed, which is larger than the available KV cache memory (0.61 GiB). Based on the available memory, the estimated maximum model length is 50304. Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 11:25:40.402 | (EngineCore pid=134) Traceback (most recent call last):
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 11:25:40.402 | (EngineCore pid=134)     self.run()
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 11:25:40.402 | (EngineCore pid=134)     self._target(*self._args, **self._kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 11:25:40.402 | (EngineCore pid=134)     raise e
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:25:40.402 | (EngineCore pid=134)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:40.402 | (EngineCore pid=134)     return func(*args, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:25:40.402 | (EngineCore pid=134)     super().__init__(
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 11:25:40.402 | (EngineCore pid=134)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 11:25:40.402 | (EngineCore pid=134)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:40.402 | (EngineCore pid=134)     return func(*args, **kwargs)
2026-04-19 11:25:40.402 | (EngineCore pid=134)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 260, in _initialize_kv_caches
2026-04-19 11:25:40.402 | (EngineCore pid=134)     kv_cache_configs = get_kv_cache_configs(
2026-04-19 11:25:40.402 | (EngineCore pid=134)                        ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1579, in get_kv_cache_configs
2026-04-19 11:25:40.402 | (EngineCore pid=134)     _check_enough_kv_cache_memory(
2026-04-19 11:25:40.402 | (EngineCore pid=134)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 644, in _check_enough_kv_cache_memory
2026-04-19 11:25:40.402 | (EngineCore pid=134)     raise ValueError(
2026-04-19 11:25:40.402 | (EngineCore pid=134) ValueError: To serve at least one request with the models's max seq len (98304), (1.06 GiB KV cache is needed, which is larger than the available KV cache memory (0.61 GiB). Based on the available memory, the estimated maximum model length is 50304. Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-04-19 11:25:41.203 | [rank0]:[W419 09:25:41.898324324 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 11:25:42.813 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 11:25:42.813 | (APIServer pid=1)     sys.exit(main())
2026-04-19 11:25:42.813 | (APIServer pid=1)              ^^^^^^
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 11:25:42.813 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 11:25:42.813 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 11:25:42.813 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 11:25:42.813 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 11:25:42.813 | (APIServer pid=1)     return runner.run(main)
2026-04-19 11:25:42.813 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.813 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 11:25:42.813 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 11:25:42.814 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 11:25:42.814 | (APIServer pid=1)     return await main
2026-04-19 11:25:42.814 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 11:25:42.814 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 11:25:42.814 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 11:25:42.814 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:25:42.814 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:25:42.814 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 11:25:42.814 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 11:25:42.814 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:25:42.814 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:25:42.814 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.814 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 11:25:42.815 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 11:25:42.815 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 11:25:42.815 | (APIServer pid=1)     return cls(
2026-04-19 11:25:42.815 | (APIServer pid=1)            ^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 11:25:42.815 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 11:25:42.815 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:42.815 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:25:42.815 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 11:25:42.815 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 11:25:42.815 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:25:42.815 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:25:42.815 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 11:25:42.815 | (APIServer pid=1)     super().__init__(
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 11:25:42.815 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 11:25:42.815 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 11:25:42.815 | (APIServer pid=1)     next(self.gen)
2026-04-19 11:25:42.815 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 11:25:42.816 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 11:25:42.816 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 11:25:42.816 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 11:25:42.816 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 11:25:51.114 | WARNING 04-19 09:25:51 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299] 
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 11:25:51.167 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:299] 
2026-04-19 11:25:51.170 | (APIServer pid=1) INFO 04-19 09:25:51 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 11:25:51.712 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:25:52.243 | (APIServer pid=1) INFO 04-19 09:25:52 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 11:25:52.244 | (APIServer pid=1) INFO 04-19 09:25:52 [model.py:1685] Using max model len 98304
2026-04-19 11:25:53.280 | (APIServer pid=1) INFO 04-19 09:25:53 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 11:25:53.281 | (APIServer pid=1) INFO 04-19 09:25:53 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 11:25:53.281 | (APIServer pid=1) WARNING 04-19 09:25:53 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 11:25:53.281 | (APIServer pid=1) INFO 04-19 09:25:53 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 11:25:53.281 | (APIServer pid=1) INFO 04-19 09:25:53 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 11:25:53.283 | (APIServer pid=1) INFO 04-19 09:25:53 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 11:25:53.324 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 11:25:53.324 | (APIServer pid=1)     sys.exit(main())
2026-04-19 11:25:53.324 | (APIServer pid=1)              ^^^^^^
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 11:25:53.324 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 11:25:53.324 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 11:25:53.324 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 11:25:53.324 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 11:25:53.324 | (APIServer pid=1)     return runner.run(main)
2026-04-19 11:25:53.324 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.324 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 11:25:53.324 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 11:25:53.325 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1512, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1505, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1379, in uvloop.loop.Loop.run_forever
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/loop.pyx", line 557, in uvloop.loop.Loop._run
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/loop.pyx", line 476, in uvloop.loop.Loop._on_idle
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 83, in uvloop.loop.Handle._run
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 61, in uvloop.loop.Handle._run
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 11:25:53.325 | (APIServer pid=1)     return await main
2026-04-19 11:25:53.325 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 11:25:53.325 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 11:25:53.325 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 11:25:53.326 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 11:25:53.326 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:25:53.326 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:25:53.326 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 11:25:53.326 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 11:25:53.326 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:25:53.326 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:25:53.326 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 124, in build_async_engine_client_from_engine_args
2026-04-19 11:25:53.326 | (APIServer pid=1)     vllm_config = engine_args.create_engine_config(usage_context=usage_context)
2026-04-19 11:25:53.326 | (APIServer pid=1)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/engine/arg_utils.py", line 2094, in create_engine_config
2026-04-19 11:25:53.326 | (APIServer pid=1)     config = VllmConfig(
2026-04-19 11:25:53.326 | (APIServer pid=1)              ^^^^^^^^^^^
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/pydantic/_internal/_dataclasses.py", line 121, in __init__
2026-04-19 11:25:53.326 | (APIServer pid=1)     s.__pydantic_validator__.validate_python(ArgsKwargs(args, kwargs), self_instance=s)
2026-04-19 11:25:53.326 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/vllm.py", line 1247, in __post_init__
2026-04-19 11:25:53.326 | (APIServer pid=1)     self.reasoning_config.initialize_token_ids(self.model_config)
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/reasoning.py", line 71, in initialize_token_ids
2026-04-19 11:25:53.327 | (APIServer pid=1)     tokenizer = cached_tokenizer_from_config(model_config=model_config)
2026-04-19 11:25:53.327 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/registry.py", line 260, in cached_tokenizer_from_config
2026-04-19 11:25:53.327 | (APIServer pid=1)     return cached_get_tokenizer(
2026-04-19 11:25:53.327 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/registry.py", line 221, in get_tokenizer
2026-04-19 11:25:53.327 | (APIServer pid=1)     config = get_config(
2026-04-19 11:25:53.327 | (APIServer pid=1)              ^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/config.py", line 693, in get_config
2026-04-19 11:25:53.327 | (APIServer pid=1)     config_dict, config = config_parser.parse(
2026-04-19 11:25:53.327 | (APIServer pid=1)                           ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/config.py", line 170, in parse
2026-04-19 11:25:53.327 | (APIServer pid=1)     config_dict, _ = PretrainedConfig.get_config_dict(
2026-04-19 11:25:53.327 | (APIServer pid=1)                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/configuration_utils.py", line 670, in get_config_dict
2026-04-19 11:25:53.327 | (APIServer pid=1)     config_dict, kwargs = cls._get_config_dict(pretrained_model_name_or_path, **kwargs)
2026-04-19 11:25:53.327 | (APIServer pid=1)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/configuration_utils.py", line 725, in _get_config_dict
2026-04-19 11:25:53.327 | (APIServer pid=1)     resolved_config_file = cached_file(
2026-04-19 11:25:53.327 | (APIServer pid=1)                            ^^^^^^^^^^^^
2026-04-19 11:25:53.327 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/utils/hub.py", line 278, in cached_file
2026-04-19 11:25:53.328 | (APIServer pid=1)     file = cached_files(path_or_repo_id=path_or_repo_id, filenames=[filename], **kwargs)
2026-04-19 11:25:53.328 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/utils/hub.py", line 422, in cached_files
2026-04-19 11:25:53.328 | (APIServer pid=1)     hf_hub_download(
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_validators.py", line 88, in _inner_fn
2026-04-19 11:25:53.328 | (APIServer pid=1)     return fn(*args, **kwargs)
2026-04-19 11:25:53.328 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 997, in hf_hub_download
2026-04-19 11:25:53.328 | (APIServer pid=1)     return _hf_hub_download_to_cache_dir(
2026-04-19 11:25:53.328 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1072, in _hf_hub_download_to_cache_dir
2026-04-19 11:25:53.328 | (APIServer pid=1)     (url_to_download, etag, commit_hash, expected_size, xet_file_data, head_call_error) = _get_metadata_or_catch_error(
2026-04-19 11:25:53.328 | (APIServer pid=1)                                                                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1669, in _get_metadata_or_catch_error
2026-04-19 11:25:53.328 | (APIServer pid=1)     metadata = get_hf_file_metadata(
2026-04-19 11:25:53.328 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.328 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_validators.py", line 88, in _inner_fn
2026-04-19 11:25:53.328 | (APIServer pid=1)     return fn(*args, **kwargs)
2026-04-19 11:25:53.329 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1591, in get_hf_file_metadata
2026-04-19 11:25:53.329 | (APIServer pid=1)     response = _httpx_follow_relative_redirects_with_backoff(
2026-04-19 11:25:53.329 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 685, in _httpx_follow_relative_redirects_with_backoff
2026-04-19 11:25:53.329 | (APIServer pid=1)     response = http_backoff(
2026-04-19 11:25:53.329 | (APIServer pid=1)                ^^^^^^^^^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 559, in http_backoff
2026-04-19 11:25:53.329 | (APIServer pid=1)     return next(
2026-04-19 11:25:53.329 | (APIServer pid=1)            ^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 467, in _http_backoff_base
2026-04-19 11:25:53.329 | (APIServer pid=1)     response = client.request(method=method, url=url, **kwargs)
2026-04-19 11:25:53.329 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 825, in request
2026-04-19 11:25:53.329 | (APIServer pid=1)     return self.send(request, auth=auth, follow_redirects=follow_redirects)
2026-04-19 11:25:53.329 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.329 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 914, in send
2026-04-19 11:25:53.330 | (APIServer pid=1)     response = self._send_handling_auth(
2026-04-19 11:25:53.330 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 942, in _send_handling_auth
2026-04-19 11:25:53.330 | (APIServer pid=1)     response = self._send_handling_redirects(
2026-04-19 11:25:53.330 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 979, in _send_handling_redirects
2026-04-19 11:25:53.330 | (APIServer pid=1)     response = self._send_single_request(request)
2026-04-19 11:25:53.330 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 1014, in _send_single_request
2026-04-19 11:25:53.330 | (APIServer pid=1)     response = transport.handle_request(request)
2026-04-19 11:25:53.330 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_transports/default.py", line 250, in handle_request
2026-04-19 11:25:53.330 | (APIServer pid=1)     resp = self._pool.handle_request(req)
2026-04-19 11:25:53.330 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection_pool.py", line 256, in handle_request
2026-04-19 11:25:53.330 | (APIServer pid=1)     raise exc from None
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection_pool.py", line 236, in handle_request
2026-04-19 11:25:53.330 | (APIServer pid=1)     response = connection.handle_request(
2026-04-19 11:25:53.330 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection.py", line 103, in handle_request
2026-04-19 11:25:53.330 | (APIServer pid=1)     return self._connection.handle_request(request)
2026-04-19 11:25:53.330 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.330 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 136, in handle_request
2026-04-19 11:25:53.331 | (APIServer pid=1)     raise exc
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 106, in handle_request
2026-04-19 11:25:53.331 | (APIServer pid=1)     ) = self._receive_response_headers(**kwargs)
2026-04-19 11:25:53.331 | (APIServer pid=1)         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 177, in _receive_response_headers
2026-04-19 11:25:53.331 | (APIServer pid=1)     event = self._receive_event(timeout=timeout)
2026-04-19 11:25:53.331 | (APIServer pid=1)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 217, in _receive_event
2026-04-19 11:25:53.331 | (APIServer pid=1)     data = self._network_stream.read(
2026-04-19 11:25:53.331 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_backends/sync.py", line 128, in read
2026-04-19 11:25:53.331 | (APIServer pid=1)     return self._sock.recv(max_bytes)
2026-04-19 11:25:53.331 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/lib/python3.12/ssl.py", line 1232, in recv
2026-04-19 11:25:53.331 | (APIServer pid=1)     return self.read(buflen)
2026-04-19 11:25:53.331 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/lib/python3.12/ssl.py", line 1105, in read
2026-04-19 11:25:53.331 | (APIServer pid=1)     return self._sslobj.read(len)
2026-04-19 11:25:53.331 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:25:53.331 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 564, in signal_handler
2026-04-19 11:25:53.331 | (APIServer pid=1)     raise KeyboardInterrupt("terminated")
2026-04-19 11:25:53.331 | (APIServer pid=1) KeyboardInterrupt: terminated