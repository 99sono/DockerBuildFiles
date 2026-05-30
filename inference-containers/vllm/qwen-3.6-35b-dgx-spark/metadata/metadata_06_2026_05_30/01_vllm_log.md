
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
      - '{"method":"dflash","model":"z-lab/Qwen3.6-35B-A3B-DFlash","num_speculative_tokens":6}'

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# Vllm log

```log
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
WARNING 05-30 07:09:38 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344] 
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.22.0
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344]   █▄█▀ █     █     █     █  model   rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:344] 
(APIServer pid=1) INFO 05-30 07:09:38 [utils.py:278] non-default args: {'model_tag': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', 'trust_remote_code': True, 'max_model_len': 200000, 'quantization': 'compressed-tensors', 'served_model_name': ['qwen3.6-35b'], 'attention_backend': 'flash_attn', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'speculative_config': {'method': 'dflash', 'model': 'z-lab/Qwen3.6-35B-A3B-DFlash', 'num_speculative_tokens': 6}, 'optimization_level': '3', 'performance_mode': 'throughput'}
(APIServer pid=1) WARNING 05-30 07:09:38 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
(APIServer pid=1) WARNING 05-30 07:09:38 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
(APIServer pid=1) WARNING 05-30 07:09:38 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_BUILD_URL
(APIServer pid=1) WARNING 05-30 07:09:38 [envs.py:2057] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
(APIServer pid=1) INFO 05-30 07:09:49 [model.py:617] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-30 07:09:49 [model.py:1752] Using max model len 200000
(APIServer pid=1) INFO 05-30 07:09:55 [model.py:617] Resolved architecture: DFlashDraftModel
(APIServer pid=1) INFO 05-30 07:09:55 [model.py:1752] Using max model len 262144
(APIServer pid=1) INFO 05-30 07:09:55 [speculative.py:882] Overriding draft model max model len from 262144 to 200000
(APIServer pid=1) INFO 05-30 07:09:55 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
(APIServer pid=1) INFO 05-30 07:09:55 [vllm.py:832] Performance mode set to 'throughput'.
(APIServer pid=1) WARNING 05-30 07:09:55 [config.py:355] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-30 07:09:55 [config.py:375] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-30 07:09:55 [vllm.py:977] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-30 07:09:55 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
(EngineCore pid=282) INFO 05-30 07:10:12 [core.py:112] Initializing a V1 LLM engine (v0.22.0) with config: model='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', speculative_config=SpeculativeConfig(method='dflash', model='z-lab/Qwen3.6-35B-A3B-DFlash', num_spec_tokens=6), tokenizer='rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=200000, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=auto, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-35b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 112, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto', linear_backend='auto')
(EngineCore pid=282) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=282) INFO 05-30 07:10:14 [parallel_state.py:1422] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:41813 backend=nccl
(EngineCore pid=282) INFO 05-30 07:10:14 [parallel_state.py:1735] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=282) INFO 05-30 07:10:14 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
(EngineCore pid=282) WARNING 05-30 07:10:14 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=282) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=282) INFO 05-30 07:10:23 [gpu_model_runner.py:5037] Starting to load model rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm...
(EngineCore pid=282) INFO 05-30 07:10:24 [__init__.py:940] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=282) INFO 05-30 07:10:24 [cuda.py:433] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=282) INFO 05-30 07:10:24 [__init__.py:721] Using FlashInferCutlassMxfp8LinearKernel for MXFP8 GEMM
(EngineCore pid=282) INFO 05-30 07:10:24 [mm_encoder_attention.py:372] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=282) INFO 05-30 07:10:24 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel (requested=auto, head_k_dim=None).
(EngineCore pid=282) INFO 05-30 07:10:24 [nvfp4.py:231] Using 'MARLIN' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=282) INFO 05-30 07:10:24 [cuda.py:318] Using AttentionBackendEnum.FLASH_ATTN backend.
(EngineCore pid=282) INFO 05-30 07:10:24 [flash_attn.py:636] Using FlashAttention version 2
(EngineCore pid=282) INFO 05-30 07:10:26 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.31 GiB. Available RAM: 86.76 GiB.
(EngineCore pid=282) INFO 05-30 07:10:26 [weight_utils.py:945] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
(EngineCore pid=282) Loading safetensors checkpoint shards:   0% Completed | 0/6 [00:00<?, ?it/s]
(EngineCore pid=282) Loading safetensors checkpoint shards:  17% Completed | 1/6 [00:23<01:57, 23.54s/it]
(EngineCore pid=282) Loading safetensors checkpoint shards:  33% Completed | 2/6 [00:53<01:48, 27.04s/it]
(EngineCore pid=282) Loading safetensors checkpoint shards:  50% Completed | 3/6 [01:22<01:24, 28.29s/it]
(EngineCore pid=282) Loading safetensors checkpoint shards:  67% Completed | 4/6 [01:52<00:57, 28.83s/it]
(EngineCore pid=282) Loading safetensors checkpoint shards:  83% Completed | 5/6 [02:18<00:27, 27.89s/it]
(EngineCore pid=282) Loading safetensors checkpoint shards: 100% Completed | 6/6 [02:18<00:00, 23.12s/it]
(EngineCore pid=282) 
(EngineCore pid=282) INFO 05-30 07:12:45 [default_loader.py:397] Loading weights took 138.88 seconds
(EngineCore pid=282) WARNING 05-30 07:12:45 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
(EngineCore pid=282) INFO 05-30 07:12:45 [nvfp4.py:537] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=282) WARNING 05-30 07:12:45 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
(EngineCore pid=282) INFO 05-30 07:12:50 [gpu_model_runner.py:5061] Loading drafter model...
(EngineCore pid=282) INFO 05-30 07:12:50 [vllm.py:832] Performance mode set to 'throughput'.
(EngineCore pid=282) INFO 05-30 07:12:50 [vllm.py:977] Asynchronous scheduling is enabled.
(EngineCore pid=282) INFO 05-30 07:12:50 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=282) INFO 05-30 07:12:50 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=282) INFO 05-30 07:12:50 [cuda.py:378] Using FLASH_ATTN attention backend out of potential backends: ['FLASH_ATTN', 'FLEX_ATTENTION'].
(EngineCore pid=282) INFO 05-30 07:12:50 [weight_utils.py:647] No model.safetensors.index.json found in remote.
(EngineCore pid=282) INFO 05-30 07:12:50 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 0.88 GiB. Available RAM: 66.05 GiB.
(EngineCore pid=282) Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
(EngineCore pid=282) Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00, 59.30it/s]
(EngineCore pid=282) 
(EngineCore pid=282) INFO 05-30 07:12:56 [default_loader.py:397] Loading weights took 5.18 seconds
(EngineCore pid=282) INFO 05-30 07:12:56 [llm_base_proposer.py:1298] Detected EAGLE model without its own embed_tokens in the checkpoint. Sharing target model embedding weights with the draft model.
(EngineCore pid=282) INFO 05-30 07:12:56 [llm_base_proposer.py:1353] Detected EAGLE model without its own lm_head in the checkpoint. Sharing target model lm_head weights with the draft model.
(EngineCore pid=282) INFO 05-30 07:12:56 [gpu_model_runner.py:5217] Using auxiliary layers from speculative config: (2, 11, 20, 29, 38)
(EngineCore pid=282) INFO 05-30 07:12:56 [gpu_model_runner.py:5132] Model loading took 21.91 GiB memory and 152.095157 seconds
(EngineCore pid=282) INFO 05-30 07:12:56 [interface.py:649] Setting attention block size to 1104 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=282) INFO 05-30 07:12:56 [interface.py:673] Padding mamba page size by 0.73% to ensure that mamba page size and attention page size are exactly equal.
(EngineCore pid=282) INFO 05-30 07:12:56 [gpu_model_runner.py:6136] Encoder cache will be initialized with a budget of 32768 tokens, and profiled with 2 image items of the maximum feature size.
(EngineCore pid=282) INFO 05-30 07:13:10 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/ce13c53ab8/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=282) INFO 05-30 07:13:10 [backends.py:1148] Dynamo bytecode transform time: 6.30 s
(EngineCore pid=282) [rank0]:W0530 07:13:28.397000 282 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=282) INFO 05-30 07:13:29 [backends.py:378] Cache the graph of compile range (1, 32768) for later use
(EngineCore pid=282) INFO 05-30 07:14:08 [backends.py:393] Compiling a graph for compile range (1, 32768) takes 57.59 s
(EngineCore pid=282) INFO 05-30 07:14:10 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/918132ecc73a09cc116de3655c3a093c7c24425e9ef067f4dfdd005d64e5b9cd/rank_0_0/model
(EngineCore pid=282) INFO 05-30 07:14:10 [monitor.py:53] torch.compile took 65.83 s in total
(EngineCore pid=282) INFO 05-30 07:15:00 [monitor.py:81] Initial profiling/warmup run took 50.50 s
(EngineCore pid=282) INFO 05-30 07:15:01 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/ce13c53ab8/rank_0_0/eagle_head for vLLM's torch.compile
(EngineCore pid=282) INFO 05-30 07:15:01 [backends.py:1148] Dynamo bytecode transform time: 0.73 s
(EngineCore pid=282) INFO 05-30 07:15:07 [backends.py:393] Compiling a graph for compile range (1, 32768) takes 5.55 s
(EngineCore pid=282) INFO 05-30 07:15:07 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/8feb0cb82b295aab7af00363885ebaf853f50a0150c47b04bb4511543c6ba9b3/rank_0_0/model
(EngineCore pid=282) INFO 05-30 07:15:07 [monitor.py:53] torch.compile took 6.69 s in total
(EngineCore pid=282) INFO 05-30 07:15:08 [monitor.py:81] Initial profiling/warmup run took 0.35 s
(EngineCore pid=282) WARNING 05-30 07:15:12 [kv_cache_utils.py:1157] Add 2 padding layers, may waste at most 6.67% KV cache memory
(EngineCore pid=282) WARNING 05-30 07:15:12 [kv_cache_utils.py:1157] Add 6 padding layers, may waste at most 60.00% KV cache memory
(EngineCore pid=282) INFO 05-30 07:15:12 [gpu_model_runner.py:6279] Profiling CUDA graph memory: PIECEWISE=15 (largest=112), FULL=8 (largest=56)
(EngineCore pid=282) INFO 05-30 07:15:32 [gpu_model_runner.py:6365] Estimated CUDA graph memory: 0.65 GiB total
(EngineCore pid=282) INFO 05-30 07:15:33 [gpu_worker.py:466] Available KV cache memory: 71.59 GiB
(EngineCore pid=282) INFO 05-30 07:15:33 [gpu_worker.py:481] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8445 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8555. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=282) WARNING 05-30 07:15:33 [kv_cache_utils.py:1157] Add 2 padding layers, may waste at most 6.67% KV cache memory
(EngineCore pid=282) WARNING 05-30 07:15:33 [kv_cache_utils.py:1157] Add 6 padding layers, may waste at most 60.00% KV cache memory
(EngineCore pid=282) INFO 05-30 07:15:33 [kv_cache_utils.py:1733] GPU KV cache size: 1,470,588 tokens
(EngineCore pid=282) INFO 05-30 07:15:33 [kv_cache_utils.py:1734] Maximum concurrency for 200,000 tokens per request: 7.35x
(EngineCore pid=282) 2026-05-30 07:15:45,192 - INFO - autotuner.py:615 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(EngineCore pid=282) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/23 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:   4%|▍         | 1/23 [00:00<00:04,  4.48profile/s][AutoTuner]: Tuning fp4_gemm:  13%|█▎        | 3/23 [00:00<00:02,  8.68profile/s][AutoTuner]: Tuning fp4_gemm:  22%|██▏       | 5/23 [00:00<00:01, 10.18profile/s][AutoTuner]: Tuning fp4_gemm:  30%|███       | 7/23 [00:00<00:01, 11.48profile/s][AutoTuner]: Tuning fp4_gemm:  39%|███▉      | 9/23 [00:00<00:01, 12.75profile/s][AutoTuner]: Tuning fp4_gemm:  48%|████▊     | 11/23 [00:01<00:01, 11.24profile/s][AutoTuner]: Tuning fp4_gemm:  57%|█████▋    | 13/23 [00:01<00:01,  8.83profile/s][AutoTuner]: Tuning fp4_gemm:  65%|██████▌   | 15/23 [00:01<00:01,  6.88profile/s][AutoTuner]: Tuning fp4_gemm:  70%|██████▉   | 16/23 [00:02<00:01,  6.05profile/s][AutoTuner]: Tuning fp4_gemm:  74%|███████▍  | 17/23 [00:02<00:01,  5.08profile/s][AutoTuner]: Tuning fp4_gemm:  78%|███████▊  | 18/23 [00:02<00:01,  3.72profile/s][AutoTuner]: Tuning fp4_gemm:  83%|████████▎ | 19/23 [00:03<00:01,  3.34profile/s][AutoTuner]: Tuning fp4_gemm:  87%|████████▋ | 20/23 [00:03<00:01,  2.95profile/s][AutoTuner]: Tuning fp4_gemm:  91%|█████████▏| 21/23 [00:04<00:01,  1.79profile/s][AutoTuner]: Tuning fp4_gemm:  96%|█████████▌| 22/23 [00:07<00:01,  1.07s/profile][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:14<00:00,  2.82s/profile][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:14<00:00,  1.59profile/s]
(EngineCore pid=282) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/23 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:   9%|▊         | 2/23 [00:00<00:01, 14.58profile/s][AutoTuner]: Tuning fp4_gemm:  22%|██▏       | 5/23 [00:00<00:00, 18.20profile/s][AutoTuner]: Tuning fp4_gemm:  35%|███▍      | 8/23 [00:00<00:00, 19.83profile/s][AutoTuner]: Tuning fp4_gemm:  48%|████▊     | 11/23 [00:00<00:00, 19.62profile/s][AutoTuner]: Tuning fp4_gemm:  57%|█████▋    | 13/23 [00:00<00:00, 17.75profile/s][AutoTuner]: Tuning fp4_gemm:  65%|██████▌   | 15/23 [00:00<00:00, 15.66profile/s][AutoTuner]: Tuning fp4_gemm:  74%|███████▍  | 17/23 [00:01<00:00, 13.29profile/s][AutoTuner]: Tuning fp4_gemm:  83%|████████▎ | 19/23 [00:01<00:00, 10.84profile/s][AutoTuner]: Tuning fp4_gemm:  91%|█████████▏| 21/23 [00:01<00:00,  7.71profile/s][AutoTuner]: Tuning fp4_gemm:  96%|█████████▌| 22/23 [00:02<00:00,  3.96profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:03<00:00,  2.15profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 23/23 [00:03<00:00,  5.83profile/s]
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/23 [00:00<?, ?profile/s]2026-05-30 07:16:04,424 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:   4%|▍         | 1/23 [00:00<00:09,  2.34profile/s]2026-05-30 07:16:04,444 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,462 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,480 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,498 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,515 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,529 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  30%|███       | 7/23 [00:00<00:00, 16.62profile/s]2026-05-30 07:16:04,543 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,562 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,587 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,620 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,660 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  52%|█████▏    | 12/23 [00:00<00:00, 23.43profile/s]2026-05-30 07:16:04,709 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,768 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,832 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:04,908 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  70%|██████▉   | 16/23 [00:00<00:00, 20.08profile/s]2026-05-30 07:16:04,998 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:05,109 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:05,309 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  83%|████████▎ | 19/23 [00:01<00:00, 13.57profile/s]2026-05-30 07:16:05,540 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:06,103 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:08,457 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  96%|█████████▌| 22/23 [00:04<00:00,  2.81profile/s]2026-05-30 07:16:12,851 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 23/23 [00:08<00:00,  2.60profile/s]
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:   0%|          | 0/23 [00:00<?, ?profile/s]2026-05-30 07:16:13,239 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:   4%|▍         | 1/23 [00:00<00:07,  3.03profile/s]2026-05-30 07:16:13,250 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,262 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,272 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,283 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,292 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,302 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,311 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,322 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,336 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,352 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  48%|████▊     | 11/23 [00:00<00:00, 31.14profile/s]2026-05-30 07:16:13,370 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,391 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,414 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,440 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,469 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,504 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  74%|███████▍  | 17/23 [00:00<00:00, 34.34profile/s]2026-05-30 07:16:13,544 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,590 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,640 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,734 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) 2026-05-30 07:16:13,918 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm:  96%|█████████▌| 22/23 [00:01<00:00, 20.95profile/s]2026-05-30 07:16:14,281 - INFO - autotuner.py:1256 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for mxfp8_gemm (enable debug logs to see details)
(EngineCore pid=282) [AutoTuner]: Tuning mxfp8_gemm: 100%|██████████| 23/23 [00:01<00:00, 16.77profile/s]
(EngineCore pid=282) 2026-05-30 07:16:14,576 - INFO - autotuner.py:634 - flashinfer.jit: [Autotuner]: Autotuning process ends
(EngineCore pid=282) Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/15 [00:00<?, ?it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   7%|▋         | 1/15 [00:00<00:02,  6.33it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  13%|█▎        | 2/15 [00:00<00:01,  7.83it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  20%|██        | 3/15 [00:00<00:01,  8.50it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  27%|██▋       | 4/15 [00:00<00:01,  8.97it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 5/15 [00:00<00:01,  9.30it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  40%|████      | 6/15 [00:00<00:00,  9.42it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  47%|████▋     | 7/15 [00:00<00:00,  9.49it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  53%|█████▎    | 8/15 [00:00<00:00,  9.33it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  60%|██████    | 9/15 [00:01<00:00,  8.90it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 10/15 [00:01<00:00,  8.61it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  73%|███████▎  | 11/15 [00:01<00:00,  8.85it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  80%|████████  | 12/15 [00:01<00:00,  9.02it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  87%|████████▋ | 13/15 [00:01<00:00,  9.07it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  93%|█████████▎| 14/15 [00:01<00:00,  9.34it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 15/15 [00:01<00:00,  9.07it/s]
(EngineCore pid=282) Capturing CUDA graphs (decode, FULL):   0%|          | 0/8 [00:00<?, ?it/s]Capturing CUDA graphs (decode, FULL):  12%|█▎        | 1/8 [00:00<00:05,  1.31it/s]Capturing CUDA graphs (decode, FULL):  25%|██▌       | 2/8 [00:00<00:02,  2.58it/s]Capturing CUDA graphs (decode, FULL):  38%|███▊      | 3/8 [00:01<00:01,  3.65it/s]Capturing CUDA graphs (decode, FULL):  50%|█████     | 4/8 [00:01<00:00,  4.64it/s]Capturing CUDA graphs (decode, FULL):  62%|██████▎   | 5/8 [00:01<00:00,  5.59it/s]Capturing CUDA graphs (decode, FULL):  75%|███████▌  | 6/8 [00:01<00:00,  6.33it/s]Capturing CUDA graphs (decode, FULL):  88%|████████▊ | 7/8 [00:01<00:00,  6.99it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 8/8 [00:01<00:00,  5.77it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 8/8 [00:01<00:00,  4.61it/s]
(EngineCore pid=282) INFO 05-30 07:16:21 [gpu_model_runner.py:6456] Graph capturing finished in 7 secs, took 0.64 GiB
(EngineCore pid=282) INFO 05-30 07:16:21 [gpu_worker.py:619] CUDA graph pool memory: 0.64 GiB (actual), 0.65 GiB (estimated), difference: 0.01 GiB (2.0%).
(EngineCore pid=282) INFO 05-30 07:16:22 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
(EngineCore pid=282) INFO 05-30 07:16:22 [core.py:302] init engine (profile, create kv cache, warmup model) took 205.24 s (compilation: 72.52 s)
(EngineCore pid=282) INFO 05-30 07:16:22 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) INFO 05-30 07:16:23 [api_server.py:592] Supported tasks: ['generate']
(APIServer pid=1) INFO 05-30 07:16:26 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 05-30 07:16:27 [model.py:1509] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-30 07:16:31 [hf.py:488] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-30 07:16:48 [base.py:224] Multi-modal warmup completed in 16.858s
(APIServer pid=1) INFO 05-30 07:16:49 [base.py:224] Readonly multi-modal warmup completed in 1.150s
(APIServer pid=1) INFO 05-30 07:16:50 [api_server.py:596] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-30 07:16:50 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.3:50234 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=282) WARNING 05-30 07:20:28 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _zero_kv_blocks_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:20:29 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _compute_slot_mapping_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:20:29 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _causal_conv1d_fwd_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:20:29 [jit_monitor.py:103] Triton kernel JIT compilation during inference: postprocess_mamba_fused_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:20:30 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_next_token_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:20:30 [jit_monitor.py:103] Triton kernel JIT compilation during inference: copy_and_expand_dflash_inputs_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:21:02 [jit_monitor.py:103] Triton kernel JIT compilation during inference: batch_memcpy_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:21:03 [jit_monitor.py:103] Triton kernel JIT compilation during inference: expand_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 05-30 07:21:03 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_inputs_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 05-30 07:21:10 [loggers.py:271] Engine 000: Avg prompt throughput: 453.7 tokens/s, Avg generation throughput: 15.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 05-30 07:21:10 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.89, Accepted throughput: 0.36 tokens/s, Drafted throughput: 1.15 tokens/s, Accepted: 104 tokens, Drafted: 330 tokens, Per-position acceptance rate: 0.691, 0.491, 0.291, 0.182, 0.164, 0.073, Avg Draft acceptance rate: 31.5%
(APIServer pid=1) INFO 05-30 07:21:20 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.3:54522 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:22:50 [loggers.py:271] Engine 000: Avg prompt throughput: 131.0 tokens/s, Avg generation throughput: 19.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 36.2%
(APIServer pid=1) INFO 05-30 07:22:50 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 1.17 tokens/s, Drafted throughput: 4.32 tokens/s, Accepted: 117 tokens, Drafted: 432 tokens, Per-position acceptance rate: 0.708, 0.417, 0.236, 0.139, 0.069, 0.056, Avg Draft acceptance rate: 27.1%
(APIServer pid=1) INFO:     172.18.0.3:54532 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:23:00 [loggers.py:271] Engine 000: Avg prompt throughput: 399.4 tokens/s, Avg generation throughput: 54.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 40.2%
(APIServer pid=1) INFO 05-30 07:23:00 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 34.20 tokens/s, Drafted throughput: 119.99 tokens/s, Accepted: 342 tokens, Drafted: 1200 tokens, Per-position acceptance rate: 0.705, 0.445, 0.265, 0.145, 0.090, 0.060, Avg Draft acceptance rate: 28.5%
(APIServer pid=1) INFO 05-30 07:23:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 40.2%
(APIServer pid=1) INFO:     172.18.0.3:47504 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:44236 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:44252 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:44262 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:25:20 [loggers.py:271] Engine 000: Avg prompt throughput: 1075.1 tokens/s, Avg generation throughput: 27.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 50.5%
(APIServer pid=1) INFO 05-30 07:25:20 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 1.27 tokens/s, Drafted throughput: 4.11 tokens/s, Accepted: 178 tokens, Drafted: 576 tokens, Per-position acceptance rate: 0.688, 0.490, 0.333, 0.177, 0.094, 0.073, Avg Draft acceptance rate: 30.9%
(APIServer pid=1) INFO 05-30 07:25:30 [loggers.py:271] Engine 000: Avg prompt throughput: 142.4 tokens/s, Avg generation throughput: 12.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 57.5%
(APIServer pid=1) INFO 05-30 07:25:30 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.26, Accepted throughput: 8.80 tokens/s, Drafted throughput: 23.40 tokens/s, Accepted: 88 tokens, Drafted: 234 tokens, Per-position acceptance rate: 0.795, 0.513, 0.359, 0.256, 0.179, 0.154, Avg Draft acceptance rate: 37.6%
(APIServer pid=1) INFO 05-30 07:25:40 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 57.5%
(APIServer pid=1) INFO:     172.18.0.3:32872 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:26:20 [loggers.py:271] Engine 000: Avg prompt throughput: 472.7 tokens/s, Avg generation throughput: 30.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 56.9%
(APIServer pid=1) INFO 05-30 07:26:20 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.37, Accepted throughput: 3.56 tokens/s, Drafted throughput: 15.60 tokens/s, Accepted: 178 tokens, Drafted: 780 tokens, Per-position acceptance rate: 0.662, 0.354, 0.192, 0.123, 0.031, 0.008, Avg Draft acceptance rate: 22.8%
(APIServer pid=1) INFO 05-30 07:26:30 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 56.9%
(APIServer pid=1) INFO:     172.18.0.3:51538 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:27:10 [loggers.py:271] Engine 000: Avg prompt throughput: 161.0 tokens/s, Avg generation throughput: 11.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 60.9%
(APIServer pid=1) INFO 05-30 07:27:10 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 1.26 tokens/s, Drafted throughput: 6.00 tokens/s, Accepted: 63 tokens, Drafted: 300 tokens, Per-position acceptance rate: 0.540, 0.300, 0.200, 0.100, 0.080, 0.040, Avg Draft acceptance rate: 21.0%
(APIServer pid=1) INFO 05-30 07:27:20 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 60.9%
(APIServer pid=1) INFO 05-30 07:27:20 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.05, Accepted throughput: 23.10 tokens/s, Drafted throughput: 131.98 tokens/s, Accepted: 231 tokens, Drafted: 1320 tokens, Per-position acceptance rate: 0.582, 0.264, 0.114, 0.050, 0.032, 0.009, Avg Draft acceptance rate: 17.5%
(APIServer pid=1) INFO 05-30 07:27:30 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 3.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.9%
(APIServer pid=1) INFO 05-30 07:27:30 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.76, Accepted throughput: 1.60 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 16 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.476, 0.190, 0.095, 0.000, 0.000, 0.000, Avg Draft acceptance rate: 12.7%
(APIServer pid=1) INFO 05-30 07:27:40 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.9%
(APIServer pid=1) INFO:     172.18.0.3:52194 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:28:40 [loggers.py:271] Engine 000: Avg prompt throughput: 575.1 tokens/s, Avg generation throughput: 24.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 60.8%
(APIServer pid=1) INFO 05-30 07:28:40 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 5.15, Accepted throughput: 2.84 tokens/s, Drafted throughput: 4.11 tokens/s, Accepted: 199 tokens, Drafted: 288 tokens, Per-position acceptance rate: 0.938, 0.833, 0.708, 0.625, 0.542, 0.500, Avg Draft acceptance rate: 69.1%
(APIServer pid=1) INFO 05-30 07:28:50 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 101.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 60.8%
(APIServer pid=1) INFO 05-30 07:28:50 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 5.04, Accepted throughput: 81.29 tokens/s, Drafted throughput: 120.58 tokens/s, Accepted: 813 tokens, Drafted: 1206 tokens, Per-position acceptance rate: 0.871, 0.751, 0.692, 0.632, 0.562, 0.537, Avg Draft acceptance rate: 67.4%
(APIServer pid=1) INFO 05-30 07:29:00 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 34.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.8%
(APIServer pid=1) INFO 05-30 07:29:00 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.51, Accepted throughput: 24.80 tokens/s, Drafted throughput: 59.40 tokens/s, Accepted: 248 tokens, Drafted: 594 tokens, Per-position acceptance rate: 0.657, 0.545, 0.434, 0.333, 0.283, 0.253, Avg Draft acceptance rate: 41.8%
(APIServer pid=1) INFO 05-30 07:29:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 60.8%
(APIServer pid=1) INFO:     172.18.0.3:51730 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-30 07:30:30 [loggers.py:271] Engine 000: Avg prompt throughput: 230.1 tokens/s, Avg generation throughput: 28.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 64.5%
(APIServer pid=1) INFO 05-30 07:30:30 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.94, Accepted throughput: 2.04 tokens/s, Drafted throughput: 6.33 tokens/s, Accepted: 184 tokens, Drafted: 570 tokens, Per-position acceptance rate: 0.726, 0.432, 0.284, 0.211, 0.158, 0.126, Avg Draft acceptance rate: 32.3%
(APIServer pid=1) INFO 05-30 07:30:40 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 55.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 64.5%
(APIServer pid=1) INFO 05-30 07:30:40 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 35.19 tokens/s, Drafted throughput: 120.58 tokens/s, Accepted: 352 tokens, Drafted: 1206 tokens, Per-position acceptance rate: 0.602, 0.438, 0.274, 0.204, 0.139, 0.095, Avg Draft acceptance rate: 29.2%
(APIServer pid=1) INFO 05-30 07:30:50 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 56.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 64.5%
(APIServer pid=1) INFO 05-30 07:30:50 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 36.29 tokens/s, Drafted throughput: 119.98 tokens/s, Accepted: 363 tokens, Drafted: 1200 tokens, Per-position acceptance rate: 0.650, 0.435, 0.280, 0.195, 0.160, 0.095, Avg Draft acceptance rate: 30.2%
(APIServer pid=1) INFO 05-30 07:31:00 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 64.5%
(APIServer pid=1) INFO 05-30 07:31:00 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.48, Accepted throughput: 5.90 tokens/s, Drafted throughput: 24.00 tokens/s, Accepted: 59 tokens, Drafted: 240 tokens, Per-position acceptance rate: 0.550, 0.425, 0.200, 0.150, 0.100, 0.050, Avg Draft acceptance rate: 24.6%
(APIServer pid=1) INFO 05-30 07:31:10 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 64.5%
```
