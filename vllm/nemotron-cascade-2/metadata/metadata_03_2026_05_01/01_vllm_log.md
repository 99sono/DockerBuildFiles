# docker compose

```yml
version: "3.9"

services:
  nemotron-cascade:
    image: vllm/vllm-openai:nightly
    container_name: nemotron-cascade-2-nvfp4-stable
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
      # Required for Blackwell + WSL2 stability
      VLLM_WORKER_MULTIPROC_METHOD: spawn
            
      # Optional: cleaner allocator behavior with large contexts
      PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True

    command:
      # Model
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--served-model-name"
      - "nemotron-cascade-2-nvfp4"

      # Required for Nemotron models
      - "--trust-remote-code"

      # Quantization (weights remain NVFP4)
      - "--quantization"
      - "modelopt_fp4"

      # KV cache (stable on Blackwell)
      - "--kv-cache-dtype"
      - "fp8_e4m3"

      # Memory
      - "--gpu-memory-utilization"
      - "0.85"

      # Long-context safe for Cline
      - "--max-model-len"
      - "256000"

      # Allow batching if multiple requests arrive
      - "--max-num-seqs"
      - "128"
      - "--max-num-batched-tokens"
      - "32768"

      # ✅ CUDA graphs (safe with Marlin backend)
      - "--max-cudagraph-capture-size"
      - "512"
     
      # backend possibility
      # - "--moe-backend"
      # - "marlin"
      # 2026-04-23 23:45:50.475 | (EngineCore pid=176) INFO 04-23 21:45:50 [nvfp4.py:276] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].


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

# VLLM Log
2026-05-01 19:57:53.254 | WARNING 05-01 17:57:53 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299] 
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.1rc1.dev91+ga749a33d8
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299]   █▄█▀ █     █     █     █  model   chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 19:57:53.560 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:299] 
2026-05-01 19:57:53.564 | (APIServer pid=1) INFO 05-01 17:57:53 [utils.py:233] non-default args: {'model_tag': 'chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 256000, 'quantization': 'modelopt_fp4', 'served_model_name': ['nemotron-cascade-2-nvfp4'], 'reasoning_parser': 'nemotron_v3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'mamba_ssm_cache_dtype': 'float32', 'max_num_batched_tokens': 32768, 'max_num_seqs': 128, 'max_cudagraph_capture_size': 512}
2026-05-01 19:57:53.565 | (APIServer pid=1) WARNING 05-01 17:57:53 [envs.py:1821] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
2026-05-01 19:57:53.565 | (APIServer pid=1) WARNING 05-01 17:57:53 [envs.py:1821] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
2026-05-01 19:57:53.565 | (APIServer pid=1) WARNING 05-01 17:57:53 [envs.py:1821] Unknown vLLM environment variable detected: VLLM_BUILD_URL
2026-05-01 19:57:53.565 | (APIServer pid=1) WARNING 05-01 17:57:53 [envs.py:1821] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
2026-05-01 19:57:53.732 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 19:58:04.810 | (APIServer pid=1) INFO 05-01 17:58:04 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 19:58:04.844 | (APIServer pid=1) INFO 05-01 17:58:04 [nixl_utils.py:32] NIXL is available
2026-05-01 19:58:05.045 | (APIServer pid=1) INFO 05-01 17:58:05 [model.py:563] Resolved architecture: NemotronHForCausalLM
2026-05-01 19:58:05.045 | (APIServer pid=1) INFO 05-01 17:58:05 [model.py:1692] Using max model len 256000
2026-05-01 19:58:05.691 | (APIServer pid=1) INFO 05-01 17:58:05 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 19:58:05.692 | (APIServer pid=1) INFO 05-01 17:58:05 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-05-01 19:58:05.693 | (APIServer pid=1) WARNING 05-01 17:58:05 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-01 19:58:05.693 | (APIServer pid=1) INFO 05-01 17:58:05 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 19:58:05.694 | (APIServer pid=1) INFO 05-01 17:58:05 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 19:58:08.346 | (APIServer pid=1) INFO 05-01 17:58:08 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 19:58:14.065 | INFO 05-01 17:58:14 [nixl_utils.py:32] NIXL is available
2026-05-01 19:58:14.152 | (EngineCore pid=176) INFO 05-01 17:58:14 [core.py:109] Initializing a V1 LLM engine (v0.20.1rc1.dev91+ga749a33d8) with config: model='chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', speculative_config=None, tokenizer='chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=256000, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='nemotron_v3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=nemotron-cascade-2-nvfp4, enable_prefix_caching=False, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto')
2026-05-01 19:58:14.321 | (EngineCore pid=176) WARNING 05-01 17:58:14 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:58:14.399 | (EngineCore pid=176) INFO 05-01 17:58:14 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:37553 backend=nccl
2026-05-01 19:58:14.697 | (EngineCore pid=176) INFO 05-01 17:58:14 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 19:58:15.862 | (EngineCore pid=176) INFO 05-01 17:58:15 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
2026-05-01 19:58:15.979 | (EngineCore pid=176) INFO 05-01 17:58:15 [gpu_model_runner.py:4781] Starting to load model chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4...
2026-05-01 19:58:16.206 | (EngineCore pid=176) INFO 05-01 17:58:16 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 19:58:16.220 | (EngineCore pid=176) INFO 05-01 17:58:16 [nvfp4.py:279] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 19:58:16.311 | (EngineCore pid=176) INFO 05-01 17:58:16 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 19:58:17.376 | (EngineCore pid=176) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 19:58:17.828 | (EngineCore pid=176) INFO 05-01 17:58:17 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.01 GiB. Available RAM: 57.39 GiB.
2026-05-01 19:58:17.828 | (EngineCore pid=176) INFO 05-01 17:58:17 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 19:58:17.829 | (EngineCore pid=176) 
2026-05-01 19:58:17.829 | Loading safetensors checkpoint shards:   0% Completed | 0/4 [00:00<?, ?it/s]
2026-05-01 19:58:23.691 | (EngineCore pid=176) 
2026-05-01 19:58:23.691 | Loading safetensors checkpoint shards:  25% Completed | 1/4 [00:05<00:17,  5.86s/it]
2026-05-01 19:58:29.922 | (EngineCore pid=176) 
2026-05-01 19:58:29.922 | Loading safetensors checkpoint shards:  50% Completed | 2/4 [00:12<00:12,  6.08s/it]
2026-05-01 19:58:36.244 | (EngineCore pid=176) 
2026-05-01 19:58:36.244 | Loading safetensors checkpoint shards:  75% Completed | 3/4 [00:18<00:06,  6.19s/it]
2026-05-01 19:58:41.504 | (EngineCore pid=176) 
2026-05-01 19:58:41.504 | Loading safetensors checkpoint shards: 100% Completed | 4/4 [00:23<00:00,  5.82s/it]
2026-05-01 19:58:41.504 | (EngineCore pid=176) 
2026-05-01 19:58:41.504 | Loading safetensors checkpoint shards: 100% Completed | 4/4 [00:23<00:00,  5.92s/it]
2026-05-01 19:58:41.504 | (EngineCore pid=176) 
2026-05-01 19:58:41.688 | (EngineCore pid=176) INFO 05-01 17:58:41 [default_loader.py:391] Loading weights took 23.83 seconds
2026-05-01 19:58:41.844 | (EngineCore pid=176) INFO 05-01 17:58:41 [nvfp4.py:484] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 19:58:41.941 | (EngineCore pid=176) WARNING 05-01 17:58:41 [kv_cache.py:109] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
2026-05-01 19:58:41.942 | (EngineCore pid=176) WARNING 05-01 17:58:41 [kv_cache.py:123] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
2026-05-01 19:58:42.524 | (EngineCore pid=176) INFO 05-01 17:58:42 [gpu_model_runner.py:4883] Model loading took 18.54 GiB memory and 25.847705 seconds
2026-05-01 19:58:42.525 | (EngineCore pid=176) INFO 05-01 17:58:42 [interface.py:606] Setting attention block size to 4176 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 19:58:42.525 | (EngineCore pid=176) INFO 05-01 17:58:42 [interface.py:630] Padding mamba page size by 0.19% to ensure that mamba page size and attention page size are exactly equal.
2026-05-01 19:58:47.363 | (EngineCore pid=176) INFO 05-01 17:58:47 [backends.py:1070] Using cache directory: /root/.cache/vllm/torch_compile_cache/1b45eb2dca/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 19:58:47.363 | (EngineCore pid=176) INFO 05-01 17:58:47 [backends.py:1129] Dynamo bytecode transform time: 4.60 s
2026-05-01 19:58:49.704 | (EngineCore pid=176) INFO 05-01 17:58:49 [backends.py:377] Cache the graph of compile range (1, 32768) for later use
2026-05-01 19:58:50.074 | (EngineCore pid=176) /usr/local/lib/python3.12/dist-packages/torch/_inductor/compile_fx.py:322: UserWarning: TensorFloat32 tensor cores for float32 matrix multiplication available but not enabled. Consider setting `torch.set_float32_matmul_precision('high')` for better performance.
2026-05-01 19:58:50.074 | (EngineCore pid=176)   warnings.warn(
2026-05-01 19:58:58.739 | (EngineCore pid=176) INFO 05-01 17:58:58 [backends.py:392] Compiling a graph for compile range (1, 32768) takes 10.94 s
2026-05-01 19:59:00.539 | (EngineCore pid=176) INFO 05-01 17:59:00 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/fa1032ec2db7428ec45b9de6fb59309ff043d1ecc398ef871a02a7aae70cc229/rank_0_0/model
2026-05-01 19:59:00.539 | (EngineCore pid=176) INFO 05-01 17:59:00 [monitor.py:53] torch.compile took 17.73 s in total
2026-05-01 19:59:03.135 | (EngineCore pid=176) INFO 05-01 17:59:03 [monitor.py:81] Initial profiling/warmup run took 2.60 s
2026-05-01 19:59:03.880 | (EngineCore pid=176) WARNING 05-01 17:59:03 [kv_cache_utils.py:1152] Add 1 padding layers, may waste at most 4.35% KV cache memory
2026-05-01 19:59:03.881 | (EngineCore pid=176) INFO 05-01 17:59:03 [ssu_dispatch.py:222] Using triton Mamba SSU backend.
2026-05-01 19:59:03.983 | (EngineCore pid=176) INFO 05-01 17:59:03 [gpu_model_runner.py:5967] Profiling CUDA graph memory: PIECEWISE=51 (largest=512), FULL=19 (largest=128)
2026-05-01 19:59:06.570 | (EngineCore pid=176) INFO 05-01 17:59:06 [gpu_model_runner.py:6046] Estimated CUDA graph memory: 0.48 GiB total
2026-05-01 19:59:06.913 | (EngineCore pid=176) INFO 05-01 17:59:06 [gpu_worker.py:433] Available KV cache memory: 3.72 GiB
2026-05-01 19:59:06.913 | (EngineCore pid=176) INFO 05-01 17:59:06 [gpu_worker.py:448] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8348 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8652. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 19:59:06.913 | (EngineCore pid=176) WARNING 05-01 17:59:06 [kv_cache_utils.py:1152] Add 1 padding layers, may waste at most 4.35% KV cache memory
2026-05-01 19:59:06.913 | (EngineCore pid=176) INFO 05-01 17:59:06 [kv_cache_utils.py:1710] GPU KV cache size: 1,206,303 tokens
2026-05-01 19:59:06.913 | (EngineCore pid=176) INFO 05-01 17:59:06 [kv_cache_utils.py:1711] Maximum concurrency for 256,000 tokens per request: 4.71x
2026-05-01 19:59:07.003 | (EngineCore pid=176) 2026-05-01 17:59:07,002 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 19:59:07.495 | (EngineCore pid=176) 
2026-05-01 19:59:07.495 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
2026-05-01 19:59:07.495 | [AutoTuner]: Tuning fp4_gemm:  62%|██████▎   | 10/16 [00:00<00:00, 94.18profile/s]
2026-05-01 19:59:07.495 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:00<00:00, 36.24profile/s]
2026-05-01 19:59:07.725 | (EngineCore pid=176) 
2026-05-01 19:59:07.725 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
2026-05-01 19:59:07.725 | [AutoTuner]: Tuning fp4_gemm:  69%|██████▉   | 11/16 [00:00<00:00, 103.33profile/s]
2026-05-01 19:59:07.725 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:00<00:00, 70.29profile/s] 
2026-05-01 19:59:07.944 | (EngineCore pid=176) 
2026-05-01 19:59:07.944 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
2026-05-01 19:59:07.944 | [AutoTuner]: Tuning fp4_gemm:  75%|███████▌  | 12/16 [00:00<00:00, 108.89profile/s]
2026-05-01 19:59:07.944 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:00<00:00, 73.87profile/s] 
2026-05-01 19:59:08.164 | (EngineCore pid=176) 
2026-05-01 19:59:08.164 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
2026-05-01 19:59:08.164 | [AutoTuner]: Tuning fp4_gemm:  69%|██████▉   | 11/16 [00:00<00:00, 107.76profile/s]
2026-05-01 19:59:08.164 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:00<00:00, 73.53profile/s] 
2026-05-01 19:59:08.205 | (EngineCore pid=176) 
2026-05-01 19:59:08.205 | [AutoTuner]: Tuning trtllm::fused_moe::gemm1:   0%|          | 0/10 [00:00<?, ?profile/s]2026-05-01 17:59:08,205 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.232 | (EngineCore pid=176) 2026-05-01 17:59:08,231 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.262 | (EngineCore pid=176) 2026-05-01 17:59:08,261 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.296 | (EngineCore pid=176) 2026-05-01 17:59:08,295 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.338 | (EngineCore pid=176) 
2026-05-01 19:59:08.338 | [AutoTuner]: Tuning trtllm::fused_moe::gemm1:  40%|████      | 4/10 [00:00<00:00, 30.88profile/s]2026-05-01 17:59:08,338 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.387 | (EngineCore pid=176) 2026-05-01 17:59:08,387 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.440 | (EngineCore pid=176) 2026-05-01 17:59:08,440 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.495 | (EngineCore pid=176) 2026-05-01 17:59:08,495 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.550 | (EngineCore pid=176) 
2026-05-01 19:59:08.550 | [AutoTuner]: Tuning trtllm::fused_moe::gemm1:  80%|████████  | 8/10 [00:00<00:00, 23.45profile/s]2026-05-01 17:59:08,550 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.608 | (EngineCore pid=176) 2026-05-01 17:59:08,608 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
2026-05-01 19:59:08.608 | (EngineCore pid=176) 
2026-05-01 19:59:08.608 | [AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 10/10 [00:00<00:00, 22.64profile/s]
2026-05-01 19:59:08.675 | (EngineCore pid=176) 
2026-05-01 19:59:08.675 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2:   0%|          | 0/10 [00:00<?, ?profile/s]2026-05-01 17:59:08,674 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:08.733 | (EngineCore pid=176) 2026-05-01 17:59:08,733 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:08.793 | (EngineCore pid=176) 
2026-05-01 19:59:08.793 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2:  20%|██        | 2/10 [00:00<00:00, 16.15profile/s]2026-05-01 17:59:08,792 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:08.862 | (EngineCore pid=176) 2026-05-01 17:59:08,861 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:08.945 | (EngineCore pid=176) 
2026-05-01 19:59:08.945 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2:  40%|████      | 4/10 [00:00<00:00, 15.78profile/s]2026-05-01 17:59:08,945 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.039 | (EngineCore pid=176) 2026-05-01 17:59:09,039 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.144 | (EngineCore pid=176) 
2026-05-01 19:59:09.144 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2:  60%|██████    | 6/10 [00:00<00:00, 13.33profile/s]2026-05-01 17:59:09,144 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.250 | (EngineCore pid=176) 2026-05-01 17:59:09,250 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.357 | (EngineCore pid=176) 
2026-05-01 19:59:09.357 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2:  80%|████████  | 8/10 [00:00<00:00, 11.49profile/s]2026-05-01 17:59:09,357 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.465 | (EngineCore pid=176) 2026-05-01 17:59:09,464 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
2026-05-01 19:59:09.465 | (EngineCore pid=176) 
2026-05-01 19:59:09.465 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 10/10 [00:00<00:00, 10.61profile/s]
2026-05-01 19:59:09.465 | [AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 10/10 [00:00<00:00, 11.69profile/s]
2026-05-01 19:59:10.400 | (EngineCore pid=176) 2026-05-01 17:59:10,400 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 19:59:17.273 | (EngineCore pid=176) 
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/51 [00:00<?, ?it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   2%|▏         | 1/51 [00:00<00:06,  8.18it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   4%|▍         | 2/51 [00:00<00:05,  8.61it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   6%|▌         | 3/51 [00:00<00:05,  8.73it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   8%|▊         | 4/51 [00:00<00:05,  8.71it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  10%|▉         | 5/51 [00:00<00:05,  8.69it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  12%|█▏        | 6/51 [00:00<00:05,  8.70it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  14%|█▎        | 7/51 [00:00<00:05,  8.71it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  16%|█▌        | 8/51 [00:00<00:04,  8.74it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  18%|█▊        | 9/51 [00:01<00:04,  8.71it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  20%|█▉        | 10/51 [00:01<00:04,  8.68it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  22%|██▏       | 11/51 [00:01<00:04,  8.70it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  24%|██▎       | 12/51 [00:01<00:04,  8.79it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  25%|██▌       | 13/51 [00:01<00:04,  8.78it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  27%|██▋       | 14/51 [00:01<00:04,  8.86it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  29%|██▉       | 15/51 [00:01<00:04,  8.81it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  31%|███▏      | 16/51 [00:01<00:03,  8.82it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 17/51 [00:01<00:03,  8.75it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  35%|███▌      | 18/51 [00:02<00:03,  8.55it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  37%|███▋      | 19/51 [00:02<00:03,  8.53it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  39%|███▉      | 20/51 [00:02<00:03,  8.48it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  41%|████      | 21/51 [00:02<00:03,  8.52it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  43%|████▎     | 22/51 [00:02<00:03,  8.57it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  45%|████▌     | 23/51 [00:02<00:03,  8.58it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  47%|████▋     | 24/51 [00:02<00:03,  8.56it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  49%|████▉     | 25/51 [00:02<00:03,  8.46it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  51%|█████     | 26/51 [00:03<00:02,  8.41it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  53%|█████▎    | 27/51 [00:03<00:02,  8.40it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  55%|█████▍    | 28/51 [00:03<00:02,  8.28it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  57%|█████▋    | 29/51 [00:03<00:02,  8.32it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  59%|█████▉    | 30/51 [00:03<00:02,  8.27it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  61%|██████    | 31/51 [00:03<00:02,  8.29it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  63%|██████▎   | 32/51 [00:03<00:02,  8.29it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  65%|██████▍   | 33/51 [00:03<00:02,  8.29it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 34/51 [00:03<00:02,  8.35it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  69%|██████▊   | 35/51 [00:04<00:01,  8.37it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  71%|███████   | 36/51 [00:04<00:01,  8.39it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  73%|███████▎  | 37/51 [00:04<00:01,  8.41it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  75%|███████▍  | 38/51 [00:04<00:01,  8.44it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  76%|███████▋  | 39/51 [00:04<00:01,  8.47it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  78%|███████▊  | 40/51 [00:04<00:01,  8.49it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  80%|████████  | 41/51 [00:04<00:01,  7.19it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  82%|████████▏ | 42/51 [00:04<00:01,  7.60it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  84%|████████▍ | 43/51 [00:05<00:01,  7.87it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  86%|████████▋ | 44/51 [00:05<00:00,  8.06it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  88%|████████▊ | 45/51 [00:05<00:00,  8.20it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  90%|█████████ | 46/51 [00:05<00:00,  8.32it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  92%|█████████▏| 47/51 [00:05<00:00,  8.14it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  94%|█████████▍| 48/51 [00:05<00:00,  8.29it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  96%|█████████▌| 49/51 [00:05<00:00,  8.45it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  98%|█████████▊| 50/51 [00:05<00:00,  8.59it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 51/51 [00:06<00:00,  4.27it/s]
2026-05-01 19:59:17.273 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 51/51 [00:06<00:00,  7.93it/s]
2026-05-01 19:59:20.200 | (EngineCore pid=176) 
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/19 [00:00<?, ?it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):   5%|▌         | 1/19 [00:00<00:04,  3.74it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  11%|█         | 2/19 [00:00<00:04,  3.92it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  16%|█▌        | 3/19 [00:00<00:03,  5.01it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  21%|██        | 4/19 [00:00<00:02,  5.65it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  26%|██▋       | 5/19 [00:00<00:02,  6.11it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  32%|███▏      | 6/19 [00:01<00:02,  6.40it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  37%|███▋      | 7/19 [00:01<00:01,  6.73it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  42%|████▏     | 8/19 [00:01<00:01,  6.93it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  47%|████▋     | 9/19 [00:01<00:01,  7.04it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  53%|█████▎    | 10/19 [00:01<00:01,  7.14it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  58%|█████▊    | 11/19 [00:01<00:01,  7.19it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  63%|██████▎   | 12/19 [00:01<00:00,  7.25it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  68%|██████▊   | 13/19 [00:02<00:00,  7.33it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  74%|███████▎  | 14/19 [00:02<00:00,  7.39it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  79%|███████▉  | 15/19 [00:02<00:00,  7.43it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  84%|████████▍ | 16/19 [00:02<00:00,  7.42it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  89%|████████▉ | 17/19 [00:02<00:00,  7.45it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL):  95%|█████████▍| 18/19 [00:02<00:00,  7.52it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 19/19 [00:02<00:00,  5.99it/s]
2026-05-01 19:59:20.200 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 19/19 [00:02<00:00,  6.49it/s]
2026-05-01 19:59:20.540 | (EngineCore pid=176) INFO 05-01 17:59:20 [gpu_model_runner.py:6137] Graph capturing finished in 10 secs, took 1.56 GiB
2026-05-01 19:59:20.540 | (EngineCore pid=176) INFO 05-01 17:59:20 [gpu_worker.py:592] CUDA graph pool memory: 1.56 GiB (actual), 0.48 GiB (estimated), difference: 1.08 GiB (69.0%).
2026-05-01 19:59:20.599 | (EngineCore pid=176) INFO 05-01 17:59:20 [core.py:299] init engine (profile, create kv cache, warmup model) took 38.07 s (compilation: 17.73 s)
2026-05-01 19:59:23.739 | (EngineCore pid=176) INFO 05-01 17:59:23 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 19:59:23.740 | (EngineCore pid=176) INFO 05-01 17:59:23 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 19:59:23.740 | (EngineCore pid=176) INFO 05-01 17:59:23 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 19:59:23.748 | (APIServer pid=1) INFO 05-01 17:59:23 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 19:59:27.598 | (APIServer pid=1) INFO 05-01 17:59:27 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:37] Available routes are:
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 19:59:27.909 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 19:59:27.910 | (APIServer pid=1) INFO 05-01 17:59:27 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 19:59:28.007 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 19:59:28.007 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 19:59:28.259 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-01 19:59:40.576 | (APIServer pid=1) INFO:     172.18.0.1:48046 - "GET /v1/models HTTP/1.1" 200 OK
2026-05-01 20:01:42.162 | (APIServer pid=1) INFO:     172.18.0.1:36938 - "GET /v1/models HTTP/1.1" 200 OK
2026-05-01 20:02:28.989 | (APIServer pid=1) INFO:     172.18.0.1:54386 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:03:08.533 | (APIServer pid=1) INFO 05-01 18:03:08 [loggers.py:271] Engine 000: Avg prompt throughput: 1873.7 tokens/s, Avg generation throughput: 124.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:03:18.534 | (APIServer pid=1) INFO 05-01 18:03:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:03:50.891 | (APIServer pid=1) INFO:     172.18.0.1:40502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:03:52.529 | (APIServer pid=1) INFO:     172.18.0.1:40502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:03:58.611 | (APIServer pid=1) INFO 05-01 18:03:58 [loggers.py:271] Engine 000: Avg prompt throughput: 3976.4 tokens/s, Avg generation throughput: 155.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:04:02.475 | (APIServer pid=1) INFO:     172.18.0.1:40502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:04:04.143 | (APIServer pid=1) INFO:     172.18.0.1:40502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:04:08.611 | (APIServer pid=1) INFO 05-01 18:04:08 [loggers.py:271] Engine 000: Avg prompt throughput: 4421.5 tokens/s, Avg generation throughput: 74.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:04:18.611 | (APIServer pid=1) INFO 05-01 18:04:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:05:17.949 | (APIServer pid=1) INFO:     172.18.0.1:55056 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:05:18.686 | (APIServer pid=1) INFO 05-01 18:05:18 [loggers.py:271] Engine 000: Avg prompt throughput: 2360.4 tokens/s, Avg generation throughput: 2.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.2%, Prefix cache hit rate: 0.0%
2026-05-01 20:05:22.416 | (APIServer pid=1) INFO:     172.18.0.1:55056 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:05:28.718 | (APIServer pid=1) INFO 05-01 18:05:28 [loggers.py:271] Engine 000: Avg prompt throughput: 2538.2 tokens/s, Avg generation throughput: 178.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:05:38.718 | (APIServer pid=1) INFO 05-01 18:05:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:05:58.597 | (APIServer pid=1) INFO:     172.18.0.1:39412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:06:08.774 | (APIServer pid=1) INFO 05-01 18:06:08 [loggers.py:271] Engine 000: Avg prompt throughput: 2644.2 tokens/s, Avg generation throughput: 239.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:06:18.774 | (APIServer pid=1) INFO 05-01 18:06:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 254.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 0.0%
2026-05-01 20:06:28.814 | (APIServer pid=1) INFO 05-01 18:06:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 49.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:06:38.815 | (APIServer pid=1) INFO 05-01 18:06:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:07:30.810 | (APIServer pid=1) INFO:     172.18.0.1:54802 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:07:38.900 | (APIServer pid=1) INFO 05-01 18:07:38 [loggers.py:271] Engine 000: Avg prompt throughput: 2770.9 tokens/s, Avg generation throughput: 187.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 0.0%
2026-05-01 20:07:48.900 | (APIServer pid=1) INFO 05-01 18:07:48 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 210.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:07:58.935 | (APIServer pid=1) INFO 05-01 18:07:58 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:08:21.309 | (APIServer pid=1) INFO:     172.18.0.1:33526 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:08:28.979 | (APIServer pid=1) INFO 05-01 18:08:28 [loggers.py:271] Engine 000: Avg prompt throughput: 2917.3 tokens/s, Avg generation throughput: 169.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 0.0%
2026-05-01 20:08:38.980 | (APIServer pid=1) INFO 05-01 18:08:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 208.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:08:41.713 | (APIServer pid=1) INFO:     172.18.0.1:57692 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:08:48.979 | (APIServer pid=1) INFO 05-01 18:08:48 [loggers.py:271] Engine 000: Avg prompt throughput: 2998.4 tokens/s, Avg generation throughput: 36.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:08:59.020 | (APIServer pid=1) INFO 05-01 18:08:59 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:12:06.688 | (APIServer pid=1) INFO:     172.18.0.1:47262 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:12:34.687 | (APIServer pid=1) INFO:     172.18.0.1:47262 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:12:39.346 | (APIServer pid=1) INFO 05-01 18:12:39 [loggers.py:271] Engine 000: Avg prompt throughput: 3701.8 tokens/s, Avg generation throughput: 26.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:12:49.346 | (APIServer pid=1) INFO 05-01 18:12:49 [loggers.py:271] Engine 000: Avg prompt throughput: 6391.6 tokens/s, Avg generation throughput: 50.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:12:59.406 | (APIServer pid=1) INFO 05-01 18:12:59 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 102.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:09.406 | (APIServer pid=1) INFO 05-01 18:13:09 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 66.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:10.305 | (APIServer pid=1) INFO:     172.18.0.1:36844 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:13:19.407 | (APIServer pid=1) INFO 05-01 18:13:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:29.447 | (APIServer pid=1) INFO 05-01 18:13:29 [loggers.py:271] Engine 000: Avg prompt throughput: 6538.6 tokens/s, Avg generation throughput: 91.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:39.448 | (APIServer pid=1) INFO 05-01 18:13:39 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 48.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:49.448 | (APIServer pid=1) INFO 05-01 18:13:49 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:13:57.667 | (APIServer pid=1) INFO:     172.18.0.1:47632 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:14:09.496 | (APIServer pid=1) INFO 05-01 18:14:09 [loggers.py:271] Engine 000: Avg prompt throughput: 6669.9 tokens/s, Avg generation throughput: 9.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:14:19.496 | (APIServer pid=1) INFO 05-01 18:14:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 86.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.8%, Prefix cache hit rate: 0.0%
2026-05-01 20:14:22.218 | (APIServer pid=1) INFO:     172.18.0.1:47632 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:14:29.547 | (APIServer pid=1) INFO 05-01 18:14:29 [loggers.py:271] Engine 000: Avg prompt throughput: 6826.7 tokens/s, Avg generation throughput: 32.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.8%, Prefix cache hit rate: 0.0%
2026-05-01 20:14:39.548 | (APIServer pid=1) INFO 05-01 18:14:39 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 95.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:14:49.547 | (APIServer pid=1) INFO 05-01 18:14:49 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:16:50.019 | (APIServer pid=1) INFO:     172.18.0.1:33064 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:17:09.804 | (APIServer pid=1) INFO 05-01 18:17:09 [loggers.py:271] Engine 000: Avg prompt throughput: 6965.7 tokens/s, Avg generation throughput: 48.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.8%, Prefix cache hit rate: 0.0%
2026-05-01 20:17:19.805 | (APIServer pid=1) INFO 05-01 18:17:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 92.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.1%, Prefix cache hit rate: 0.0%
2026-05-01 20:17:29.847 | (APIServer pid=1) INFO 05-01 18:17:29 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 49.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:17:30.424 | (APIServer pid=1) INFO:     172.18.0.1:48342 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:17:39.848 | (APIServer pid=1) INFO 05-01 18:17:39 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:17:49.849 | (APIServer pid=1) INFO 05-01 18:17:49 [loggers.py:271] Engine 000: Avg prompt throughput: 7086.3 tokens/s, Avg generation throughput: 36.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.1%, Prefix cache hit rate: 0.0%
2026-05-01 20:17:59.906 | (APIServer pid=1) INFO 05-01 18:17:59 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 87.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.1%, Prefix cache hit rate: 0.0%
2026-05-01 20:18:06.542 | (APIServer pid=1) INFO:     172.18.0.1:48342 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:18:09.906 | (APIServer pid=1) INFO 05-01 18:18:09 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:18:19.907 | (APIServer pid=1) INFO 05-01 18:18:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.5%, Prefix cache hit rate: 0.0%
2026-05-01 20:18:39.959 | (APIServer pid=1) INFO 05-01 18:18:39 [loggers.py:271] Engine 000: Avg prompt throughput: 9948.6 tokens/s, Avg generation throughput: 22.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:18:49.959 | (APIServer pid=1) INFO 05-01 18:18:49 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 83.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.4%, Prefix cache hit rate: 0.0%
2026-05-01 20:19:00.019 | (APIServer pid=1) INFO 05-01 18:19:00 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 83.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.4%, Prefix cache hit rate: 0.0%
2026-05-01 20:19:06.165 | (APIServer pid=1) INFO:     172.18.0.1:42582 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 20:19:10.020 | (APIServer pid=1) INFO 05-01 18:19:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 18.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:19:20.021 | (APIServer pid=1) INFO 05-01 18:19:20 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:21:00.212 | (APIServer pid=1) INFO 05-01 18:21:00 [loggers.py:271] Engine 000: Avg prompt throughput: 10066.1 tokens/s, Avg generation throughput: 29.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.4%, Prefix cache hit rate: 0.0%
2026-05-01 20:21:10.213 | (APIServer pid=1) INFO 05-01 18:21:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 20:21:20.213 | (APIServer pid=1) INFO 05-01 18:21:20 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%