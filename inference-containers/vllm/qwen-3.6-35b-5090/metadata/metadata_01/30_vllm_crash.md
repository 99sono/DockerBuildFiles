# docker compose for experiment
```yaml
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
      - "16384" # Try to find the sweet spot for the KV cache
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

```

# vllm crash

2026-04-19 12:09:18.192 | WARNING 04-19 10:09:18 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299] 
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:09:18.295 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:299] 
2026-04-19 12:09:18.298 | (APIServer pid=1) INFO 04-19 10:09:18 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 16384, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 12:09:19.067 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:09:28.686 | (APIServer pid=1) INFO 04-19 10:09:28 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 12:09:28.687 | (APIServer pid=1) INFO 04-19 10:09:28 [model.py:1685] Using max model len 16384
2026-04-19 12:09:28.973 | (APIServer pid=1) INFO 04-19 10:09:28 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 12:09:28.974 | (APIServer pid=1) INFO 04-19 10:09:28 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 12:09:28.974 | (APIServer pid=1) WARNING 04-19 10:09:28 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 12:09:28.974 | (APIServer pid=1) INFO 04-19 10:09:28 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 12:09:28.974 | (APIServer pid=1) INFO 04-19 10:09:28 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:09:28.974 | (APIServer pid=1) INFO 04-19 10:09:28 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:09:31.717 | (APIServer pid=1) INFO 04-19 10:09:31 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 12:09:31.890 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:09:40.295 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:09:51.205 | (EngineCore pid=207) INFO 04-19 10:09:51 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=16384, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
2026-04-19 12:09:51.398 | (EngineCore pid=207) WARNING 04-19 10:09:51 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:09:51.510 | (EngineCore pid=207) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 12:09:51.932 | (EngineCore pid=207) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:09:54.576 | (EngineCore pid=207) INFO 04-19 10:09:54 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:47857 backend=nccl
2026-04-19 12:09:54.862 | (EngineCore pid=207) INFO 04-19 10:09:54 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 12:10:01.271 | (EngineCore pid=207) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 12:10:06.530 | (EngineCore pid=207) INFO 04-19 10:10:06 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 12:10:06.859 | (EngineCore pid=207) INFO 04-19 10:10:06 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 12:10:06.860 | (EngineCore pid=207) INFO 04-19 10:10:06 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 12:10:06.910 | (EngineCore pid=207) INFO 04-19 10:10:06 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 12:10:06.910 | (EngineCore pid=207) INFO 04-19 10:10:06 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 12:10:07.268 | (EngineCore pid=207) INFO 04-19 10:10:07 [nvfp4.py:203] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 12:10:07.328 | (EngineCore pid=207) INFO 04-19 10:10:07 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-04-19 12:10:07.775 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 12:10:07.775 | (EngineCore pid=207) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 12:10:08.653 | (EngineCore pid=207) INFO 04-19 10:10:08 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.93 GiB.
2026-04-19 12:10:08.653 | (EngineCore pid=207) INFO 04-19 10:10:08 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 12:10:08.654 | (EngineCore pid=207) 
2026-04-19 12:10:08.654 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-04-19 12:10:32.773 | (EngineCore pid=207) 
2026-04-19 12:10:32.773 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:24<00:48, 24.12s/it]
2026-04-19 12:10:36.285 | (EngineCore pid=207) 
2026-04-19 12:10:36.285 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  7.55s/it]
2026-04-19 12:10:36.285 | (EngineCore pid=207) 
2026-04-19 12:10:36.285 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:27<00:00,  9.21s/it]
2026-04-19 12:10:36.285 | (EngineCore pid=207) 
2026-04-19 12:10:36.416 | (EngineCore pid=207) INFO 04-19 10:10:36 [default_loader.py:384] Loading weights took 27.86 seconds
2026-04-19 12:10:36.556 | (EngineCore pid=207) INFO 04-19 10:10:36 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 12:10:37.167 | (EngineCore pid=207) INFO 04-19 10:10:37 [gpu_model_runner.py:4837] Model loading took 21.88 GiB memory and 29.988480 seconds
2026-04-19 12:10:37.167 | (EngineCore pid=207) INFO 04-19 10:10:37 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-04-19 12:10:37.398 | (EngineCore pid=207) INFO 04-19 10:10:37 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
2026-04-19 12:10:54.464 | (EngineCore pid=207) INFO 04-19 10:10:54 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/3f3eb39433/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 12:10:54.464 | (EngineCore pid=207) INFO 04-19 10:10:54 [backends.py:1137] Dynamo bytecode transform time: 6.61 s
2026-04-19 12:10:56.886 | (EngineCore pid=207) INFO 04-19 10:10:56 [backends.py:377] Cache the graph of compile range (1, 32768) for later use
2026-04-19 12:11:35.790 | (EngineCore pid=207) INFO 04-19 10:11:35 [backends.py:398] Compiling a graph for compile range (1, 32768) takes 40.99 s
2026-04-19 12:11:38.734 | (EngineCore pid=207) INFO 04-19 10:11:38 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/780698177cd587a01bfdec0a0ee3e19a16465a0e79b2082646cd73444d0e7513/rank_0_0/model
2026-04-19 12:11:38.734 | (EngineCore pid=207) INFO 04-19 10:11:38 [monitor.py:48] torch.compile took 50.98 s in total
2026-04-19 12:12:30.234 | (EngineCore pid=207) INFO 04-19 10:12:30 [monitor.py:76] Initial profiling/warmup run took 51.69 s
2026-04-19 12:12:36.670 | (EngineCore pid=207) INFO 04-19 10:12:36 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=512
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] EngineCore failed to start.
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] Traceback (most recent call last):
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     super().__init__(
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 249, in _initialize_kv_caches
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     available_gpu_memory = self.model_executor.determine_available_memory()
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 147, in determine_available_memory
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return self.collective_rpc("determine_available_memory")
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     result = run_method(self.driver_worker, method, args, kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) Process EngineCore:
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 381, in determine_available_memory
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     cudagraph_memory_estimate = self.model_runner.profile_cudagraph_memory()
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5904, in profile_cudagraph_memory
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     self._init_minimal_kv_cache_for_profiling()
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5848, in _init_minimal_kv_cache_for_profiling
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     self.initialize_kv_cache(minimal_config, is_profiling=True)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6773, in initialize_kv_cache
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     kv_caches = self.initialize_kv_cache_tensors(
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6687, in initialize_kv_cache_tensors
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     kv_cache_raw_tensors = self._allocate_kv_cache_tensors(kv_cache_config)
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6491, in _allocate_kv_cache_tensors
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]     tensor = torch.zeros(
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132]              ^^^^^^^^^^^^
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] torch.AcceleratorError: CUDA error: out of memory
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] Search for `cudaErrorMemoryAllocation' in https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html for more information.
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] For debugging consider passing CUDA_LAUNCH_BLOCKING=1
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] Compile with `TORCH_USE_CUDA_DSA` to enable device-side assertions.
2026-04-19 12:12:38.268 | (EngineCore pid=207) ERROR 04-19 10:12:38 [core.py:1132] 
2026-04-19 12:12:38.268 | (EngineCore pid=207) Traceback (most recent call last):
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 12:12:38.269 | (EngineCore pid=207)     self.run()
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 12:12:38.269 | (EngineCore pid=207)     self._target(*self._args, **self._kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 12:12:38.269 | (EngineCore pid=207)     raise e
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:12:38.269 | (EngineCore pid=207)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:12:38.269 | (EngineCore pid=207)     super().__init__(
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 126, in __init__
2026-04-19 12:12:38.269 | (EngineCore pid=207)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-04-19 12:12:38.269 | (EngineCore pid=207)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 249, in _initialize_kv_caches
2026-04-19 12:12:38.269 | (EngineCore pid=207)     available_gpu_memory = self.model_executor.determine_available_memory()
2026-04-19 12:12:38.269 | (EngineCore pid=207)                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 147, in determine_available_memory
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return self.collective_rpc("determine_available_memory")
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-04-19 12:12:38.269 | (EngineCore pid=207)     result = run_method(self.driver_worker, method, args, kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 381, in determine_available_memory
2026-04-19 12:12:38.269 | (EngineCore pid=207)     cudagraph_memory_estimate = self.model_runner.profile_cudagraph_memory()
2026-04-19 12:12:38.269 | (EngineCore pid=207)                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-04-19 12:12:38.269 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 12:12:38.269 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5904, in profile_cudagraph_memory
2026-04-19 12:12:38.269 | (EngineCore pid=207)     self._init_minimal_kv_cache_for_profiling()
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5848, in _init_minimal_kv_cache_for_profiling
2026-04-19 12:12:38.269 | (EngineCore pid=207)     self.initialize_kv_cache(minimal_config, is_profiling=True)
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6773, in initialize_kv_cache
2026-04-19 12:12:38.269 | (EngineCore pid=207)     kv_caches = self.initialize_kv_cache_tensors(
2026-04-19 12:12:38.269 | (EngineCore pid=207)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6687, in initialize_kv_cache_tensors
2026-04-19 12:12:38.269 | (EngineCore pid=207)     kv_cache_raw_tensors = self._allocate_kv_cache_tensors(kv_cache_config)
2026-04-19 12:12:38.269 | (EngineCore pid=207)                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 6491, in _allocate_kv_cache_tensors
2026-04-19 12:12:38.269 | (EngineCore pid=207)     tensor = torch.zeros(
2026-04-19 12:12:38.269 | (EngineCore pid=207)              ^^^^^^^^^^^^
2026-04-19 12:12:38.269 | (EngineCore pid=207) torch.AcceleratorError: CUDA error: out of memory
2026-04-19 12:12:38.269 | (EngineCore pid=207) Search for `cudaErrorMemoryAllocation' in https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html for more information.
2026-04-19 12:12:38.269 | (EngineCore pid=207) CUDA kernel errors might be asynchronously reported at some other API call, so the stacktrace below might be incorrect.
2026-04-19 12:12:38.269 | (EngineCore pid=207) For debugging consider passing CUDA_LAUNCH_BLOCKING=1
2026-04-19 12:12:38.269 | (EngineCore pid=207) Compile with `TORCH_USE_CUDA_DSA` to enable device-side assertions.
2026-04-19 12:12:38.269 | (EngineCore pid=207) 
2026-04-19 12:12:38.269 | [rank0]:[W419 10:12:38.312560734 CUDAGuardImpl.h:126] Warning: CUDA warning: out of memory (function destroyEvent)
2026-04-19 12:12:39.259 | [rank0]:[W419 10:12:39.301857711 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 12:12:41.050 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:12:41.050 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:12:41.050 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:12:41.050 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:12:41.050 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:12:41.050 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:12:41.050 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:12:41.050 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:12:41.050 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:12:41.050 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:12:41.050 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:12:41.050 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:12:41.051 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:12:41.051 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:12:41.051 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:12:41.051 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:12:41.051 | (APIServer pid=1)     return await main
2026-04-19 12:12:41.051 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 12:12:41.051 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 12:12:41.051 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:12:41.051 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.051 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:12:41.052 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:12:41.052 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:12:41.052 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:12:41.052 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 12:12:41.052 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 12:12:41.052 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 12:12:41.052 | (APIServer pid=1)     return cls(
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 12:12:41.052 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 12:12:41.052 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:41.052 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 12:12:41.052 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:12:41.052 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:12:41.052 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.052 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 12:12:41.053 | (APIServer pid=1)     super().__init__(
2026-04-19 12:12:41.053 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 12:12:41.053 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 12:12:41.053 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:41.053 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 12:12:41.053 | (APIServer pid=1)     next(self.gen)
2026-04-19 12:12:41.053 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 12:12:41.053 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 12:12:41.053 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 12:12:41.053 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 12:12:41.053 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 12:12:49.103 | WARNING 04-19 10:12:49 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299] 
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:12:49.151 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:299] 
2026-04-19 12:12:49.154 | (APIServer pid=1) INFO 04-19 10:12:49 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 16384, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 12:12:49.314 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:12:50.194 | (APIServer pid=1) INFO 04-19 10:12:50 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 12:12:50.194 | (APIServer pid=1) INFO 04-19 10:12:50 [model.py:1685] Using max model len 16384
2026-04-19 12:12:51.171 | (APIServer pid=1) INFO 04-19 10:12:51 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 12:12:51.172 | (APIServer pid=1) INFO 04-19 10:12:51 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 12:12:51.173 | (APIServer pid=1) WARNING 04-19 10:12:51 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 12:12:51.173 | (APIServer pid=1) INFO 04-19 10:12:51 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 12:12:51.173 | (APIServer pid=1) INFO 04-19 10:12:51 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:12:51.174 | (APIServer pid=1) INFO 04-19 10:12:51 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:12:52.960 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:12:52.961 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:12:52.961 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:12:52.961 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:12:52.961 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:12:52.961 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:12:52.961 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:12:52.961 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:12:52.961 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:12:52.961 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:12:52.961 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1512, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1505, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1379, in uvloop.loop.Loop.run_forever
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/loop.pyx", line 557, in uvloop.loop.Loop._run
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/loop.pyx", line 476, in uvloop.loop.Loop._on_idle
2026-04-19 12:12:52.961 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 83, in uvloop.loop.Handle._run
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 61, in uvloop.loop.Handle._run
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:12:52.962 | (APIServer pid=1)     return await main
2026-04-19 12:12:52.962 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 12:12:52.962 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 12:12:52.962 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:12:52.962 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:12:52.962 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:12:52.962 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:12:52.962 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:12:52.962 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:12:52.962 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:12:52.962 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 124, in build_async_engine_client_from_engine_args
2026-04-19 12:12:52.962 | (APIServer pid=1)     vllm_config = engine_args.create_engine_config(usage_context=usage_context)
2026-04-19 12:12:52.962 | (APIServer pid=1)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.962 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/engine/arg_utils.py", line 2094, in create_engine_config
2026-04-19 12:12:52.963 | (APIServer pid=1)     config = VllmConfig(
2026-04-19 12:12:52.963 | (APIServer pid=1)              ^^^^^^^^^^^
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/pydantic/_internal/_dataclasses.py", line 121, in __init__
2026-04-19 12:12:52.963 | (APIServer pid=1)     s.__pydantic_validator__.validate_python(ArgsKwargs(args, kwargs), self_instance=s)
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/vllm.py", line 1247, in __post_init__
2026-04-19 12:12:52.963 | (APIServer pid=1)     self.reasoning_config.initialize_token_ids(self.model_config)
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/reasoning.py", line 71, in initialize_token_ids
2026-04-19 12:12:52.963 | (APIServer pid=1)     tokenizer = cached_tokenizer_from_config(model_config=model_config)
2026-04-19 12:12:52.963 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/registry.py", line 260, in cached_tokenizer_from_config
2026-04-19 12:12:52.963 | (APIServer pid=1)     return cached_get_tokenizer(
2026-04-19 12:12:52.963 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/registry.py", line 243, in get_tokenizer
2026-04-19 12:12:52.963 | (APIServer pid=1)     tokenizer = tokenizer_cls_.from_pretrained(tokenizer_name, *args, **kwargs)
2026-04-19 12:12:52.963 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.963 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/hf.py", line 85, in from_pretrained
2026-04-19 12:12:52.964 | (APIServer pid=1)     tokenizer = AutoTokenizer.from_pretrained(
2026-04-19 12:12:52.964 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.964 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/models/auto/tokenization_auto.py", line 719, in from_pretrained
2026-04-19 12:12:52.964 | (APIServer pid=1)     return TokenizersBackend.from_pretrained(pretrained_model_name_or_path, *inputs, **kwargs)
2026-04-19 12:12:52.964 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.964 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py", line 1729, in from_pretrained
2026-04-19 12:12:52.964 | (APIServer pid=1)     return cls._from_pretrained(
2026-04-19 12:12:52.964 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.964 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py", line 1915, in _from_pretrained
2026-04-19 12:12:52.964 | (APIServer pid=1)     init_kwargs = cls.convert_to_native_format(**init_kwargs)
2026-04-19 12:12:52.964 | (APIServer pid=1)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.964 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_tokenizers.py", line 116, in convert_to_native_format
2026-04-19 12:12:52.964 | (APIServer pid=1)     local_kwargs["tokenizer_object"] = TokenizerFast.from_file(fast_tokenizer_file)
2026-04-19 12:12:52.964 | (APIServer pid=1)                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:12:52.964 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 564, in signal_handler
2026-04-19 12:12:52.964 | (APIServer pid=1)     raise KeyboardInterrupt("terminated")
2026-04-19 12:12:52.964 | (APIServer pid=1) KeyboardInterrupt: terminated