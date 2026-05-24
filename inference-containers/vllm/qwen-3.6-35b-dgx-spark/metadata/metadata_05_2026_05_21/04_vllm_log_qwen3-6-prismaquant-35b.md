# docker compose
```yml
services:
  prismaquant-35b:
    image: vllm/vllm-openai:v0.20.2-ubuntu2404
    container_name: qwen3-6-prismaquant-35b
    hostname: inference-server
    platform: linux/arm64
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
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      VLLM_MARLIN_USE_ATOMIC_ADD: "1"
      VLLM_HTTP_TIMEOUT_KEEP_ALIVE: "600"
      FLASHINFER_DISABLE_VERSION_CHECK: "1"

    command:
      - "--model"
      - "rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-35b}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"

      # --- MEMORY & CONTEXT ---
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "10"

      # --- BATCHING / PREFILL ---
      - "--max-num-batched-tokens"
      - "32768"

      # --- QUANTIZATION & ATTN ---
      - "--kv-cache-dtype"
      - "fp8"
      - "--quantization"
      - "compressed-tensors"
      - "--attention-backend"
      - "flashinfer"
      - "--dtype"
      - "auto"

      # --- PARSERS & TOOLS ---
      - "--reasoning-parser"
      - "qwen3"
      - "--enable-auto-tool-choice"
      - "--tool-call-parser"
      - "qwen3_coder"

      # --- CACHING & PREFILL ---
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # --- MTP SPECULATIVE DECODING (n=3 — measured optimum) ---
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":3}'

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log
```log
WARNING 05-21 21:02:50 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299] 
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.2
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299]   █▄█▀ █     █     █     █  model   rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:299] 
(APIServer pid=1) INFO 05-21 21:02:50 [utils.py:233] non-default args: {'model_tag': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'compressed-tensors', 'served_model_name': ['qwen3.6-35b'], 'attention_backend': 'flashinfer', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 10, 'enable_chunked_prefill': True, 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 3}}
(APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(APIServer pid=1) INFO 05-21 21:02:57 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
(APIServer pid=1) INFO 05-21 21:02:57 [nixl_utils.py:32] NIXL is available
(APIServer pid=1) INFO 05-21 21:02:57 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-21 21:02:57 [model.py:1680] Using max model len 262144
(APIServer pid=1) INFO 05-21 21:02:58 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 05-21 21:03:02 [model.py:555] Resolved architecture: Qwen3_5MoeMTP
(APIServer pid=1) INFO 05-21 21:03:02 [model.py:1680] Using max model len 262144
(APIServer pid=1) WARNING 05-21 21:03:02 [speculative.py:602] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
(APIServer pid=1) INFO 05-21 21:03:02 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
(APIServer pid=1) WARNING 05-21 21:03:02 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-21 21:03:02 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-21 21:03:02 [vllm.py:840] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-21 21:03:02 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
INFO 05-21 21:03:19 [nixl_utils.py:32] NIXL is available
(EngineCore pid=199) INFO 05-21 21:03:20 [core.py:109] Initializing a V1 LLM engine (v0.20.2) with config: model='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', speculative_config=SpeculativeConfig(method='mtp', model='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', num_spec_tokens=3), tokenizer='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-35b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 80, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto')
(EngineCore pid=199) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=199) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(EngineCore pid=199) INFO 05-21 21:03:22 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:57327 backend=nccl
(EngineCore pid=199) INFO 05-21 21:03:22 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=199) WARNING 05-21 21:03:22 [__init__.py:206] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=199) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=199) INFO 05-21 21:03:31 [gpu_model_runner.py:4777] Starting to load model rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm...
(EngineCore pid=199) INFO 05-21 21:03:31 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=199) INFO 05-21 21:03:31 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=199) INFO 05-21 21:03:31 [__init__.py:560] Using FlashInferCutlassMxfp8LinearKernel for MXFP8 GEMM
(EngineCore pid=199) INFO 05-21 21:03:31 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=199) INFO 05-21 21:03:31 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
(EngineCore pid=199) INFO 05-21 21:03:32 [nvfp4.py:280] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=199) INFO 05-21 21:03:32 [cuda.py:308] Using AttentionBackendEnum.FLASHINFER backend.
(EngineCore pid=199) INFO 05-21 21:04:54 [weight_utils.py:615] Time spent downloading weights for rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm: 78.967547 seconds
(EngineCore pid=199) INFO 05-21 21:04:54 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.31 GiB. Available RAM: 87.59 GiB.
(EngineCore pid=199) INFO 05-21 21:04:54 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
(EngineCore pid=199) 
Loading safetensors checkpoint shards:   0% Completed | 0/6 [00:00<?, ?it/s]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  17% Completed | 1/6 [00:34<02:54, 34.81s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  33% Completed | 2/6 [01:10<02:21, 35.34s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  50% Completed | 3/6 [01:46<01:46, 35.41s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  67% Completed | 4/6 [02:20<01:10, 35.09s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  83% Completed | 5/6 [02:50<00:33, 33.31s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards: 100% Completed | 6/6 [02:50<00:00, 28.46s/it]
(EngineCore pid=199) 
(EngineCore pid=199) INFO 05-21 21:07:45 [default_loader.py:384] Loading weights took 170.92 seconds
(EngineCore pid=199) INFO 05-21 21:07:45 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=199) WARNING 05-21 21:07:45 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
(EngineCore pid=199) INFO 05-21 21:07:45 [gpu_model_runner.py:4801] Loading drafter model...
(EngineCore pid=199) INFO 05-21 21:07:46 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.31 GiB. Available RAM: 86.27 GiB.
(EngineCore pid=199) 
Loading safetensors checkpoint shards:   0% Completed | 0/6 [00:00<?, ?it/s]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  17% Completed | 1/6 [00:16<01:24, 16.82s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  33% Completed | 2/6 [00:17<00:28,  7.04s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  50% Completed | 3/6 [00:17<00:11,  3.92s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  67% Completed | 4/6 [00:17<00:04,  2.44s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards:  83% Completed | 5/6 [00:21<00:03,  3.08s/it]
(EngineCore pid=199) 
Loading safetensors checkpoint shards: 100% Completed | 6/6 [00:21<00:00,  3.61s/it]
(EngineCore pid=199) 
(EngineCore pid=199) INFO 05-21 21:08:08 [default_loader.py:384] Loading weights took 21.64 seconds
(EngineCore pid=199) INFO 05-21 21:08:08 [llm_base_proposer.py:1445] Detected MTP model. Sharing target model embedding weights with the draft model.
(EngineCore pid=199) INFO 05-21 21:08:08 [llm_base_proposer.py:1501] Detected MTP model. Sharing target model lm_head weights with the draft model.
(EngineCore pid=199) INFO 05-21 21:08:08 [gpu_model_runner.py:4879] Model loading took 21.42 GiB memory and 276.698589 seconds
(EngineCore pid=199) INFO 05-21 21:08:08 [interface.py:606] Setting attention block size to 2144 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=199) INFO 05-21 21:08:08 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
(EngineCore pid=199) INFO 05-21 21:08:22 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/cb4d827ebf/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=199) INFO 05-21 21:08:22 [backends.py:1128] Dynamo bytecode transform time: 6.27 s
(EngineCore pid=199) [rank0]:W0521 21:08:35.966000 199 site-packages/torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=199) INFO 05-21 21:08:37 [backends.py:376] Cache the graph of compile range (1, 32768) for later use
(EngineCore pid=199) INFO 05-21 21:09:10 [backends.py:391] Compiling a graph for compile range (1, 32768) takes 48.32 s
(EngineCore pid=199) INFO 05-21 21:09:12 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/d1888e361f698a962bfeae11657a6ca1c011557809ef484d9652f14cf26db623/rank_0_0/model
(EngineCore pid=199) INFO 05-21 21:09:12 [monitor.py:53] torch.compile took 56.45 s in total
(EngineCore pid=199) INFO 05-21 21:09:57 [monitor.py:81] Initial profiling/warmup run took 44.69 s
(EngineCore pid=199) INFO 05-21 21:09:57 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/cb4d827ebf/rank_0_0/eagle_head for vLLM's torch.compile
(EngineCore pid=199) INFO 05-21 21:09:57 [backends.py:1128] Dynamo bytecode transform time: 0.36 s
(EngineCore pid=199) INFO 05-21 21:10:04 [backends.py:391] Compiling a graph for compile range (1, 32768) takes 7.06 s
(EngineCore pid=199) INFO 05-21 21:10:04 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/d4e3af856b070cc2a7f8bb16aa8b8b8944c9f837218e97861b89011b5f5d1df8/rank_0_0/model
(EngineCore pid=199) INFO 05-21 21:10:04 [monitor.py:53] torch.compile took 7.56 s in total
(EngineCore pid=199) INFO 05-21 21:10:05 [monitor.py:81] Initial profiling/warmup run took 1.03 s
(EngineCore pid=199) WARNING 05-21 21:10:10 [kv_cache_utils.py:1152] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=199) WARNING 05-21 21:10:10 [compilation.py:1390] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for attention backend FlashInferBackend (support: AttentionCGSupport.UNIFORM_SINGLE_TOKEN_DECODE); setting cudagraph_mode=PIECEWISE
(EngineCore pid=199) INFO 05-21 21:10:10 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=13 (largest=80)
(EngineCore pid=199) INFO 05-21 21:10:11 [gpu_model_runner.py:6042] Estimated CUDA graph memory: -0.17 GiB total
(EngineCore pid=199) INFO 05-21 21:10:12 [gpu_worker.py:440] Available KV cache memory: 64.69 GiB
(EngineCore pid=199) WARNING 05-21 21:10:12 [kv_cache_utils.py:1152] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=199) INFO 05-21 21:10:12 [kv_cache_utils.py:1708] GPU KV cache size: 5,463,232 tokens
(EngineCore pid=199) INFO 05-21 21:10:12 [kv_cache_utils.py:1709] Maximum concurrency for 262,144 tokens per request: 20.84x
(EngineCore pid=199) 2026-05-21 21:10:15,615 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(EngineCore pid=199) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  50%|█████     | 8/16 [00:00<00:00, 78.46profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:02<00:00,  4.67profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:02<00:00,  5.44profile/s]
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm1:   0%|          | 0/7 [00:00<?, ?profile/s]2026-05-21 21:10:18,688 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:18,715 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:18,752 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm1:  43%|████▎     | 3/7 [00:00<00:00, 25.19profile/s]2026-05-21 21:10:18,804 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:18,881 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:18,993 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm1:  86%|████████▌ | 6/7 [00:00<00:00, 15.72profile/s]2026-05-21 21:10:19,139 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 7/7 [00:00<00:00, 13.82profile/s]
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm2:   0%|          | 0/7 [00:00<?, ?profile/s]2026-05-21 21:10:19,187 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:19,232 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:19,286 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm2:  43%|████▎     | 3/7 [00:00<00:00, 20.72profile/s]2026-05-21 21:10:19,355 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:19,448 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:19,573 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm2:  86%|████████▌ | 6/7 [00:00<00:00, 13.13profile/s]2026-05-21 21:10:19,728 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 7/7 [00:00<00:00, 11.92profile/s]
(EngineCore pid=199) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  38%|███▊      | 6/16 [00:00<00:00, 58.92profile/s]
[AutoTuner]: Tuning fp4_gemm:  88%|████████▊ | 14/16 [00:00<00:00, 57.59profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 16/16 [00:00<00:00, 26.02profile/s]
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]2026-05-21 21:10:21,484 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm:   6%|▋         | 1/16 [00:00<00:06,  2.24profile/s]2026-05-21 21:10:21,487 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,489 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,492 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,495 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,497 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,500 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,503 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,506 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,511 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,519 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,533 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,559 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:21,610 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm:  88%|████████▊ | 14/16 [00:00<00:00, 31.20profile/s]2026-05-21 21:10:21,852 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,337 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 16/16 [00:01<00:00, 12.30profile/s]
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/16 [00:00<?, ?profile/s]2026-05-21 21:10:22,954 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm:   6%|▋         | 1/16 [00:00<00:08,  1.76profile/s]2026-05-21 21:10:22,956 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,958 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,959 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,961 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,963 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,964 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,966 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,968 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,970 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,973 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,979 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:22,989 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:23,007 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:23,041 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 2026-05-21 21:10:23,108 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 2 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=199) 
[AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 16/16 [00:00<00:00, 28.48profile/s]
[AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 16/16 [00:00<00:00, 22.18profile/s]
(EngineCore pid=199) 2026-05-21 21:10:26,853 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
(EngineCore pid=199) 
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/13 [00:00<?, ?it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   8%|▊         | 1/13 [00:00<00:01,  8.21it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  23%|██▎       | 3/13 [00:00<00:00, 12.69it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  38%|███▊      | 5/13 [00:00<00:00, 14.18it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  54%|█████▍    | 7/13 [00:00<00:00, 14.76it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  69%|██████▉   | 9/13 [00:00<00:00, 15.30it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  85%|████████▍ | 11/13 [00:00<00:00, 15.93it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 13/13 [00:01<00:00,  9.29it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 13/13 [00:01<00:00, 11.44it/s]
(EngineCore pid=199) INFO 05-21 21:10:29 [gpu_model_runner.py:6133] Graph capturing finished in 2 secs, took 0.37 GiB
(EngineCore pid=199) INFO 05-21 21:10:29 [core.py:299] init engine (profile, create kv cache, warmup model) took 140.49 s (compilation: 64.01 s)
(EngineCore pid=199) INFO 05-21 21:10:29 [vllm.py:840] Asynchronous scheduling is enabled.
(EngineCore pid=199) INFO 05-21 21:10:29 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(APIServer pid=1) INFO 05-21 21:10:29 [api_server.py:598] Supported tasks: ['generate']
(APIServer pid=1) INFO 05-21 21:10:29 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 05-21 21:10:29 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-21 21:10:33 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-21 21:10:39 [base.py:233] Multi-modal warmup completed in 6.228s
(APIServer pid=1) INFO 05-21 21:10:45 [base.py:233] Readonly multi-modal warmup completed in 6.077s
(APIServer pid=1) INFO 05-21 21:10:46 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-21 21:10:46 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.3:51856 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46874 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:11:56 [loggers.py:271] Engine 000: Avg prompt throughput: 1503.9 tokens/s, Avg generation throughput: 50.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-21 21:11:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.03, Accepted throughput: 3.87 tokens/s, Drafted throughput: 5.72 tokens/s, Accepted: 337 tokens, Drafted: 498 tokens, Per-position acceptance rate: 0.837, 0.669, 0.524, Avg Draft acceptance rate: 67.7%
(APIServer pid=1) INFO 05-21 21:12:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.3:59734 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:33672 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:14:46 [loggers.py:271] Engine 000: Avg prompt throughput: 786.1 tokens/s, Avg generation throughput: 22.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.7%, Prefix cache hit rate: 52.9%
(APIServer pid=1) INFO 05-21 21:14:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.36, Accepted throughput: 0.92 tokens/s, Drafted throughput: 1.16 tokens/s, Accepted: 156 tokens, Drafted: 198 tokens, Per-position acceptance rate: 0.924, 0.788, 0.652, Avg Draft acceptance rate: 78.8%
(APIServer pid=1) INFO:     172.18.0.3:33682 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:33690 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:14:56 [loggers.py:271] Engine 000: Avg prompt throughput: 1110.3 tokens/s, Avg generation throughput: 46.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 62.1%
(APIServer pid=1) INFO 05-21 21:14:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.79, Accepted throughput: 34.89 tokens/s, Drafted throughput: 37.49 tokens/s, Accepted: 349 tokens, Drafted: 375 tokens, Per-position acceptance rate: 0.968, 0.936, 0.888, Avg Draft acceptance rate: 93.1%
(APIServer pid=1) INFO:     172.18.0.3:40706 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40714 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:15:06 [loggers.py:271] Engine 000: Avg prompt throughput: 1219.4 tokens/s, Avg generation throughput: 48.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 71.5%
(APIServer pid=1) INFO 05-21 21:15:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.26, Accepted throughput: 33.89 tokens/s, Drafted throughput: 44.99 tokens/s, Accepted: 339 tokens, Drafted: 450 tokens, Per-position acceptance rate: 0.827, 0.753, 0.680, Avg Draft acceptance rate: 75.3%
(APIServer pid=1) INFO 05-21 21:15:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 71.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 71.5%
(APIServer pid=1) INFO 05-21 21:15:16 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.35, Accepted throughput: 49.80 tokens/s, Drafted throughput: 63.59 tokens/s, Accepted: 498 tokens, Drafted: 636 tokens, Per-position acceptance rate: 0.892, 0.797, 0.660, Avg Draft acceptance rate: 78.3%
(APIServer pid=1) INFO 05-21 21:15:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 60.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 71.5%
(APIServer pid=1) INFO 05-21 21:15:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.89, Accepted throughput: 39.80 tokens/s, Drafted throughput: 63.30 tokens/s, Accepted: 398 tokens, Drafted: 633 tokens, Per-position acceptance rate: 0.777, 0.635, 0.474, Avg Draft acceptance rate: 62.9%
(APIServer pid=1) INFO:     172.18.0.3:54100 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49202 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:15:36 [loggers.py:271] Engine 000: Avg prompt throughput: 806.0 tokens/s, Avg generation throughput: 40.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 74.8%
(APIServer pid=1) INFO 05-21 21:15:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.51, Accepted throughput: 29.10 tokens/s, Drafted throughput: 34.79 tokens/s, Accepted: 291 tokens, Drafted: 348 tokens, Per-position acceptance rate: 0.931, 0.828, 0.750, Avg Draft acceptance rate: 83.6%
(APIServer pid=1) INFO:     172.18.0.3:49206 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41876 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:15:46 [loggers.py:271] Engine 000: Avg prompt throughput: 855.5 tokens/s, Avg generation throughput: 49.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 77.0%
(APIServer pid=1) INFO 05-21 21:15:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.33, Accepted throughput: 34.70 tokens/s, Drafted throughput: 44.70 tokens/s, Accepted: 347 tokens, Drafted: 447 tokens, Per-position acceptance rate: 0.859, 0.758, 0.711, Avg Draft acceptance rate: 77.6%
(APIServer pid=1) INFO:     172.18.0.3:41882 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:55196 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:15:56 [loggers.py:271] Engine 000: Avg prompt throughput: 977.8 tokens/s, Avg generation throughput: 50.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 78.4%
(APIServer pid=1) INFO 05-21 21:15:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.63, Accepted throughput: 36.30 tokens/s, Drafted throughput: 41.40 tokens/s, Accepted: 363 tokens, Drafted: 414 tokens, Per-position acceptance rate: 0.935, 0.870, 0.826, Avg Draft acceptance rate: 87.7%
(APIServer pid=1) INFO 05-21 21:16:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 68.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 78.4%
(APIServer pid=1) INFO 05-21 21:16:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.26, Accepted throughput: 47.30 tokens/s, Drafted throughput: 62.70 tokens/s, Accepted: 473 tokens, Drafted: 627 tokens, Per-position acceptance rate: 0.885, 0.746, 0.632, Avg Draft acceptance rate: 75.4%
(APIServer pid=1) INFO 05-21 21:16:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 65.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 78.4%
(APIServer pid=1) INFO 05-21 21:16:16 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.16, Accepted throughput: 44.90 tokens/s, Drafted throughput: 62.40 tokens/s, Accepted: 449 tokens, Drafted: 624 tokens, Per-position acceptance rate: 0.837, 0.712, 0.611, Avg Draft acceptance rate: 72.0%
(APIServer pid=1) INFO 05-21 21:16:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 43.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 78.4%
(APIServer pid=1) INFO 05-21 21:16:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 28.70 tokens/s, Drafted throughput: 45.30 tokens/s, Accepted: 287 tokens, Drafted: 453 tokens, Per-position acceptance rate: 0.755, 0.623, 0.523, Avg Draft acceptance rate: 63.4%
(APIServer pid=1) INFO 05-21 21:16:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 78.4%
(APIServer pid=1) INFO:     172.18.0.3:42952 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:19:26 [loggers.py:271] Engine 000: Avg prompt throughput: 507.2 tokens/s, Avg generation throughput: 25.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 79.1%
(APIServer pid=1) INFO 05-21 21:19:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 0.94 tokens/s, Drafted throughput: 1.48 tokens/s, Accepted: 169 tokens, Drafted: 267 tokens, Per-position acceptance rate: 0.809, 0.607, 0.483, Avg Draft acceptance rate: 63.3%
(APIServer pid=1) INFO 05-21 21:19:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 8.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.1%
(APIServer pid=1) INFO 05-21 21:19:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 5.00 tokens/s, Drafted throughput: 10.50 tokens/s, Accepted: 50 tokens, Drafted: 105 tokens, Per-position acceptance rate: 0.743, 0.400, 0.286, Avg Draft acceptance rate: 47.6%
(APIServer pid=1) INFO 05-21 21:19:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.1%
(APIServer pid=1) INFO:     172.18.0.3:35838 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:20:56 [loggers.py:271] Engine 000: Avg prompt throughput: 411.0 tokens/s, Avg generation throughput: 41.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 79.9%
(APIServer pid=1) INFO 05-21 21:20:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.66, Accepted throughput: 3.24 tokens/s, Drafted throughput: 5.85 tokens/s, Accepted: 259 tokens, Drafted: 468 tokens, Per-position acceptance rate: 0.750, 0.538, 0.372, Avg Draft acceptance rate: 55.3%
(APIServer pid=1) INFO 05-21 21:21:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.9%
(APIServer pid=1) INFO 05-21 21:21:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 11.70 tokens/s, Drafted throughput: 23.40 tokens/s, Accepted: 117 tokens, Drafted: 234 tokens, Per-position acceptance rate: 0.718, 0.487, 0.295, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO 05-21 21:21:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.9%
(APIServer pid=1) INFO:     172.18.0.3:36876 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:35040 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:26:36 [loggers.py:271] Engine 000: Avg prompt throughput: 997.4 tokens/s, Avg generation throughput: 25.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 81.0%
(APIServer pid=1) INFO 05-21 21:26:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.23, Accepted throughput: 0.53 tokens/s, Drafted throughput: 0.72 tokens/s, Accepted: 176 tokens, Drafted: 237 tokens, Per-position acceptance rate: 0.835, 0.734, 0.658, Avg Draft acceptance rate: 74.3%
(APIServer pid=1) INFO:     172.18.0.3:35052 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:35000 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:26:46 [loggers.py:271] Engine 000: Avg prompt throughput: 760.7 tokens/s, Avg generation throughput: 44.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 82.4%
(APIServer pid=1) INFO 05-21 21:26:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.70, Accepted throughput: 32.70 tokens/s, Drafted throughput: 36.30 tokens/s, Accepted: 327 tokens, Drafted: 363 tokens, Per-position acceptance rate: 0.934, 0.893, 0.876, Avg Draft acceptance rate: 90.1%
(APIServer pid=1) INFO 05-21 21:26:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 82.4%
(APIServer pid=1) INFO 05-21 21:26:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.34, Accepted throughput: 25.30 tokens/s, Drafted throughput: 32.40 tokens/s, Accepted: 253 tokens, Drafted: 324 tokens, Per-position acceptance rate: 0.898, 0.759, 0.685, Avg Draft acceptance rate: 78.1%
(APIServer pid=1) INFO 05-21 21:27:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 82.4%
(APIServer pid=1) INFO:     172.18.0.3:37878 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:28:26 [loggers.py:271] Engine 000: Avg prompt throughput: 283.5 tokens/s, Avg generation throughput: 22.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.1%
(APIServer pid=1) INFO 05-21 21:28:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.74, Accepted throughput: 1.86 tokens/s, Drafted throughput: 2.03 tokens/s, Accepted: 167 tokens, Drafted: 183 tokens, Per-position acceptance rate: 0.967, 0.902, 0.869, Avg Draft acceptance rate: 91.3%
(APIServer pid=1) INFO:     172.18.0.3:44104 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:59564 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:28:36 [loggers.py:271] Engine 000: Avg prompt throughput: 722.7 tokens/s, Avg generation throughput: 31.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO 05-21 21:28:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.37, Accepted throughput: 22.30 tokens/s, Drafted throughput: 28.20 tokens/s, Accepted: 223 tokens, Drafted: 282 tokens, Per-position acceptance rate: 0.851, 0.787, 0.734, Avg Draft acceptance rate: 79.1%
(APIServer pid=1) INFO 05-21 21:28:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 30.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO 05-21 21:28:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.55, Accepted throughput: 21.90 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 219 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.942, 0.814, 0.791, Avg Draft acceptance rate: 84.9%
(APIServer pid=1) INFO 05-21 21:28:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO:     172.18.0.3:56984 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:32:26 [loggers.py:271] Engine 000: Avg prompt throughput: 716.2 tokens/s, Avg generation throughput: 54.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO 05-21 21:32:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.18, Accepted throughput: 1.69 tokens/s, Drafted throughput: 2.32 tokens/s, Accepted: 371 tokens, Drafted: 510 tokens, Per-position acceptance rate: 0.876, 0.706, 0.600, Avg Draft acceptance rate: 72.7%
(APIServer pid=1) INFO 05-21 21:32:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO 05-21 21:32:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 4.00, Accepted throughput: 0.30 tokens/s, Drafted throughput: 0.30 tokens/s, Accepted: 3 tokens, Drafted: 3 tokens, Per-position acceptance rate: 1.000, 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-21 21:32:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.2%
(APIServer pid=1) INFO:     172.18.0.3:55300 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:55316 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:55328 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:38:16 [loggers.py:271] Engine 000: Avg prompt throughput: 1235.2 tokens/s, Avg generation throughput: 45.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.4%
(APIServer pid=1) INFO 05-21 21:38:16 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.69, Accepted throughput: 0.98 tokens/s, Drafted throughput: 1.09 tokens/s, Accepted: 333 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.927, 0.887, 0.871, Avg Draft acceptance rate: 89.5%
(APIServer pid=1) INFO:     172.18.0.3:48774 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:38:26 [loggers.py:271] Engine 000: Avg prompt throughput: 2607.0 tokens/s, Avg generation throughput: 6.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 83.8%
(APIServer pid=1) INFO 05-21 21:38:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.77, Accepted throughput: 3.90 tokens/s, Drafted throughput: 6.60 tokens/s, Accepted: 39 tokens, Drafted: 66 tokens, Per-position acceptance rate: 0.818, 0.545, 0.409, Avg Draft acceptance rate: 59.1%
(APIServer pid=1) INFO 05-21 21:38:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 67.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 83.8%
(APIServer pid=1) INFO 05-21 21:38:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.44, Accepted throughput: 47.99 tokens/s, Drafted throughput: 59.09 tokens/s, Accepted: 480 tokens, Drafted: 591 tokens, Per-position acceptance rate: 0.929, 0.802, 0.706, Avg Draft acceptance rate: 81.2%
(APIServer pid=1) INFO 05-21 21:38:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 61.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 83.8%
(APIServer pid=1) INFO 05-21 21:38:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.12, Accepted throughput: 41.80 tokens/s, Drafted throughput: 59.09 tokens/s, Accepted: 418 tokens, Drafted: 591 tokens, Per-position acceptance rate: 0.843, 0.701, 0.579, Avg Draft acceptance rate: 70.7%
(APIServer pid=1) INFO 05-21 21:38:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.8%
(APIServer pid=1) INFO 05-21 21:38:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 25.50 tokens/s, Drafted throughput: 42.90 tokens/s, Accepted: 255 tokens, Drafted: 429 tokens, Per-position acceptance rate: 0.783, 0.573, 0.427, Avg Draft acceptance rate: 59.4%
(APIServer pid=1) INFO 05-21 21:39:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.8%
(APIServer pid=1) INFO:     172.18.0.3:50782 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50784 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:40:36 [loggers.py:271] Engine 000: Avg prompt throughput: 747.1 tokens/s, Avg generation throughput: 10.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.3%
(APIServer pid=1) INFO 05-21 21:40:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 0.61 tokens/s, Drafted throughput: 1.11 tokens/s, Accepted: 61 tokens, Drafted: 111 tokens, Per-position acceptance rate: 0.838, 0.486, 0.324, Avg Draft acceptance rate: 55.0%
(APIServer pid=1) INFO 05-21 21:40:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.3%
(APIServer pid=1) INFO:     172.18.0.3:42878 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:43:36 [loggers.py:271] Engine 000: Avg prompt throughput: 589.1 tokens/s, Avg generation throughput: 35.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 85.8%
(APIServer pid=1) INFO 05-21 21:43:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.50, Accepted throughput: 1.41 tokens/s, Drafted throughput: 1.68 tokens/s, Accepted: 253 tokens, Drafted: 303 tokens, Per-position acceptance rate: 0.931, 0.822, 0.752, Avg Draft acceptance rate: 83.5%
(APIServer pid=1) INFO 05-21 21:43:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 75.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 85.8%
(APIServer pid=1) INFO 05-21 21:43:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.90, Accepted throughput: 56.29 tokens/s, Drafted throughput: 58.19 tokens/s, Accepted: 563 tokens, Drafted: 582 tokens, Per-position acceptance rate: 1.000, 0.969, 0.933, Avg Draft acceptance rate: 96.7%
(APIServer pid=1) INFO 05-21 21:43:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 67.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 85.8%
(APIServer pid=1) INFO 05-21 21:43:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.39, Accepted throughput: 47.39 tokens/s, Drafted throughput: 59.39 tokens/s, Accepted: 474 tokens, Drafted: 594 tokens, Per-position acceptance rate: 0.899, 0.788, 0.707, Avg Draft acceptance rate: 79.8%
(APIServer pid=1) INFO:     172.18.0.3:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:44:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 29.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.8%
(APIServer pid=1) INFO 05-21 21:44:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.55, Accepted throughput: 21.20 tokens/s, Drafted throughput: 24.90 tokens/s, Accepted: 212 tokens, Drafted: 249 tokens, Per-position acceptance rate: 0.928, 0.867, 0.759, Avg Draft acceptance rate: 85.1%
(APIServer pid=1) INFO:     172.18.0.3:46186 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:44:16 [loggers.py:271] Engine 000: Avg prompt throughput: 1402.2 tokens/s, Avg generation throughput: 36.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 86.5%
(APIServer pid=1) INFO 05-21 21:44:16 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.57, Accepted throughput: 26.19 tokens/s, Drafted throughput: 30.59 tokens/s, Accepted: 262 tokens, Drafted: 306 tokens, Per-position acceptance rate: 0.941, 0.853, 0.775, Avg Draft acceptance rate: 85.6%
(APIServer pid=1) INFO:     172.18.0.3:50370 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:44:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 67.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 86.5%
(APIServer pid=1) INFO 05-21 21:44:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.47, Accepted throughput: 47.69 tokens/s, Drafted throughput: 57.89 tokens/s, Accepted: 477 tokens, Drafted: 579 tokens, Per-position acceptance rate: 0.912, 0.824, 0.736, Avg Draft acceptance rate: 82.4%
(APIServer pid=1) INFO:     172.18.0.3:42440 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:44:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 33.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.5%
(APIServer pid=1) INFO 05-21 21:44:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.86, Accepted throughput: 24.60 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 246 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.965, 0.953, 0.942, Avg Draft acceptance rate: 95.3%
(APIServer pid=1) INFO 05-21 21:44:46 [loggers.py:271] Engine 000: Avg prompt throughput: 723.0 tokens/s, Avg generation throughput: 47.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.8%
(APIServer pid=1) INFO 05-21 21:44:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.50, Accepted throughput: 34.20 tokens/s, Drafted throughput: 41.10 tokens/s, Accepted: 342 tokens, Drafted: 411 tokens, Per-position acceptance rate: 0.920, 0.832, 0.745, Avg Draft acceptance rate: 83.2%
(APIServer pid=1) INFO 05-21 21:44:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.8%
(APIServer pid=1) INFO:     172.18.0.3:56850 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49800 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:55596 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:45:26 [loggers.py:271] Engine 000: Avg prompt throughput: 5811.4 tokens/s, Avg generation throughput: 20.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 84.9%
(APIServer pid=1) INFO 05-21 21:45:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.43, Accepted throughput: 3.65 tokens/s, Drafted throughput: 4.50 tokens/s, Accepted: 146 tokens, Drafted: 180 tokens, Per-position acceptance rate: 0.900, 0.817, 0.717, Avg Draft acceptance rate: 81.1%
(APIServer pid=1) INFO:     172.18.0.3:55608 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:45:36 [loggers.py:271] Engine 000: Avg prompt throughput: 492.3 tokens/s, Avg generation throughput: 27.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.2%
(APIServer pid=1) INFO 05-21 21:45:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.27, Accepted throughput: 19.50 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 195 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.814, 0.744, 0.709, Avg Draft acceptance rate: 75.6%
(APIServer pid=1) INFO 05-21 21:45:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.2%
(APIServer pid=1) INFO:     172.18.0.3:59562 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:33026 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:46:56 [loggers.py:271] Engine 000: Avg prompt throughput: 752.5 tokens/s, Avg generation throughput: 11.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 85.9%
(APIServer pid=1) INFO 05-21 21:46:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.56, Accepted throughput: 1.02 tokens/s, Drafted throughput: 1.20 tokens/s, Accepted: 82 tokens, Drafted: 96 tokens, Per-position acceptance rate: 0.906, 0.844, 0.812, Avg Draft acceptance rate: 85.4%
(APIServer pid=1) INFO 05-21 21:47:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.9%
(APIServer pid=1) INFO 05-21 21:47:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.72, Accepted throughput: 14.40 tokens/s, Drafted throughput: 15.90 tokens/s, Accepted: 144 tokens, Drafted: 159 tokens, Per-position acceptance rate: 0.962, 0.906, 0.849, Avg Draft acceptance rate: 90.6%
(APIServer pid=1) INFO 05-21 21:47:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.9%
(APIServer pid=1) INFO:     172.18.0.3:44846 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:44860 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:49:26 [loggers.py:271] Engine 000: Avg prompt throughput: 1077.1 tokens/s, Avg generation throughput: 34.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 86.3%
(APIServer pid=1) INFO 05-21 21:49:26 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.25, Accepted throughput: 1.72 tokens/s, Drafted throughput: 2.29 tokens/s, Accepted: 241 tokens, Drafted: 321 tokens, Per-position acceptance rate: 0.888, 0.720, 0.645, Avg Draft acceptance rate: 75.1%
(APIServer pid=1) INFO 05-21 21:49:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.3%
(APIServer pid=1) INFO 05-21 21:49:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.12, Accepted throughput: 31.00 tokens/s, Drafted throughput: 43.80 tokens/s, Accepted: 310 tokens, Drafted: 438 tokens, Per-position acceptance rate: 0.849, 0.692, 0.582, Avg Draft acceptance rate: 70.8%
(APIServer pid=1) INFO:     172.18.0.3:51992 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49028 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:49:46 [loggers.py:271] Engine 000: Avg prompt throughput: 2364.7 tokens/s, Avg generation throughput: 21.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 85.6%
(APIServer pid=1) INFO 05-21 21:49:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.75, Accepted throughput: 15.40 tokens/s, Drafted throughput: 16.80 tokens/s, Accepted: 154 tokens, Drafted: 168 tokens, Per-position acceptance rate: 1.000, 0.893, 0.857, Avg Draft acceptance rate: 91.7%
(APIServer pid=1) INFO:     172.18.0.3:49040 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:49:56 [loggers.py:271] Engine 000: Avg prompt throughput: 322.3 tokens/s, Avg generation throughput: 44.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.7%
(APIServer pid=1) INFO 05-21 21:49:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.43, Accepted throughput: 31.80 tokens/s, Drafted throughput: 39.30 tokens/s, Accepted: 318 tokens, Drafted: 393 tokens, Per-position acceptance rate: 0.878, 0.794, 0.756, Avg Draft acceptance rate: 80.9%
(APIServer pid=1) INFO 05-21 21:50:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.7%
(APIServer pid=1) INFO:     172.18.0.3:58438 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:34910 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:55:06 [loggers.py:271] Engine 000: Avg prompt throughput: 634.7 tokens/s, Avg generation throughput: 23.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.7%
(APIServer pid=1) INFO 05-21 21:55:06 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.19, Accepted throughput: 0.52 tokens/s, Drafted throughput: 0.72 tokens/s, Accepted: 162 tokens, Drafted: 222 tokens, Per-position acceptance rate: 0.905, 0.703, 0.581, Avg Draft acceptance rate: 73.0%
(APIServer pid=1) INFO 05-21 21:55:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.7%
(APIServer pid=1) INFO:     172.18.0.3:58936 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:52898 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:55:36 [loggers.py:271] Engine 000: Avg prompt throughput: 759.0 tokens/s, Avg generation throughput: 13.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 85.4%
(APIServer pid=1) INFO 05-21 21:55:36 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 2.73 tokens/s, Drafted throughput: 5.00 tokens/s, Accepted: 82 tokens, Drafted: 150 tokens, Per-position acceptance rate: 0.760, 0.540, 0.340, Avg Draft acceptance rate: 54.7%
(APIServer pid=1) INFO:     172.18.0.3:52914 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:52916 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:52924 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:55:46 [loggers.py:271] Engine 000: Avg prompt throughput: 974.1 tokens/s, Avg generation throughput: 56.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 85.1%
(APIServer pid=1) INFO 05-21 21:55:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.20, Accepted throughput: 38.99 tokens/s, Drafted throughput: 53.09 tokens/s, Accepted: 390 tokens, Drafted: 531 tokens, Per-position acceptance rate: 0.881, 0.723, 0.599, Avg Draft acceptance rate: 73.4%
(APIServer pid=1) INFO 05-21 21:55:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.1%
(APIServer pid=1) INFO 05-21 21:55:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 8.40 tokens/s, Drafted throughput: 13.80 tokens/s, Accepted: 84 tokens, Drafted: 138 tokens, Per-position acceptance rate: 0.739, 0.609, 0.478, Avg Draft acceptance rate: 60.9%
(APIServer pid=1) INFO 05-21 21:56:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.1%
(APIServer pid=1) INFO:     172.18.0.3:51530 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:51538 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:56:46 [loggers.py:271] Engine 000: Avg prompt throughput: 1061.6 tokens/s, Avg generation throughput: 47.0 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 84.9%
(APIServer pid=1) INFO 05-21 21:56:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 6.24 tokens/s, Drafted throughput: 9.36 tokens/s, Accepted: 312 tokens, Drafted: 468 tokens, Per-position acceptance rate: 0.801, 0.686, 0.513, Avg Draft acceptance rate: 66.7%
(APIServer pid=1) INFO 05-21 21:56:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 46.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.9%
(APIServer pid=1) INFO 05-21 21:56:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.01, Accepted throughput: 31.30 tokens/s, Drafted throughput: 46.80 tokens/s, Accepted: 313 tokens, Drafted: 468 tokens, Per-position acceptance rate: 0.821, 0.660, 0.526, Avg Draft acceptance rate: 66.9%
(APIServer pid=1) INFO 05-21 21:57:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.9%
(APIServer pid=1) INFO:     172.18.0.3:38724 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:38740 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-21 21:57:46 [loggers.py:271] Engine 000: Avg prompt throughput: 922.2 tokens/s, Avg generation throughput: 44.1 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 84.8%
(APIServer pid=1) INFO 05-21 21:57:46 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 5.10 tokens/s, Drafted throughput: 11.04 tokens/s, Accepted: 255 tokens, Drafted: 552 tokens, Per-position acceptance rate: 0.679, 0.440, 0.266, Avg Draft acceptance rate: 46.2%
(APIServer pid=1) INFO 05-21 21:57:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.8%
(APIServer pid=1) INFO 05-21 21:57:56 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.31, Accepted throughput: 25.90 tokens/s, Drafted throughput: 33.60 tokens/s, Accepted: 259 tokens, Drafted: 336 tokens, Per-position acceptance rate: 0.884, 0.768, 0.661, Avg Draft acceptance rate: 77.1%
(APIServer pid=1) INFO 05-21 21:58:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 84.8%
```
