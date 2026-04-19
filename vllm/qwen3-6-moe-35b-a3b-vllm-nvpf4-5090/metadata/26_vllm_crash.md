# docker compose 32k 
services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    runtime: nvidia
    restart: unless-stopped
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
      - NVIDIA_VISIBLE_DEVICES=all
      - HF_HUB_ENABLE_HF_TRANSFER=1
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
    command:
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--tensor-parallel-size"
      - "1"
      - "--gpu-memory-utilization"
      - "0.80" # line in the sand the OS must continue working
      - "--max-model-len"
      - "32768" # Try to find the sweet spot for the KV cache
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "256"
      - "--max-num-batched-tokens"
      - "32768"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true


# vllm crash
2026-04-19 12:01:49.109 | WARNING 04-19 10:01:49 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299] 
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:01:49.206 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:299] 
2026-04-19 12:01:49.208 | (APIServer pid=1) INFO 04-19 10:01:49 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 32768, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 12:01:49.370 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:02:00.480 | (APIServer pid=1) INFO 04-19 10:02:00 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 12:02:00.481 | (APIServer pid=1) INFO 04-19 10:02:00 [model.py:1685] Using max model len 32768
2026-04-19 12:02:00.831 | (APIServer pid=1) INFO 04-19 10:02:00 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 12:02:00.831 | (APIServer pid=1) INFO 04-19 10:02:00 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 12:02:00.832 | (APIServer pid=1) WARNING 04-19 10:02:00 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 12:02:00.832 | (APIServer pid=1) INFO 04-19 10:02:00 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 12:02:00.832 | (APIServer pid=1) INFO 04-19 10:02:00 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:02:00.832 | (APIServer pid=1) INFO 04-19 10:02:00 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:02:03.592 | (APIServer pid=1) INFO 04-19 10:02:03 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 12:02:03.747 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:02:11.753 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:02:22.718 | (EngineCore pid=207) INFO 04-19 10:02:22 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=32768, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-04-19 12:02:22.922 | (EngineCore pid=207) WARNING 04-19 10:02:22 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:02:23.035 | (EngineCore pid=207) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:02:23.585 | (EngineCore pid=207) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:02:26.197 | (EngineCore pid=207) INFO 04-19 10:02:26 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:56613 backend=nccl
2026-04-19 12:02:26.513 | (EngineCore pid=207) INFO 04-19 10:02:26 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 12:02:32.998 | (EngineCore pid=207) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:02:38.316 | (EngineCore pid=207) INFO 04-19 10:02:38 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 12:02:38.705 | (EngineCore pid=207) INFO 04-19 10:02:38 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 12:02:38.706 | (EngineCore pid=207) INFO 04-19 10:02:38 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 12:02:38.758 | (EngineCore pid=207) INFO 04-19 10:02:38 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 12:02:38.760 | (EngineCore pid=207) INFO 04-19 10:02:38 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 12:02:39.435 | (EngineCore pid=207) INFO 04-19 10:02:39 [nvfp4.py:203] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 12:02:39.499 | (EngineCore pid=207) INFO 04-19 10:02:39 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-04-19 12:02:39.935 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 12:02:39.935 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 12:02:40.845 | (EngineCore pid=207) INFO 04-19 10:02:40 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.93 GiB.
2026-04-19 12:02:40.845 | (EngineCore pid=207) INFO 04-19 10:02:40 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 12:02:40.848 | (EngineCore pid=207) 
2026-04-19 12:02:40.848 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-04-19 12:03:23.313 | (EngineCore pid=207) 
2026-04-19 12:03:23.313 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:42<01:24, 42.46s/it]
2026-04-19 12:03:25.117 | (EngineCore pid=207) 
2026-04-19 12:03:25.117 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:44<00:00, 11.68s/it]
2026-04-19 12:03:25.117 | (EngineCore pid=207) 
2026-04-19 12:03:25.117 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:44<00:00, 14.76s/it]
2026-04-19 12:03:25.117 | (EngineCore pid=207) 
2026-04-19 12:03:25.155 | (EngineCore pid=207) INFO 04-19 10:03:25 [default_loader.py:384] Loading weights took 44.51 seconds
2026-04-19 12:03:25.375 | (EngineCore pid=207) INFO 04-19 10:03:25 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 12:03:26.168 | (EngineCore pid=207) INFO 04-19 10:03:26 [gpu_model_runner.py:4837] Model loading took 21.88 GiB memory and 47.308755 seconds
2026-04-19 12:03:26.169 | (EngineCore pid=207) INFO 04-19 10:03:26 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-04-19 12:03:26.397 | (EngineCore pid=207) INFO 04-19 10:03:26 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
2026-04-19 12:03:44.030 | (EngineCore pid=207) INFO 04-19 10:03:44 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/9d78dc16ba/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 12:03:44.030 | (EngineCore pid=207) INFO 04-19 10:03:44 [backends.py:1137] Dynamo bytecode transform time: 6.99 s
2026-04-19 12:03:46.545 | (EngineCore pid=207) INFO 04-19 10:03:46 [backends.py:377] Cache the graph of compile range (1, 32768) for later use
2026-04-19 12:04:24.244 | (EngineCore pid=207) INFO 04-19 10:04:24 [backends.py:398] Compiling a graph for compile range (1, 32768) takes 39.93 s
2026-04-19 12:04:27.262 | (EngineCore pid=207) INFO 04-19 10:04:27 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/33ac9f5fe8e332fdbfef1a4b6d45c3f5221d2c42e8031df39b0a694a783f15de/rank_0_0/model
2026-04-19 12:04:27.262 | (EngineCore pid=207) INFO 04-19 10:04:27 [monitor.py:48] torch.compile took 50.41 s in total
2026-04-19 12:05:20.085 | (EngineCore pid=207) INFO 04-19 10:05:20 [monitor.py:76] Initial profiling/warmup run took 52.92 s
2026-04-19 12:05:26.043 | (EngineCore pid=207) INFO 04-19 10:05:26 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=512
2026-04-19 12:05:26.331 | (EngineCore pid=207) INFO 04-19 10:05:26 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=51 (largest=512), FULL=35 (largest=256)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] EngineCore failed to start.
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] Traceback (most recent call last):
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) Process EngineCore:
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     super().__init__(
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 249, in _initialize_kv_caches
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     available_gpu_memory = self.model_executor.determine_available_memory()
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 147, in determine_available_memory
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return self.collective_rpc("determine_available_memory")
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     result = run_method(self.driver_worker, method, args, kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 381, in determine_available_memory
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     cudagraph_memory_estimate = self.model_runner.profile_cudagraph_memory()
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5933, in profile_cudagraph_memory
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     with self._freeze_gc(), graph_capture(device=self.device):
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/lib/python3.12/contextlib.py", line 137, in __enter__
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return next(self.gen)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/distributed/parallel_state.py", line 1299, in graph_capture
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     with get_tp_group().graph_capture(context), get_pp_group().graph_capture(context):
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/lib/python3.12/contextlib.py", line 137, in __enter__
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     return next(self.gen)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]            ^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/distributed/parallel_state.py", line 487, in graph_capture
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     stream.wait_stream(curr_stream)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 77, in wait_stream
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     self.wait_event(stream.record_event())
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]                     ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 91, in record_event
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     event.record(self)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 209, in record
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132]     super().record(stream)
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] torch.AcceleratorError: CUDA error: out of memory
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] Search for `cudaErrorMemoryAllocation' in https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html for more information.
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] For debugging consider passing CUDA_LAUNCH_BLOCKING=1
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] Compile with `TORCH_USE_CUDA_DSA` to enable device-side assertions.
2026-04-19 12:05:27.169 | (EngineCore pid=207) ERROR 04-19 10:05:27 [core.py:1132] 
2026-04-19 12:05:27.169 | (EngineCore pid=207) Traceback (most recent call last):
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 12:05:27.170 | (EngineCore pid=207)     self.run()
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 12:05:27.170 | (EngineCore pid=207)     self._target(*self._args, **self._kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 12:05:27.170 | (EngineCore pid=207)     raise e
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:05:27.170 | (EngineCore pid=207)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:05:27.170 | (EngineCore pid=207)     super().__init__(
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:05:27.170 | (EngineCore pid=207)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:05:27.170 | (EngineCore pid=207)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 249, in _initialize_kv_caches
2026-04-19 12:05:27.170 | (EngineCore pid=207)     available_gpu_memory = self.model_executor.determine_available_memory()
2026-04-19 12:05:27.170 | (EngineCore pid=207)                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 147, in determine_available_memory
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return self.collective_rpc("determine_available_memory")
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-04-19 12:05:27.170 | (EngineCore pid=207)     result = run_method(self.driver_worker, method, args, kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 381, in determine_available_memory
2026-04-19 12:05:27.170 | (EngineCore pid=207)     cudagraph_memory_estimate = self.model_runner.profile_cudagraph_memory()
2026-04-19 12:05:27.170 | (EngineCore pid=207)                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5933, in profile_cudagraph_memory
2026-04-19 12:05:27.170 | (EngineCore pid=207)     with self._freeze_gc(), graph_capture(device=self.device):
2026-04-19 12:05:27.170 | (EngineCore pid=207)                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/lib/python3.12/contextlib.py", line 137, in __enter__
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return next(self.gen)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/distributed/parallel_state.py", line 1299, in graph_capture
2026-04-19 12:05:27.170 | (EngineCore pid=207)     with get_tp_group().graph_capture(context), get_pp_group().graph_capture(context):
2026-04-19 12:05:27.170 | (EngineCore pid=207)          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/lib/python3.12/contextlib.py", line 137, in __enter__
2026-04-19 12:05:27.170 | (EngineCore pid=207)     return next(self.gen)
2026-04-19 12:05:27.170 | (EngineCore pid=207)            ^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/distributed/parallel_state.py", line 487, in graph_capture
2026-04-19 12:05:27.170 | (EngineCore pid=207)     stream.wait_stream(curr_stream)
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 77, in wait_stream
2026-04-19 12:05:27.170 | (EngineCore pid=207)     self.wait_event(stream.record_event())
2026-04-19 12:05:27.170 | (EngineCore pid=207)                     ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 91, in record_event
2026-04-19 12:05:27.170 | (EngineCore pid=207)     event.record(self)
2026-04-19 12:05:27.170 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/cuda/streams.py", line 209, in record
2026-04-19 12:05:27.170 | (EngineCore pid=207)     super().record(stream)
2026-04-19 12:05:27.170 | (EngineCore pid=207) torch.AcceleratorError: CUDA error: out of memory
2026-04-19 12:05:27.170 | (EngineCore pid=207) Search for `cudaErrorMemoryAllocation' in https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html for more information.
2026-04-19 12:05:27.170 | (EngineCore pid=207) CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
2026-04-19 12:05:27.170 | (EngineCore pid=207) For debugging consider passing CUDA_LAUNCH_BLOCKING=1
2026-04-19 12:05:27.170 | (EngineCore pid=207) Compile with `TORCH_USE_CUDA_DSA` to enable device-side assertions.
2026-04-19 12:05:27.170 | (EngineCore pid=207) 
2026-04-19 12:05:27.174 | [rank0]:[W419 10:05:27.841846807 CUDAGuardImpl.h:126] Warning: CUDA warning: out of memory (function destroyEvent)
2026-04-19 12:05:28.177 | [rank0]:[W419 10:05:28.844438421 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 12:05:30.068 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:05:30.068 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:05:30.068 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:05:30.068 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:05:30.068 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:05:30.068 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:05:30.068 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:05:30.068 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:05:30.068 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:05:30.068 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:05:30.068 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:05:30.068 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:05:30.071 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:05:30.071 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.071 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:05:30.071 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:05:30.071 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.071 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:05:30.072 | (APIServer pid=1)     return await main
2026-04-19 12:05:30.072 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 12:05:30.072 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 12:05:30.072 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:05:30.072 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:05:30.072 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:05:30.072 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:05:30.072 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:05:30.072 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:05:30.072 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:05:30.072 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 12:05:30.072 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 12:05:30.072 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 12:05:30.072 | (APIServer pid=1)     return cls(
2026-04-19 12:05:30.072 | (APIServer pid=1)            ^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 12:05:30.072 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 12:05:30.072 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.072 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:30.073 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:05:30.073 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 12:05:30.073 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 12:05:30.073 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:05:30.073 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:05:30.073 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 12:05:30.073 | (APIServer pid=1)     super().__init__(
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 12:05:30.073 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 12:05:30.073 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 12:05:30.073 | (APIServer pid=1)     next(self.gen)
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 12:05:30.073 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 12:05:30.073 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 12:05:30.073 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 12:05:30.073 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 12:05:38.116 | WARNING 04-19 10:05:38 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299] 
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:05:38.165 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:299] 
2026-04-19 12:05:38.168 | (APIServer pid=1) INFO 04-19 10:05:38 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 32768, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}