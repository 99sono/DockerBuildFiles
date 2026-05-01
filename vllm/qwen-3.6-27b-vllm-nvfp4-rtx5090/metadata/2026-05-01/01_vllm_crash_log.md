# docker compos

```yml
version: "3.9"

services:
  qwen-3-6-27b-nvfp4-mtp:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen-3-6-27b-nvfp4-mtp-stable
    hostname: qwen-3-6-27b-nvfp4-mtp
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
      # Required for Blackwell + WSL2 stability
      VLLM_WORKER_MULTIPROC_METHOD: spawn

      # Critical for very large KV-cache allocations
      PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True

      # Optional but useful for faster model pulls
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      # Model paths (pulled from global HF cache)
      # there is an NVFP4 version https://huggingface.co/sakamakismile/Qwen3.6-27B-NVFP4
      # https://huggingface.co/sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
      # 
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"

      # Required
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # Memory budget
      - "--gpu-memory-utilization"
      - "0.9"

      # ===== Long-context experiment =====
      - "--max-model-len"
      - "131072"

      # Batching (intentionally conservative for long windows)
      - "--max-num-seqs"
      - "2"
      - "--max-num-batched-tokens"
      - "16384"

      # KV cache
      - "--kv-cache-dtype"
      - "fp8"

      # Quantization
      - "--quantization"
      - "modelopt"

      # Long-context ergonomics
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # Reasoning + tools
      - "--reasoning-parser"
      - "qwen3"
      - "--language-model-only"

      # NVFP4 MoE backend (performance path)
      - "--moe-backend"
      - "cutlass"

      # Speculative Decoding
      - "--speculative-config"
      - '{"method":"qwen3_5_mtp","num_speculative_tokens":3}'

      # Optional ultra-stability fallback (DISABLED by default)
      # - "--moe-backend"
      # - "marlin"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# Vllm Log

2026-05-01 18:26:47.162 | WARNING 05-01 16:26:47 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 18:26:47.281 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299] 
2026-05-01 18:26:47.281 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 18:26:47.281 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 18:26:47.282 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299]   █▄█▀ █     █     █     █  model   sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
2026-05-01 18:26:47.282 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 18:26:47.282 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:299] 
2026-05-01 18:26:47.285 | (APIServer pid=1) INFO 05-01 16:26:47 [utils.py:233] non-default args: {'model_tag': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'host': '0.0.0.0', 'model': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'trust_remote_code': True, 'max_model_len': 131072, 'quantization': 'modelopt', 'served_model_name': ['qwen3.6-27b-text-nvfp4-mtp'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.9, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'language_model_only': True, 'max_num_batched_tokens': 16384, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass', 'speculative_config': {'method': 'qwen3_5_mtp', 'num_speculative_tokens': 3}}
2026-05-01 18:26:47.884 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 18:26:59.040 | (APIServer pid=1) INFO 05-01 16:26:59 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 18:26:59.073 | (APIServer pid=1) INFO 05-01 16:26:59 [nixl_utils.py:32] NIXL is available
2026-05-01 18:26:59.288 | (APIServer pid=1) INFO 05-01 16:26:59 [model.py:555] Resolved architecture: Qwen3_5ForConditionalGeneration
2026-05-01 18:26:59.288 | (APIServer pid=1) INFO 05-01 16:26:59 [model.py:1680] Using max model len 131072
2026-05-01 18:26:59.783 | (APIServer pid=1) INFO 05-01 16:26:59 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 18:26:59.783 | (APIServer pid=1) WARNING 05-01 16:26:59 [speculative.py:456] method `qwen3_5_mtp` is deprecated and replaced with mtp.
2026-05-01 18:27:06.747 | (APIServer pid=1) INFO 05-01 16:27:06 [model.py:555] Resolved architecture: Qwen3_5MTP
2026-05-01 18:27:06.747 | (APIServer pid=1) INFO 05-01 16:27:06 [model.py:1680] Using max model len 262144
2026-05-01 18:27:06.747 | (APIServer pid=1) WARNING 05-01 16:27:06 [speculative.py:602] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
2026-05-01 18:27:06.747 | (APIServer pid=1) INFO 05-01 16:27:06 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=16384.
2026-05-01 18:27:06.748 | (APIServer pid=1) WARNING 05-01 16:27:06 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
2026-05-01 18:27:06.748 | (APIServer pid=1) INFO 05-01 16:27:06 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 18:27:06.748 | (APIServer pid=1) WARNING 05-01 16:27:06 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-01 18:27:06.748 | (APIServer pid=1) INFO 05-01 16:27:06 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 18:27:06.748 | (APIServer pid=1) INFO 05-01 16:27:06 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 18:27:10.228 | (APIServer pid=1) INFO 05-01 16:27:10 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 18:27:10.405 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 18:27:22.570 | (APIServer pid=1) INFO 05-01 16:27:22 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 18:27:16.748 | INFO 05-01 16:27:16 [nixl_utils.py:32] NIXL is available
2026-05-01 18:27:16.848 | (EngineCore pid=255) INFO 05-01 16:27:16 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', speculative_config=SpeculativeConfig(method='mtp', model='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', num_spec_tokens=3), tokenizer='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=131072, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-27b-text-nvfp4-mtp, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [16384], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 16, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 18:27:17.049 | (EngineCore pid=255) WARNING 05-01 16:27:17 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 18:27:17.183 | (EngineCore pid=255) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 18:27:20.080 | (EngineCore pid=255) INFO 05-01 16:27:20 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 18:27:20.151 | (EngineCore pid=255) INFO 05-01 16:27:20 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:34459 backend=nccl
2026-05-01 18:27:20.438 | (EngineCore pid=255) INFO 05-01 16:27:20 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank N/A, EPLB rank N/A
2026-05-01 18:27:21.136 | (EngineCore pid=255) WARNING 05-01 16:27:21 [__init__.py:206] min_p and logit_bias parameters won't work with speculative decoding.
2026-05-01 18:27:21.175 | (EngineCore pid=255) INFO 05-01 16:27:21 [gpu_model_runner.py:4777] Starting to load model sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP...
2026-05-01 18:27:21.416 | (EngineCore pid=255) INFO 05-01 16:27:21 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 18:27:21.417 | (EngineCore pid=255) INFO 05-01 16:27:21 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 18:27:21.519 | (EngineCore pid=255) INFO 05-01 16:27:21 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 18:27:21.522 | (EngineCore pid=255) INFO 05-01 16:27:21 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 18:27:22.763 | (EngineCore pid=255) INFO 05-01 16:27:22 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 18:27:24.046 | (EngineCore pid=255) INFO 05-01 16:27:24 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-05-01 18:27:24.048 | (EngineCore pid=255) INFO 05-01 16:27:24 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.29 GiB. Available RAM: 56.34 GiB.
2026-05-01 18:27:24.048 | (EngineCore pid=255) INFO 05-01 16:27:24 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 18:27:24.048 | (EngineCore pid=255) 
2026-05-01 18:27:24.048 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-05-01 18:27:55.149 | (EngineCore pid=255) 
2026-05-01 18:27:55.149 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:31<00:00, 31.10s/it]
2026-05-01 18:27:55.149 | (EngineCore pid=255) 
2026-05-01 18:27:55.149 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:31<00:00, 31.10s/it]
2026-05-01 18:27:55.149 | (EngineCore pid=255) 
2026-05-01 18:27:56.022 | (EngineCore pid=255) INFO 05-01 16:27:56 [default_loader.py:384] Loading weights took 35.48 seconds
2026-05-01 18:27:56.136 | (EngineCore pid=255) WARNING 05-01 16:27:56 [kv_cache.py:109] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
2026-05-01 18:27:56.137 | (EngineCore pid=255) WARNING 05-01 16:27:56 [kv_cache.py:123] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
2026-05-01 18:27:56.137 | (EngineCore pid=255) WARNING 05-01 16:27:56 [kv_cache.py:162] Using uncalibrated q_scale 1.0 and/or prob_scale 1.0 with fp8 attention. This may cause accuracy issues. Please make sure q/prob scaling factors are available in the fp8 checkpoint.
2026-05-01 18:27:56.412 | (EngineCore pid=255) INFO 05-01 16:27:56 [gpu_model_runner.py:4801] Loading drafter model...
2026-05-01 18:27:56.905 | (EngineCore pid=255) INFO 05-01 16:27:56 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-05-01 18:27:56.906 | (EngineCore pid=255) INFO 05-01 16:27:56 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.29 GiB. Available RAM: 56.28 GiB.
2026-05-01 18:27:56.906 | (EngineCore pid=255) 
2026-05-01 18:27:56.906 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-05-01 18:27:58.561 | (EngineCore pid=255) 
2026-05-01 18:27:58.561 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:01<00:00,  1.66s/it]
2026-05-01 18:27:58.561 | (EngineCore pid=255) 
2026-05-01 18:27:58.561 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:01<00:00,  1.66s/it]
2026-05-01 18:27:58.561 | (EngineCore pid=255) 
2026-05-01 18:27:59.434 | (EngineCore pid=255) INFO 05-01 16:27:59 [default_loader.py:384] Loading weights took 2.53 seconds
2026-05-01 18:27:59.436 | (EngineCore pid=255) INFO 05-01 16:27:59 [llm_base_proposer.py:1445] Detected MTP model. Sharing target model embedding weights with the draft model.
2026-05-01 18:27:59.436 | (EngineCore pid=255) INFO 05-01 16:27:59 [llm_base_proposer.py:1501] Detected MTP model. Sharing target model lm_head weights with the draft model.
2026-05-01 18:28:00.074 | (EngineCore pid=255) INFO 05-01 16:28:00 [gpu_model_runner.py:4879] Model loading took 18.41 GiB memory and 41.551564 seconds
2026-05-01 18:28:00.075 | (EngineCore pid=255) INFO 05-01 16:28:00 [interface.py:606] Setting attention block size to 1600 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 18:28:00.075 | (EngineCore pid=255) INFO 05-01 16:28:00 [interface.py:630] Padding mamba page size by 0.25% to ensure that mamba page size and attention page size are exactly equal.
2026-05-01 18:28:16.702 | (EngineCore pid=255) INFO 05-01 16:28:16 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/02e7c7c89e/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 18:28:16.702 | (EngineCore pid=255) INFO 05-01 16:28:16 [backends.py:1128] Dynamo bytecode transform time: 18.35 s
2026-05-01 18:28:21.185 | (EngineCore pid=255) INFO 05-01 16:28:21 [backends.py:376] Cache the graph of compile range (1, 16384) for later use
2026-05-01 18:29:00.024 | (EngineCore pid=255) INFO 05-01 16:29:00 [backends.py:391] Compiling a graph for compile range (1, 16384) takes 46.24 s
2026-05-01 18:29:09.174 | (EngineCore pid=255) INFO 05-01 16:29:09 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/2b2d9181a756e9b56824bea2d837508717b9ead6db21a189b1c1ea1ab95e352b/rank_0_0/model
2026-05-01 18:29:09.174 | (EngineCore pid=255) INFO 05-01 16:29:09 [monitor.py:53] torch.compile took 75.83 s in total
2026-05-01 18:30:02.476 | (EngineCore pid=255) INFO 05-01 16:30:02 [monitor.py:81] Initial profiling/warmup run took 58.80 s
2026-05-01 18:30:03.237 | (EngineCore pid=255) INFO 05-01 16:30:03 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/02e7c7c89e/rank_0_0/eagle_head for vLLM's torch.compile
2026-05-01 18:30:03.237 | (EngineCore pid=255) INFO 05-01 16:30:03 [backends.py:1128] Dynamo bytecode transform time: 0.76 s
2026-05-01 18:30:16.469 | (EngineCore pid=255) INFO 05-01 16:30:16 [backends.py:391] Compiling a graph for compile range (1, 16384) takes 14.50 s
2026-05-01 18:30:16.731 | (EngineCore pid=255) INFO 05-01 16:30:16 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/798cd63bd76487ebdd5e58d461368b278380757a7e60de852aa24832ab726972/rank_0_0/model
2026-05-01 18:30:16.731 | (EngineCore pid=255) INFO 05-01 16:30:16 [monitor.py:53] torch.compile took 15.75 s in total
2026-05-01 18:30:18.293 | (EngineCore pid=255) INFO 05-01 16:30:18 [monitor.py:81] Initial profiling/warmup run took 1.56 s
2026-05-01 18:30:32.804 | (EngineCore pid=255) WARNING 05-01 16:30:32 [kv_cache_utils.py:1140] Add 3 padding layers, may waste at most 6.25% KV cache memory
2026-05-01 18:30:32.816 | (EngineCore pid=255) WARNING 05-01 16:30:32 [compilation.py:1390] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for attention backend FlashInferBackend (support: AttentionCGSupport.UNIFORM_SINGLE_TOKEN_DECODE); setting cudagraph_mode=PIECEWISE
2026-05-01 18:30:32.828 | (EngineCore pid=255) INFO 05-01 16:30:32 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=5 (largest=16)
2026-05-01 18:30:22.442 | (EngineCore pid=255) INFO 05-01 16:30:22 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.09 GiB total
2026-05-01 18:30:23.014 | (EngineCore pid=255) INFO 05-01 16:30:23 [gpu_worker.py:440] Available KV cache memory: 6.56 GiB
2026-05-01 18:30:23.015 | (EngineCore pid=255) INFO 05-01 16:30:23 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.9000 is equivalent to --gpu-memory-utilization=0.8971 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.9029. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 18:30:23.015 | (EngineCore pid=255) WARNING 05-01 16:30:23 [kv_cache_utils.py:1140] Add 3 padding layers, may waste at most 6.25% KV cache memory
2026-05-01 18:30:23.015 | (EngineCore pid=255) INFO 05-01 16:30:23 [kv_cache_utils.py:1711] GPU KV cache size: 49,600 tokens
2026-05-01 18:30:23.016 | (EngineCore pid=255) INFO 05-01 16:30:23 [kv_cache_utils.py:1716] Maximum concurrency for 131,072 tokens per request: 1.30x
2026-05-01 18:30:23.176 | (EngineCore pid=255) 2026-05-01 16:30:23,176 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 18:30:26.498 | (EngineCore pid=255) 
2026-05-01 18:30:26.498 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:30:26.498 | [AutoTuner]: Tuning fp4_gemm:  47%|████▋     | 7/15 [00:00<00:00, 67.61profile/s]
2026-05-01 18:30:26.498 | [AutoTuner]: Tuning fp4_gemm:  93%|█████████▎| 14/15 [00:00<00:00, 31.72profile/s]
2026-05-01 18:30:26.498 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:03<00:00,  4.55profile/s]
2026-05-01 18:30:27.005 | (EngineCore pid=255) 
2026-05-01 18:30:27.005 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:30:27.005 | [AutoTuner]: Tuning fp4_gemm:  60%|██████    | 9/15 [00:00<00:00, 81.42profile/s]
2026-05-01 18:30:27.005 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:00<00:00, 29.77profile/s]
2026-05-01 18:30:29.914 | (EngineCore pid=255) 
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  13%|█▎        | 2/15 [00:00<00:01, 12.02profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  27%|██▋       | 4/15 [00:00<00:00, 13.30profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  40%|████      | 6/15 [00:00<00:00, 13.74profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  53%|█████▎    | 8/15 [00:00<00:00, 13.94profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  67%|██████▋   | 10/15 [00:00<00:00, 13.94profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  80%|████████  | 12/15 [00:00<00:00, 13.36profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm:  93%|█████████▎| 14/15 [00:01<00:00,  8.13profile/s]
2026-05-01 18:30:29.914 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:02<00:00,  5.16profile/s]
2026-05-01 18:30:34.144 | (EngineCore pid=255) 
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:   7%|▋         | 1/15 [00:00<00:02,  6.56profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  13%|█▎        | 2/15 [00:00<00:02,  5.43profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  20%|██        | 3/15 [00:00<00:02,  5.70profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  27%|██▋       | 4/15 [00:00<00:01,  5.57profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  53%|█████▎    | 8/15 [00:00<00:00, 11.87profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  67%|██████▋   | 10/15 [00:01<00:00,  7.68profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  73%|███████▎  | 11/15 [00:01<00:00,  5.42profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  80%|████████  | 12/15 [00:03<00:01,  2.22profile/s]
2026-05-01 18:30:34.144 | [AutoTuner]: Tuning fp4_gemm:  87%|████████▋ | 13/15 [00:04<00:01,  1.72profile/s]2026-05-01 16:30:34,143 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136] EngineCore failed to start.
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136] Traceback (most recent call last):
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     super().__init__(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 283, in _initialize_kv_caches
2026-05-01 18:30:34.153 | (EngineCore pid=255) Process EngineCore:
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     self.model_executor.initialize_from_config(kv_cache_configs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 124, in initialize_from_config
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     compilation_times: list[CompilationTimes] = self.collective_rpc(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                                                 ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     result = run_method(self.driver_worker, method, args, kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 586, in compile_or_warm_up_model
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     kernel_warmup(self)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 46, in kernel_warmup
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     flashinfer_autotune(worker.model_runner)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 103, in flashinfer_autotune
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     runner._dummy_run(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5537, in _dummy_run
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     outputs = self.model(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]               ^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/cuda_graph.py", line 254, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.runnable(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self._call_impl(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return forward_call(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 695, in forward
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     hidden_states = self.language_model.model(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 480, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.aot_compiled_fn(self, *args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/aot_compile.py", line 224, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 495, in forward
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     def forward(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/caching.py", line 215, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.optimized_call(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "<string>", line 291, in execution_fn
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/cuda_graph.py", line 254, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.runnable(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/piecewise_backend.py", line 380, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return range_entry.runnable(*args)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/standalone_compile.py", line 122, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self._compiled_fn(*args)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/aot_autograd.py", line 1200, in forward
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return compiled_fn(full_args)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 580, in runtime_wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     all_outs = call_func_at_runtime_with_args(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/utils.py", line 138, in call_func_at_runtime_with_args
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     out = normalize_as_list(f(args))
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                             ^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 2298, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.compiled_fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 783, in wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return compiled_fn(runtime_args)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 1011, in inner_fn
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     outs = compiled_fn(args)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/output_code.py", line 656, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self.current_callable(inputs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/utils.py", line 3401, in run
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     out = model(new_inputs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]           ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/root/.cache/vllm/torch_compile_cache/torch_aot_compile/2b2d9181a756e9b56824bea2d837508717b9ead6db21a189b1c1ea1ab95e352b/inductor_cache/e2/ce2vyipkep6v5uoppxp4q6kioxv2oc63gqtxkh6jo4r6uacbbubb.py", line 1437, in call
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     buf20 = torch.ops.vllm.flashinfer_mm_fp4.default(buf12, reinterpret_tensor(arg16_1, (2560, 34816), (1, 2560), 0), aten.view.dtype(buf19, torch.uint8), aten.view.dtype(reinterpret_tensor(arg15_1, (320, 34816), (1, 320), 0), torch.uint8), arg17_1, torch.bfloat16, False, 'cutlass')
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_ops.py", line 865, in __call__
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return self._op(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 347, in backend_impl
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     result = self._backend_fns[device_type](*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_compile.py", line 54, in inner
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return disable_fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 382, in wrapped_fn
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return fn(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 486, in flashinfer_mm_fp4
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return flashinfer_mm_fp4_(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/utils.py", line 1246, in wrapper
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 5093, in mm_fp4
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     runner, tactic = tuner.choose_one(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]                      ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 748, in choose_one
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     tensors = self._prepare_input_tensors(p, inputs)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1163, in _prepare_input_tensors
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     tensor = self._create_tensor_like(
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]              ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1148, in _create_tensor_like
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     return initializer(shapes, dtype, device)
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1154, in <lambda>
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     torch.rand(shapes, device=device) * 10 - 5
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136]     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~
2026-05-01 18:30:34.153 | (EngineCore pid=255) ERROR 05-01 16:30:34 [core.py:1136] RuntimeError: CUDA driver error: device not ready
2026-05-01 18:30:34.155 | (EngineCore pid=255) Traceback (most recent call last):
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 18:30:34.156 | (EngineCore pid=255)     self.run()
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 18:30:34.156 | (EngineCore pid=255)     self._target(*self._args, **self._kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 18:30:34.156 | (EngineCore pid=255)     raise e
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 18:30:34.156 | (EngineCore pid=255)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     super().__init__(
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 18:30:34.156 | (EngineCore pid=255)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 283, in _initialize_kv_caches
2026-05-01 18:30:34.156 | (EngineCore pid=255)     self.model_executor.initialize_from_config(kv_cache_configs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 124, in initialize_from_config
2026-05-01 18:30:34.156 | (EngineCore pid=255)     compilation_times: list[CompilationTimes] = self.collective_rpc(
2026-05-01 18:30:34.156 | (EngineCore pid=255)                                                 ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-05-01 18:30:34.156 | (EngineCore pid=255)     result = run_method(self.driver_worker, method, args, kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 586, in compile_or_warm_up_model
2026-05-01 18:30:34.156 | (EngineCore pid=255)     kernel_warmup(self)
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 46, in kernel_warmup
2026-05-01 18:30:34.156 | (EngineCore pid=255)     flashinfer_autotune(worker.model_runner)
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 103, in flashinfer_autotune
2026-05-01 18:30:34.156 | (EngineCore pid=255)     runner._dummy_run(
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5537, in _dummy_run
2026-05-01 18:30:34.156 | (EngineCore pid=255)     outputs = self.model(
2026-05-01 18:30:34.156 | (EngineCore pid=255)               ^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/cuda_graph.py", line 254, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.runnable(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self._call_impl(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return forward_call(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 695, in forward
2026-05-01 18:30:34.156 | (EngineCore pid=255)     hidden_states = self.language_model.model(
2026-05-01 18:30:34.156 | (EngineCore pid=255)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 480, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.aot_compiled_fn(self, *args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/aot_compile.py", line 224, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 495, in forward
2026-05-01 18:30:34.156 | (EngineCore pid=255)     def forward(
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/caching.py", line 215, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.optimized_call(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "<string>", line 291, in execution_fn
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/cuda_graph.py", line 254, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.runnable(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/piecewise_backend.py", line 380, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return range_entry.runnable(*args)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/standalone_compile.py", line 122, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self._compiled_fn(*args)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/aot_autograd.py", line 1200, in forward
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return compiled_fn(full_args)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 580, in runtime_wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     all_outs = call_func_at_runtime_with_args(
2026-05-01 18:30:34.156 | (EngineCore pid=255)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/utils.py", line 138, in call_func_at_runtime_with_args
2026-05-01 18:30:34.156 | (EngineCore pid=255)     out = normalize_as_list(f(args))
2026-05-01 18:30:34.156 | (EngineCore pid=255)                             ^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 2298, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.compiled_fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 783, in wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return compiled_fn(runtime_args)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_functorch/_aot_autograd/runtime_wrappers.py", line 1011, in inner_fn
2026-05-01 18:30:34.156 | (EngineCore pid=255)     outs = compiled_fn(args)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/output_code.py", line 656, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self.current_callable(inputs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_inductor/utils.py", line 3401, in run
2026-05-01 18:30:34.156 | (EngineCore pid=255)     out = model(new_inputs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)           ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/root/.cache/vllm/torch_compile_cache/torch_aot_compile/2b2d9181a756e9b56824bea2d837508717b9ead6db21a189b1c1ea1ab95e352b/inductor_cache/e2/ce2vyipkep6v5uoppxp4q6kioxv2oc63gqtxkh6jo4r6uacbbubb.py", line 1437, in call
2026-05-01 18:30:34.156 | (EngineCore pid=255)     buf20 = torch.ops.vllm.flashinfer_mm_fp4.default(buf12, reinterpret_tensor(arg16_1, (2560, 34816), (1, 2560), 0), aten.view.dtype(buf19, torch.uint8), aten.view.dtype(reinterpret_tensor(arg15_1, (320, 34816), (1, 320), 0), torch.uint8), arg17_1, torch.bfloat16, False, 'cutlass')
2026-05-01 18:30:34.156 | (EngineCore pid=255)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_ops.py", line 865, in __call__
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return self._op(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 347, in backend_impl
2026-05-01 18:30:34.156 | (EngineCore pid=255)     result = self._backend_fns[device_type](*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_compile.py", line 54, in inner
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return disable_fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 382, in wrapped_fn
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return fn(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 486, in flashinfer_mm_fp4
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return flashinfer_mm_fp4_(
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/utils.py", line 1246, in wrapper
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return func(*args, **kwargs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 5093, in mm_fp4
2026-05-01 18:30:34.156 | (EngineCore pid=255)     runner, tactic = tuner.choose_one(
2026-05-01 18:30:34.156 | (EngineCore pid=255)                      ^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 748, in choose_one
2026-05-01 18:30:34.156 | (EngineCore pid=255)     tensors = self._prepare_input_tensors(p, inputs)
2026-05-01 18:30:34.156 | (EngineCore pid=255)               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1163, in _prepare_input_tensors
2026-05-01 18:30:34.156 | (EngineCore pid=255)     tensor = self._create_tensor_like(
2026-05-01 18:30:34.156 | (EngineCore pid=255)              ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1148, in _create_tensor_like
2026-05-01 18:30:34.156 | (EngineCore pid=255)     return initializer(shapes, dtype, device)
2026-05-01 18:30:34.156 | (EngineCore pid=255)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:34.156 | (EngineCore pid=255)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 1154, in <lambda>
2026-05-01 18:30:34.156 | (EngineCore pid=255)     torch.rand(shapes, device=device) * 10 - 5
2026-05-01 18:30:34.156 | (EngineCore pid=255)     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~
2026-05-01 18:30:34.156 | (EngineCore pid=255) RuntimeError: CUDA driver error: device not ready
2026-05-01 18:30:34.157 | (EngineCore pid=255) 
2026-05-01 18:30:34.157 | [AutoTuner]: Tuning fp4_gemm:  87%|████████▋ | 13/15 [00:04<00:00,  3.07profile/s]
2026-05-01 18:30:35.483 | [rank0]:[W501 16:30:35.692036802 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 18:30:37.249 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 18:30:37.249 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 18:30:37.249 | (APIServer pid=1)     sys.exit(main())
2026-05-01 18:30:37.249 | (APIServer pid=1)              ^^^^^^
2026-05-01 18:30:37.249 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 18:30:37.249 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 18:30:37.249 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 18:30:37.249 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 18:30:37.249 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 18:30:37.249 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 18:30:37.249 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 18:30:37.249 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 18:30:37.253 | (APIServer pid=1)     return runner.run(main)
2026-05-01 18:30:37.253 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.253 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 18:30:37.253 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 18:30:37.253 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.253 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 18:30:37.253 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 18:30:37.253 | (APIServer pid=1)     return await main
2026-05-01 18:30:37.253 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 18:30:37.253 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 18:30:37.254 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 18:30:37.254 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:30:37.254 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:30:37.254 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 18:30:37.254 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:30:37.254 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:30:37.254 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 18:30:37.254 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 18:30:37.254 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 18:30:37.254 | (APIServer pid=1)     return cls(
2026-05-01 18:30:37.254 | (APIServer pid=1)            ^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 18:30:37.254 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 18:30:37.254 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:37.254 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 18:30:37.254 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 18:30:37.254 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 18:30:37.254 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.254 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:30:37.255 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 18:30:37.255 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:30:37.255 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 18:30:37.255 | (APIServer pid=1)     super().__init__(
2026-05-01 18:30:37.255 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 18:30:37.255 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 18:30:37.255 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 18:30:37.255 | (APIServer pid=1)     next(self.gen)
2026-05-01 18:30:37.255 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 18:30:37.255 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 18:30:37.255 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 18:30:37.255 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 18:30:37.255 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}