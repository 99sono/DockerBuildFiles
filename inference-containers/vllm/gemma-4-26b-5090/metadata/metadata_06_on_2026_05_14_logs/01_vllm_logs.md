# doocker compose file used

```compose
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:v0.20.2-ubuntu2404
    container_name: gemma-4-26b-it-nvfp4-stable
    hostname: vllm
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
      # Model (NVIDIA official NVFP4 checkpoint)
      - "nvidia/Gemma-4-26B-A4B-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"

      # Required
      - "--trust-remote-code"

      # Networking
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # Memory budget
      - "--gpu-memory-utilization"
      - "0.85"

      # ===== Long-context experiment =====
      - "--max-model-len"
      - "256000"

      # Batching (intentionally conservative for long windows)
      - "--max-num-seqs"
      - "2"
      - "--max-num-batched-tokens"
      - "16384"

      # KV cache
      - "--kv-cache-dtype"
      - "fp8_e4m3"

      # Quantization
      - "--quantization"
      - "compressed-tensors"

      # Long-context ergonomics
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # Reasoning + tools
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      # Auto tool choice is needed for open code, otherwise a snippet of code like the one bellow will raise an error HTTO 400 (bad request).
      #       response = client.chat.completions.create(
      # model="meta-llama/Llama-3.1-8B-Instruct",
      # messages=[{"role": "user", "content": "What's the weather in Paris?"}],
      # tools=tools,
      # tool_choice="auto"
      # )
      # ❌ Raises: 400 "auto" 
      # In short: tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set
      - "--enable-auto-tool-choice"

      # NVFP4 MoE backend (NVIDIA docs: TP=1 only, cutlass or marlin)
      - "--moe-backend"
      - "cutlass"

      # Optional ultra-stability fallback (DISABLED by default)
      # - "--moe-backend"
      # - "marlin"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm logs

2026-05-14 12:35:46.867 | WARNING 05-14 10:35:46 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299] 
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299]        █     █     █▄   ▄█
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.2
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299]   █▄█▀ █     █     █     █  model   nvidia/Gemma-4-26B-A4B-NVFP4
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-14 12:35:46.986 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:299] 
2026-05-14 12:35:46.989 | (APIServer pid=1) INFO 05-14 10:35:46 [utils.py:233] non-default args: {'model_tag': 'nvidia/Gemma-4-26B-A4B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'nvidia/Gemma-4-26B-A4B-NVFP4', 'trust_remote_code': True, 'max_model_len': 256000, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 16384, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-05-14 12:35:47.168 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-14 12:36:00.647 | (APIServer pid=1) INFO 05-14 10:36:00 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-14 12:36:00.685 | (APIServer pid=1) INFO 05-14 10:36:00 [nixl_utils.py:32] NIXL is available
2026-05-14 12:36:00.897 | (APIServer pid=1) INFO 05-14 10:36:00 [model.py:555] Resolved architecture: Gemma4ForConditionalGeneration
2026-05-14 12:36:00.898 | (APIServer pid=1) INFO 05-14 10:36:00 [model.py:1680] Using max model len 256000
2026-05-14 12:36:01.315 | (APIServer pid=1) INFO 05-14 10:36:01 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-14 12:36:01.316 | (APIServer pid=1) INFO 05-14 10:36:01 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=16384.
2026-05-14 12:36:01.316 | (APIServer pid=1) INFO 05-14 10:36:01 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-05-14 12:36:01.316 | (APIServer pid=1) WARNING 05-14 10:36:01 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-14 12:36:01.317 | (APIServer pid=1) INFO 05-14 10:36:01 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-14 12:36:01.317 | (APIServer pid=1) INFO 05-14 10:36:01 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-14 12:36:01.317 | (APIServer pid=1) WARNING 05-14 10:36:01 [cuda.py:233] Forcing --disable_chunked_mm_input for models with multimodal-bidirectional attention.
2026-05-14 12:36:06.879 | (APIServer pid=1) INFO 05-14 10:36:06 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-14 12:36:17.361 | INFO 05-14 10:36:17 [nixl_utils.py:32] NIXL is available
2026-05-14 12:36:17.482 | (EngineCore pid=219) INFO 05-14 10:36:17 [core.py:109] Initializing a V1 LLM engine (v0.20.2) with config: model='nvidia/Gemma-4-26B-A4B-NVFP4', speculative_config=None, tokenizer='nvidia/Gemma-4-26B-A4B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=256000, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [16384], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-14 12:36:17.696 | (EngineCore pid=219) WARNING 05-14 10:36:17 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-14 12:36:18.019 | (EngineCore pid=219) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-14 12:36:22.897 | (EngineCore pid=219) INFO 05-14 10:36:22 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:40247 backend=nccl
2026-05-14 12:36:23.209 | (EngineCore pid=219) INFO 05-14 10:36:23 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-14 12:36:24.063 | (EngineCore pid=219) INFO 05-14 10:36:24 [gpu_model_runner.py:4777] Starting to load model nvidia/Gemma-4-26B-A4B-NVFP4...
2026-05-14 12:36:25.035 | (EngineCore pid=219) INFO 05-14 10:36:25 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-14 12:36:25.037 | (EngineCore pid=219) INFO 05-14 10:36:25 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-14 12:36:25.037 | (EngineCore pid=219) INFO 05-14 10:36:25 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-14 12:36:25.196 | (EngineCore pid=219) INFO 05-14 10:36:25 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-05-14 12:36:25.224 | (EngineCore pid=219) INFO 05-14 10:36:25 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-14 12:36:25.351 | (EngineCore pid=219) INFO 05-14 10:36:25 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-05-14 12:41:18.328 | (EngineCore pid=219) INFO 05-14 10:41:18 [weight_utils.py:615] Time spent downloading weights for nvidia/Gemma-4-26B-A4B-NVFP4: 321.026710 seconds
2026-05-14 12:41:18.555 | (EngineCore pid=219) INFO 05-14 10:41:18 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 17.50 GiB. Available RAM: 55.45 GiB.
2026-05-14 12:41:18.555 | (EngineCore pid=219) INFO 05-14 10:41:18 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-14 12:41:18.555 | (EngineCore pid=219) 
2026-05-14 12:41:18.555 | Loading safetensors checkpoint shards:   0% Completed | 0/2 [00:00<?, ?it/s]
2026-05-14 12:41:29.550 | (EngineCore pid=219) 
2026-05-14 12:41:29.550 | Loading safetensors checkpoint shards:  50% Completed | 1/2 [00:10<00:10, 10.99s/it]
2026-05-14 12:41:42.832 | (EngineCore pid=219) 
2026-05-14 12:41:42.832 | Loading safetensors checkpoint shards: 100% Completed | 2/2 [00:24<00:00, 12.34s/it]
2026-05-14 12:41:42.832 | (EngineCore pid=219) 
2026-05-14 12:41:42.832 | Loading safetensors checkpoint shards: 100% Completed | 2/2 [00:24<00:00, 12.14s/it]
2026-05-14 12:41:42.832 | (EngineCore pid=219) 
2026-05-14 12:41:43.146 | (EngineCore pid=219) INFO 05-14 10:41:43 [default_loader.py:384] Loading weights took 27.32 seconds
2026-05-14 12:41:43.165 | (EngineCore pid=219) WARNING 05-14 10:41:43 [kv_cache.py:109] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
2026-05-14 12:41:43.166 | (EngineCore pid=219) WARNING 05-14 10:41:43 [kv_cache.py:123] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
2026-05-14 12:41:43.481 | (EngineCore pid=219) WARNING 05-14 10:41:43 [modelopt.py:1376] w1_weight_scale_2 must match w3_weight_scale_2. Accuracy may be affected.
2026-05-14 12:41:43.555 | (EngineCore pid=219) INFO 05-14 10:41:43 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-14 12:41:44.293 | (EngineCore pid=219) INFO 05-14 10:41:44 [gpu_model_runner.py:4879] Model loading took 17.89 GiB memory and 352.087376 seconds
2026-05-14 12:41:44.577 | (EngineCore pid=219) INFO 05-14 10:41:44 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 6 video items of the maximum feature size.
2026-05-14 12:42:05.546 | (EngineCore pid=219) WARNING 05-14 10:42:05 [op.py:241] Priority not set for op rms_norm, using native implementation.
2026-05-14 12:42:26.771 | (EngineCore pid=219) INFO 05-14 10:42:26 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/f18f0551e0/rank_0_0/backbone for vLLM's torch.compile
2026-05-14 12:42:26.771 | (EngineCore pid=219) INFO 05-14 10:42:26 [backends.py:1128] Dynamo bytecode transform time: 11.24 s
2026-05-14 12:42:38.266 | (EngineCore pid=219) INFO 05-14 10:42:38 [backends.py:376] Cache the graph of compile range (1, 16384) for later use
2026-05-14 12:43:04.569 | (EngineCore pid=219) INFO 05-14 10:43:04 [backends.py:391] Compiling a graph for compile range (1, 16384) takes 42.64 s
2026-05-14 12:43:09.481 | (EngineCore pid=219) INFO 05-14 10:43:09 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/4e842760c499a64b7a63c883ab2168cbb24015a80f24032849a2d3735dec84d2/rank_0_0/model
2026-05-14 12:43:09.481 | (EngineCore pid=219) INFO 05-14 10:43:09 [monitor.py:53] torch.compile took 59.41 s in total
2026-05-14 12:43:12.552 | (EngineCore pid=219) INFO 05-14 10:43:12 [monitor.py:81] Initial profiling/warmup run took 3.07 s
2026-05-14 12:43:13.531 | (EngineCore pid=219) INFO 05-14 10:43:13 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=2 (largest=2)
2026-05-14 12:43:19.685 | (EngineCore pid=219) INFO 05-14 10:43:19 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.26 GiB total
2026-05-14 12:43:20.134 | (EngineCore pid=219) INFO 05-14 10:43:20 [gpu_worker.py:440] Available KV cache memory: 4.58 GiB
2026-05-14 12:43:20.134 | (EngineCore pid=219) INFO 05-14 10:43:20 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8420 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8580. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-14 12:43:20.135 | (EngineCore pid=219) INFO 05-14 10:43:20 [kv_cache_utils.py:1708] GPU KV cache size: 286,007 tokens
2026-05-14 12:43:20.135 | (EngineCore pid=219) INFO 05-14 10:43:20 [kv_cache_utils.py:1709] Maximum concurrency for 256,000 tokens per request: 1.12x
2026-05-14 12:43:20.235 | (EngineCore pid=219) 2026-05-14 10:43:20,234 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-14 12:43:20.372 | (EngineCore pid=219) 2026-05-14 10:43:20,372 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-14 12:43:21.428 | (EngineCore pid=219) 
2026-05-14 12:43:21.428 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-05-14 12:43:21.428 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  9.81it/s]
2026-05-14 12:43:21.428 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00, 10.41it/s]
2026-05-14 12:43:21.428 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00, 10.34it/s]
2026-05-14 12:43:21.635 | (EngineCore pid=219) 
2026-05-14 12:43:21.635 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/2 [00:00<?, ?it/s]
2026-05-14 12:43:21.635 | Capturing CUDA graphs (decode, FULL):  50%|█████     | 1/2 [00:00<00:00,  9.73it/s]
2026-05-14 12:43:21.635 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  9.70it/s]
2026-05-14 12:43:21.635 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  9.69it/s]
2026-05-14 12:43:22.094 | (EngineCore pid=219) INFO 05-14 10:43:22 [gpu_model_runner.py:6133] Graph capturing finished in 2 secs, took 0.40 GiB
2026-05-14 12:43:22.095 | (EngineCore pid=219) INFO 05-14 10:43:22 [gpu_worker.py:599] CUDA graph pool memory: 0.4 GiB (actual), 0.26 GiB (estimated), difference: 0.14 GiB (35.3%).
2026-05-14 12:43:22.149 | (EngineCore pid=219) INFO 05-14 10:43:22 [core.py:299] init engine (profile, create kv cache, warmup model) took 97.86 s (compilation: 59.41 s)
2026-05-14 12:43:22.675 | (EngineCore pid=219) INFO 05-14 10:43:22 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-14 12:43:22.695 | (APIServer pid=1) INFO 05-14 10:43:22 [api_server.py:598] Supported tasks: ['generate']
2026-05-14 12:43:22.957 | (APIServer pid=1) INFO 05-14 10:43:22 [parser_manager.py:202] "auto" tool choice has been enabled.
2026-05-14 12:43:23.134 | (APIServer pid=1) WARNING 05-14 10:43:23 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 64, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-14 12:43:28.109 | (APIServer pid=1) INFO 05-14 10:43:28 [hf.py:314] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
2026-05-14 12:43:46.991 | (APIServer pid=1) INFO 05-14 10:43:46 [base.py:233] Multi-modal warmup completed in 18.843s
2026-05-14 12:43:56.922 | (APIServer pid=1) INFO 05-14 10:43:56 [base.py:233] Readonly multi-modal warmup completed in 12.658s
2026-05-14 12:43:57.273 | (APIServer pid=1) INFO 05-14 10:43:57 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-14 12:43:57.273 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:37] Available routes are:
2026-05-14 12:43:57.273 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-14 12:43:57.273 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /load, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /version, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /health, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /ping, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /ping, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-14 12:43:57.274 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-14 12:43:57.275 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-14 12:43:57.275 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-14 12:43:57.275 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-14 12:43:57.275 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-14 12:43:57.275 | (APIServer pid=1) INFO 05-14 10:43:57 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-14 12:43:57.342 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-14 12:43:57.342 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-14 12:43:57.662 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-14 12:45:42.381 | (APIServer pid=1) INFO:     172.18.0.1:47066 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:45:42.419 | (APIServer pid=1) INFO:     172.18.0.1:47074 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:45:46.798 | (APIServer pid=1) INFO 05-14 10:45:46 [loggers.py:271] Engine 000: Avg prompt throughput: 1159.6 tokens/s, Avg generation throughput: 6.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-14 12:45:56.802 | (APIServer pid=1) INFO 05-14 10:45:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-14 12:46:11.461 | (APIServer pid=1) INFO:     172.18.0.1:39090 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:46:14.081 | (APIServer pid=1) INFO 05-14 10:46:14 [loggers.py:271] Engine 000: Avg prompt throughput: 1124.8 tokens/s, Avg generation throughput: 17.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.7%, Prefix cache hit rate: 31.3%
2026-05-14 12:46:24.083 | (APIServer pid=1) INFO 05-14 10:46:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 31.3%
2026-05-14 12:46:34.083 | (APIServer pid=1) INFO 05-14 10:46:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 31.3%
2026-05-14 12:47:08.496 | (APIServer pid=1) INFO:     172.18.0.1:48458 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:47:18.632 | (APIServer pid=1) INFO 05-14 10:47:18 [loggers.py:271] Engine 000: Avg prompt throughput: 83.2 tokens/s, Avg generation throughput: 15.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 57.3%
2026-05-14 12:47:28.635 | (APIServer pid=1) INFO 05-14 10:47:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 57.3%
2026-05-14 12:48:00.160 | (APIServer pid=1) INFO:     172.18.0.1:46874 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:48:03.195 | (APIServer pid=1) INFO 05-14 10:48:03 [loggers.py:271] Engine 000: Avg prompt throughput: 52.6 tokens/s, Avg generation throughput: 21.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 68.9%
2026-05-14 12:48:13.196 | (APIServer pid=1) INFO 05-14 10:48:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 68.9%
2026-05-14 12:48:31.450 | (APIServer pid=1) INFO:     172.18.0.1:59348 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:48:40.480 | (APIServer pid=1) INFO 05-14 10:48:40 [loggers.py:271] Engine 000: Avg prompt throughput: 58.9 tokens/s, Avg generation throughput: 73.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 75.3%
2026-05-14 12:48:50.482 | (APIServer pid=1) INFO 05-14 10:48:50 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 75.3%
2026-05-14 12:50:36.219 | (APIServer pid=1) INFO:     172.18.0.1:47096 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:50:38.095 | (APIServer pid=1) INFO:     172.18.0.1:47096 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:50:39.541 | (APIServer pid=1) INFO:     172.18.0.1:47096 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:50:39.599 | (APIServer pid=1) INFO 05-14 10:50:39 [loggers.py:271] Engine 000: Avg prompt throughput: 2516.6 tokens/s, Avg generation throughput: 9.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 72.8%
2026-05-14 12:50:40.967 | (APIServer pid=1) INFO:     172.18.0.1:47096 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:50:46.873 | (APIServer pid=1) INFO 05-14 10:50:46 [loggers.py:271] Engine 000: Avg prompt throughput: 267.0 tokens/s, Avg generation throughput: 15.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 81.3%
2026-05-14 12:50:56.875 | (APIServer pid=1) INFO 05-14 10:50:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 81.3%
2026-05-14 12:51:35.951 | (APIServer pid=1) INFO:     172.18.0.1:59598 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:51:38.186 | (APIServer pid=1) INFO:     172.18.0.1:59598 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:51:41.425 | (APIServer pid=1) INFO 05-14 10:51:41 [loggers.py:271] Engine 000: Avg prompt throughput: 1529.3 tokens/s, Avg generation throughput: 27.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 82.2%
2026-05-14 12:51:51.432 | (APIServer pid=1) INFO 05-14 10:51:51 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 82.2%
2026-05-14 12:52:08.699 | (APIServer pid=1) INFO:     172.18.0.1:43458 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:52:16.021 | (APIServer pid=1) INFO:     172.18.0.1:38534 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-14 12:52:18.712 | (APIServer pid=1) INFO 05-14 10:52:18 [loggers.py:271] Engine 000: Avg prompt throughput: 166.7 tokens/s, Avg generation throughput: 32.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.9%, Prefix cache hit rate: 85.6%
2026-05-14 12:52:28.712 | (APIServer pid=1) INFO 05-14 10:52:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.6%
2026-05-14 12:52:35.981 | (APIServer pid=1) INFO 05-14 10:52:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.6%


# opencode configuration

```json
{
  "$schema": "https://opencode.ai/config.json",

  "model": "local/gemma-4-26b-it-nvfp4-5090",

  "provider": {

    "local": {
      "name": "gemma-4-26b-it-nvfp4 (RTX 5090)",
      "options": {
        "baseURL": "http://localhost:8000/v1",
        "apiKey": "dummy-key"
      },
      "models": {
        "gemma-4-26b-it-nvfp4": {
          "name": "gemma-4-26b-it-nvfp4",
          "limit": { "context": 192000, "output": 32768 }
        }
      }
    }

}



```