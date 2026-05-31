# docker compose

```yml
services:
  prismaquant-35b:
    image: vllm/vllm-openai:v0.22.0-ubuntu2404
    container_name: qwen3-6-prismaquant-35b
    hostname: inference-server
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
      
      # --- BLACKWELL & MARLIN TUNING ENVS FROM RECIPE ---
      VLLM_TEST_FORCE_FP8_MARLIN: "1"
      TORCH_MATMUL_PRECISION: "high"
      NVIDIA_FORWARD_COMPAT: "1"
      VLLM_TUNED_CONFIG_FOLDER: "/workspace/moe-configs"

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

      # --- MEMORY & CONTEXT OPTIMIZATION ---
      - "--gpu-memory-utilization"
      - "0.85"                  # Slightly bumped from 0.80 for larger cache room
      - "--max-model-len"
      - "200000"                # 200k tokens generous
      - "--max-num-seqs"
      - "8"                    # Reduce to 8 concurrent threads

      # --- BATCHING / PREFILL ---
      - "--max-num-batched-tokens"
      - "32768"

      # --- QUANTIZATION & ATTN ---
      - "--kv-cache-dtype"
      - "auto"                  # Changed to auto to allow vLLM to map seamlessly with DFlash hidden states
      - "--quantization"
      - "compressed-tensors"
      - "--attention-backend"
      - "flash_attn"            # Aligned with recipe's native flash_attn choice for DFlash stability
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

      # --- ADVANCED DRIVER / PERFORMANCE MODE ---
      - "--performance-mode"
      - "throughput"
      - "--optimization-level"
      - "3"

      # --- Z-LAB DFLASH SPECULATIVE CONFIG (n=6) ---
      - "--speculative-config"
      # - '{"method":"dflash","model":"z-lab/Qwen3.6-35B-A3B-DFlash","num_speculative_tokens":6}' # Even the first token has terrible prediction 0.69 (so this MTP brings nothing)
      - '{"method":"mtp","num_speculative_tokens":3}'

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllgm log

```log
Displaying logs for qwen3-6-prismaquant-35b (Ctrl+C to stop)...
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
WARNING 05-30 07:40:19 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.22.0
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]   █▄█▀ █     █     █     █  model   rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:344]
(APIServer pid=1) INFO 05-30 07:40:19 [utils.py:278] non-default args: {'model_tag': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'trust_remote_code': True, 'max_model_len': 200000, 'quantization': 'compressed-tensors', 'served_model_name': ['qwen3.6-35b'], 'attention_backend': 'flash_attn', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 3}, 'optimization_level': '3', 'performance_mode': 'throughput'}
(APIServer pid=1) WARNING 05-30 07:40:19 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
(APIServer pid=1) WARNING 05-30 07:40:19 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
(APIServer pid=1) WARNING 05-30 07:40:19 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_URL
(APIServer pid=1) WARNING 05-30 07:40:19 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
(APIServer pid=1) INFO 05-30 07:40:29 [model.py:617] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-30 07:40:29 [model.py:1752] Using max model len 200000
(APIServer pid=1) INFO 05-30 07:40:35 [model.py:617] Resolved architecture: Qwen3_5MoeMTP
(APIServer pid=1) INFO 05-30 07:40:35 [model.py:1752] Using max model len 262144
(APIServer pid=1) WARNING 05-30 07:40:35 [speculative.py:709] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
(APIServer pid=1) INFO 05-30 07:40:35 [speculative.py:882] Overriding draft model max model len from 262144 to 200000
(APIServer pid=1) INFO 05-30 07:40:35 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
(APIServer pid=1) INFO 05-30 07:40:35 [vllm.py:832] Performance mode set to 'throughput'.
(APIServer pid=1) WARNING 05-30 07:40:35 [config.py:355] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-30 07:40:35 [config.py:375] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-30 07:40:35 [vllm.py:977] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-30 07:40:35 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
(EngineCore pid=284) INFO 05-30 07:40:52 [core.py:112] Initializing a V1 LLM engine (v0.22.0) with config: model='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', speculative_config=SpeculativeConfig(method='mtp', model='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', num_spec_tokens=3), tokenizer='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=200000, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=auto, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-35b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 64, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto', linear_backend='auto')
(EngineCore pid=284) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=284) INFO 05-30 07:40:54 [parallel_state.py:1422] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:59543 backend=nccl
(EngineCore pid=284) INFO 05-30 07:40:54 [parallel_state.py:1735] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=284) INFO 05-30 07:40:55 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
(EngineCore pid=284) WARNING 05-30 07:40:55 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=284) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=284) INFO 05-30 07:41:04 [gpu_model_runner.py:5037] Starting to load model rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm...
(EngineCore pid=284) INFO 05-30 07:41:04 [__init__.py:940] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=284) INFO 05-30 07:41:04 [cuda.py:433] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=284) INFO 05-30 07:41:04 [__init__.py:721] Using FlashInferCutlassMxfp8LinearKernel for MXFP8 GEMM
(EngineCore pid=284) INFO 05-30 07:41:04 [mm_encoder_attention.py:372] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=284) INFO 05-30 07:41:04 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel (requested=auto, head_k_dim=None).
(EngineCore pid=284) INFO 05-30 07:41:04 [nvfp4.py:231] Using 'MARLIN' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=284) INFO 05-30 07:41:04 [cuda.py:318] Using AttentionBackendEnum.FLASH_ATTN backend.
(EngineCore pid=284) INFO 05-30 07:41:04 [flash_attn.py:636] Using FlashAttention version 2
(EngineCore pid=284) INFO 05-30 07:41:06 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.31 GiB. Available RAM: 88.96 GiB.
(EngineCore pid=284) INFO 05-30 07:41:06 [weight_utils.py:945] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
Loading safetensors checkpoint shards:   0% Completed | 0/6 [00:00<?, ?it/s]
Loading safetensors checkpoint shards:  17% Completed | 1/6 [00:34<02:51, 34.31s/it]
Loading safetensors checkpoint shards:  33% Completed | 2/6 [01:07<02:15, 33.82s/it]
Loading safetensors checkpoint shards:  50% Completed | 3/6 [01:37<01:35, 31.92s/it]
Loading safetensors checkpoint shards:  67% Completed | 4/6 [02:05<01:00, 30.43s/it]
Loading safetensors checkpoint shards:  83% Completed | 5/6 [02:30<00:28, 28.57s/it]
Loading safetensors checkpoint shards: 100% Completed | 6/6 [02:30<00:00, 25.14s/it]
(EngineCore pid=284)
(EngineCore pid=284) INFO 05-30 07:43:37 [default_loader.py:397] Loading weights took 150.97 seconds
(EngineCore pid=284) WARNING 05-30 07:43:37 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
(EngineCore pid=284) INFO 05-30 07:43:37 [nvfp4.py:537] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=284) WARNING 05-30 07:43:37 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
(EngineCore pid=284) INFO 05-30 07:43:41 [gpu_model_runner.py:5061] Loading drafter model...
(EngineCore pid=284) INFO 05-30 07:43:41 [vllm.py:832] Performance mode set to 'throughput'.
(EngineCore pid=284) INFO 05-30 07:43:41 [vllm.py:977] Asynchronous scheduling is enabled.
(EngineCore pid=284) INFO 05-30 07:43:41 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=284) INFO 05-30 07:43:41 [cuda.py:378] Using FLASH_ATTN attention backend out of potential backends: ['FLASH_ATTN', 'FLASHINFER', 'TRITON_ATTN', 'FLEX_ATTENTION'].
(EngineCore pid=284) INFO 05-30 07:43:42 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.31 GiB. Available RAM: 69.17 GiB.
Loading safetensors checkpoint shards:   0% Completed | 0/6 [00:00<?, ?it/s]
Loading safetensors checkpoint shards:  17% Completed | 1/6 [00:12<01:03, 12.79s/it]
Loading safetensors checkpoint shards:  33% Completed | 2/6 [00:12<00:21,  5.39s/it]
Loading safetensors checkpoint shards:  50% Completed | 3/6 [00:13<00:09,  3.03s/it]
Loading safetensors checkpoint shards:  67% Completed | 4/6 [00:13<00:03,  1.91s/it]
Loading safetensors checkpoint shards:  83% Completed | 5/6 [00:17<00:02,  2.54s/it]
(EngineCore pid=284) INFO 05-30 07:43:59 [default_loader.py:397] Loading weights took 17.11 seconds
Loading safetensors checkpoint shards: 100% Completed | 6/6 [00:17<00:00,  2.85s/it]
(EngineCore pid=284)
(EngineCore pid=284) INFO 05-30 07:43:59 [llm_base_proposer.py:1327] Detected MTP model. Sharing target model embedding weights with the draft model.
(EngineCore pid=284) INFO 05-30 07:43:59 [llm_base_proposer.py:1383] Detected MTP model. Sharing target model lm_head weights with the draft model.
(EngineCore pid=284) INFO 05-30 07:44:00 [gpu_model_runner.py:5132] Model loading took 21.42 GiB memory and 175.218386 seconds
(EngineCore pid=284) INFO 05-30 07:44:00 [interface.py:649] Setting attention block size to 1072 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=284) INFO 05-30 07:44:00 [gpu_model_runner.py:6136] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
(EngineCore pid=284) INFO 05-30 07:44:13 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/0d712c7e8f/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=284) INFO 05-30 07:44:13 [backends.py:1148] Dynamo bytecode transform time: 5.67 s
(EngineCore pid=284) [rank0]:W0530 07:44:27.017000 284 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=284) INFO 05-30 07:44:27 [backends.py:378] Cache the graph of compile range (1, 32768) for later use
(EngineCore pid=284) INFO 05-30 07:44:57 [backends.py:393] Compiling a graph for compile range (1, 32768) takes 44.33 s
(EngineCore pid=284) INFO 05-30 07:44:59 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/35ec614915c14caab22ac0048d2d670321e060f64496bff2f0e780132dfd2285/rank_0_0/model
(EngineCore pid=284) INFO 05-30 07:44:59 [monitor.py:53] torch.compile took 52.43 s in total
(EngineCore pid=284) INFO 05-30 07:45:48 [monitor.py:81] Initial profiling/warmup run took 48.33 s
(EngineCore pid=284) INFO 05-30 07:45:48 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/0d712c7e8f/rank_0_0/eagle_head for vLLM's torch.compile
(EngineCore pid=284) INFO 05-30 07:45:48 [backends.py:1148] Dynamo bytecode transform time: 0.35 s
(EngineCore pid=284) INFO 05-30 07:45:54 [backends.py:393] Compiling a graph for compile range (1, 32768) takes 6.40 s
(EngineCore pid=284) INFO 05-30 07:45:55 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/67c506ff394c7f3006f0bd984db335e9a3088789348e07c90c0b48eddffff7fd/rank_0_0/model
(EngineCore pid=284) INFO 05-30 07:45:55 [monitor.py:53] torch.compile took 7.32 s in total
(EngineCore pid=284) INFO 05-30 07:45:56 [monitor.py:81] Initial profiling/warmup run took 0.97 s
(EngineCore pid=284) WARNING 05-30 07:46:01 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=284) INFO 05-30 07:46:01 [gpu_model_runner.py:6279] Profiling CUDA graph memory: PIECEWISE=9 (largest=64), FULL=5 (largest=32)
(EngineCore pid=284) INFO 05-30 07:46:21 [gpu_model_runner.py:6365] Estimated CUDA graph memory: 0.61 GiB total
(EngineCore pid=284) INFO 05-30 07:46:21 [gpu_worker.py:466] Available KV cache memory: 71.15 GiB
(EngineCore pid=284) INFO 05-30 07:46:21 [gpu_worker.py:481] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8449 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8551. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=284) WARNING 05-30 07:46:21 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=284) INFO 05-30 07:46:21 [kv_cache_utils.py:1733] GPU KV cache size: 3,131,683 tokens
(EngineCore pid=284) INFO 05-30 07:46:21 [kv_cache_utils.py:1734] Maximum concurrency for 200,000 tokens per request: 15.66x
(EngineCore pid=284) 2026-05-30 07:46:27,110 - INFO - autotuner.py:615 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:17<00:00,  1.29profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:03<00:00,  5.89profile/s]
[AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/23 [00:00<?, ?profile/s]2026-05-30 07:46:50,053 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:   4%|▍         | 1/23 [00:00<00:09,  2.35profile/s]2026-05-30 07:46:50,076 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,097 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,116 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,132 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,151 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,165 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  30%|███       | 7/23 [00:00<00:00, 16.38profile/s]2026-05-30 07:46:50,180 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,198 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,224 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,257 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,298 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  52%|█████▏    | 12/23 [00:00<00:00, 23.10profile/s]2026-05-30 07:46:50,346 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,406 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,471 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,547 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  70%|██████▉   | 16/23 [00:00<00:00, 19.85profile/s]2026-05-30 07:46:50,637 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,748 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:50,954 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  83%|████████▎ | 19/23 [00:01<00:00, 13.41profile/s]2026-05-30 07:46:51,187 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:51,742 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:54,135 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  96%|█████████▌| 22/23 [00:04<00:00,  2.78profile/s]2026-05-30 07:46:58,521 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 23/23 [00:08<00:00,  2.59profile/s]
[AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/23 [00:00<?, ?profile/s]2026-05-30 07:46:58,915 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:   4%|▍         | 1/23 [00:00<00:07,  2.92profile/s]2026-05-30 07:46:58,927 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,939 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,951 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,962 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,972 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,982 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:58,992 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,003 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,017 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  43%|████▎     | 10/23 [00:00<00:00, 28.45profile/s]2026-05-30 07:46:59,032 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,050 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,071 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,094 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,120 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,149 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  70%|██████▉   | 16/23 [00:00<00:00, 34.46profile/s]2026-05-30 07:46:59,184 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,224 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,270 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,322 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,416 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm:  91%|█████████▏| 21/23 [00:00<00:00, 26.51profile/s]2026-05-30 07:46:59,601 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=284) 2026-05-30 07:46:59,962 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
[AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 23/23 [00:01<00:00, 16.56profile/s]
(EngineCore pid=284) 2026-05-30 07:47:00,209 - INFO - autotuner.py:634 - flashinfer.jit: [Autotuner]: Autotuning process ends
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 9/9 [00:00<00:00, 10.60it/s]
Capturing CUDA graphs (decode, FULL): 100%|██████████| 5/5 [00:01<00:00,  3.65it/s]
(EngineCore pid=284) INFO 05-30 07:47:06 [gpu_model_runner.py:6456] Graph capturing finished in 6 secs, took 0.38 GiB
(EngineCore pid=284) INFO 05-30 07:47:06 [gpu_worker.py:619] CUDA graph pool memory: 0.38 GiB (actual), 0.61 GiB (estimated), difference: 0.23 GiB (62.2%).
(EngineCore pid=284) INFO 05-30 07:47:06 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
(EngineCore pid=284) INFO 05-30 07:47:06 [core.py:302] init engine (profile, create kv cache, warmup model) took 186.17 s (compilation: 59.75 s)
(EngineCore pid=284) INFO 05-30 07:47:06 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) INFO 05-30 07:47:07 [api_server.py:592] Supported tasks: ['generate']
(APIServer pid=1) INFO 05-30 07:47:11 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 05-30 07:47:11 [model.py:1509] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-30 07:47:16 [hf.py:488] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-30 07:47:30 [base.py:224] Multi-modal warmup completed in 14.116s
(APIServer pid=1) INFO 05-30 07:47:30 [base.py:224] Readonly multi-modal warmup completed in 0.391s
(APIServer pid=1) INFO 05-30 07:47:31 [api_server.py:596] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-30 07:47:31 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.3:43420 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=284) WARNING 05-30 07:48:45 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _zero_kv_blocks_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:48:45 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _compute_slot_mapping_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:48:47 [jit_monitor.py:103] Triton kernel JIT compilation during inference: postprocess_mamba_fused_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:48:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_next_token_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:48:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_step_slot_mapping_metadata_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:49:16 [jit_monitor.py:103] Triton kernel JIT compilation during inference: batch_memcpy_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:49:17 [jit_monitor.py:103] Triton kernel JIT compilation during inference: expand_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=284) WARNING 05-30 07:49:17 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_inputs_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 05-30 07:49:21 [loggers.py:271] Engine 000: Avg prompt throughput: 1505.3 tokens/s, Avg generation throughput: 20.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-30 07:49:21 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.07, Accepted throughput: 1.05 tokens/s, Drafted throughput: 1.51 tokens/s, Accepted: 141 tokens, Drafted: 204 tokens, Per-position acceptance rate: 0.897, 0.676, 0.500, Avg Draft acceptance rate: 69.1%
(APIServer pid=1) INFO 05-30 07:49:31 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.3:48374 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:55:11 [loggers.py:271] Engine 000: Avg prompt throughput: 1914.9 tokens/s, Avg generation throughput: 1.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-30 07:55:11 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 0.02 tokens/s, Drafted throughput: 0.03 tokens/s, Accepted: 8 tokens, Drafted: 12 tokens, Per-position acceptance rate: 1.000, 0.500, 0.500, Avg Draft acceptance rate: 66.7%
(APIServer pid=1) INFO 05-30 07:55:21 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 54.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-30 07:55:21 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 35.39 tokens/s, Drafted throughput: 56.39 tokens/s, Accepted: 354 tokens, Drafted: 564 tokens, Per-position acceptance rate: 0.798, 0.628, 0.457, Avg Draft acceptance rate: 62.8%
(APIServer pid=1) INFO 05-30 07:55:31 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-30 07:55:31 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 25.90 tokens/s, Drafted throughput: 51.89 tokens/s, Accepted: 259 tokens, Drafted: 519 tokens, Per-position acceptance rate: 0.705, 0.474, 0.318, Avg Draft acceptance rate: 49.9%
(APIServer pid=1) INFO 05-30 07:55:41 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.3:34038 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:56:51 [loggers.py:271] Engine 000: Avg prompt throughput: 354.8 tokens/s, Avg generation throughput: 44.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 31.2%
(APIServer pid=1) INFO 05-30 07:56:51 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 3.67 tokens/s, Drafted throughput: 5.51 tokens/s, Accepted: 294 tokens, Drafted: 441 tokens, Per-position acceptance rate: 0.810, 0.653, 0.537, Avg Draft acceptance rate: 66.7%
(APIServer pid=1) INFO 05-30 07:57:01 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 31.2%
(APIServer pid=1) INFO 05-30 07:57:01 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 29.30 tokens/s, Drafted throughput: 55.79 tokens/s, Accepted: 293 tokens, Drafted: 558 tokens, Per-position acceptance rate: 0.704, 0.505, 0.366, Avg Draft acceptance rate: 52.5%
(APIServer pid=1) INFO 05-30 07:57:11 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 16.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 31.2%
(APIServer pid=1) INFO 05-30 07:57:11 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 9.40 tokens/s, Drafted throughput: 22.50 tokens/s, Accepted: 94 tokens, Drafted: 225 tokens, Per-position acceptance rate: 0.667, 0.413, 0.173, Avg Draft acceptance rate: 41.8%
```
