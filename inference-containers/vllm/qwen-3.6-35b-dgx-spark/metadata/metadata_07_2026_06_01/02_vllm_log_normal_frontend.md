# docker compose 
```yml
services:
  qwen36-35b-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen36-35b-nvfp4-nightly
    hostname: inference-server
    platform: linux/arm64
    # ports are not exposed.
    # use the nginx/nginx-vllm-reverse-proxy-dgx-spark/nginx.conf to speak with the model
    # ports:
      # - "8000:8000"
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
      # NVIDIA DGX Spark specific env vars
      VLLM_USE_FLASHINFER_MOE_FP4: "0"
      VLLM_FP8_MOE_BACKEND: flashinfer_cutlass
      FLASHINFER_DISABLE_VERSION_CHECK: "1"
      CUTE_DSL_ARCH: sm_121a
      # Rust frontend disabled — doesn't support api_key yet
      VLLM_USE_RUST_FRONTEND: "0"

    command:
      - "--model"
      - "nvidia/Qwen3.6-35B-A3B-NVFP4"
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
      # NVFP4 is ~3x smaller than BF16, MoE only 3B active params.
      # Model weights ~7-9 GB. KV cache per session at 262K with fp8 ~2-4 GB.
      # 5 sessions × 4 GB + 9 GB model = ~29 GB. Spark has 128GB UMA.
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "5"

      # --- BATCHING / PREFILL OPTIMIZATION ---
      - "--max-num-batched-tokens"
      - "8192"

      # --- ARCHITECTURE & QUANTIZATION ---
      - "--kv-cache-dtype"
      - "fp8"
      - "--dtype"
      - "auto"
      - "--quantization"
      - "modelopt"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--enable-auto-tool-choice"

      # --- BACKENDS (NVIDIA Spark recommendations) ---
      - "--attention-backend"
      - "flashinfer"
      - "--moe-backend"
      - "marlin"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"

      # --- STARTUP OPTIMIZATIONS ---
      - "--safetensors-load-strategy"
      - "prefetch"

      # --- SPECULATIVE DECODING (MTP) ---
      # MTP on a 3B active / 35B total MoE is hit-or-miss in vLLM.
      # 1-2 tokens max — 3+ wastes compute on low-quality predictions.
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":2,"moe_backend":"triton"}'

    networks:
      - development-network

networks:
  development-network:
    external: true

```


# Vllm log

```log
base) sono99@spark-8ddc:~/dev/DockerBuildFiles/inference-containers/vllm/qwen-3.6-35b-dgx-spark/nvidia-nvfp4(master)$ cat  vllm_log_dump.txt 
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
WARNING 06-01 21:51:24 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344] 
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344]        █     █     █▄   ▄█
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.22.1rc1.dev26+g4721bb3aa
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344]   █▄█▀ █     █     █     █  model   nvidia/Qwen3.6-35B-A3B-NVFP4
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:344] 
(APIServer pid=1) INFO 06-01 21:51:24 [utils.py:278] non-default args: {'model_tag': 'nvidia/Qwen3.6-35B-A3B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'nvidia/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'modelopt', 'served_model_name': ['qwen3.6-35b'], 'safetensors_load_strategy': 'prefetch', 'attention_backend': 'flashinfer', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 5, 'enable_chunked_prefill': True, 'async_scheduling': True, 'moe_backend': 'marlin', 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 2, 'moe_backend': 'triton'}}
(APIServer pid=1) WARNING 06-01 21:51:24 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_FP8_MOE_BACKEND
(APIServer pid=1) WARNING 06-01 21:51:24 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
(APIServer pid=1) WARNING 06-01 21:51:24 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
(APIServer pid=1) WARNING 06-01 21:51:24 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_URL
(APIServer pid=1) WARNING 06-01 21:51:24 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
(APIServer pid=1) INFO 06-01 21:51:34 [model.py:617] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 06-01 21:51:34 [model.py:1751] Using max model len 262144
(APIServer pid=1) INFO 06-01 21:51:34 [cache.py:269] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 06-01 21:51:39 [model.py:617] Resolved architecture: Qwen3_5MoeMTP
(APIServer pid=1) INFO 06-01 21:51:39 [model.py:1751] Using max model len 262144
(APIServer pid=1) WARNING 06-01 21:51:39 [speculative.py:722] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
(APIServer pid=1) INFO 06-01 21:51:39 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
(APIServer pid=1) WARNING 06-01 21:51:39 [config.py:355] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 06-01 21:51:39 [config.py:375] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) WARNING 06-01 21:51:39 [modelopt.py:379] Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change.
(APIServer pid=1) WARNING 06-01 21:51:39 [modelopt.py:1022] Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future.
(APIServer pid=1) WARNING 06-01 21:51:39 [modelopt.py:1022] Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future.
(APIServer pid=1) INFO 06-01 21:51:39 [vllm.py:984] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 06-01 21:51:39 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
/usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
  warnings.warn(
(EngineCore pid=282) INFO 06-01 21:51:57 [core.py:112] Initializing a V1 LLM engine (v0.22.1rc1.dev26+g4721bb3aa) with config: model='nvidia/Qwen3.6-35B-A3B-NVFP4', speculative_config=SpeculativeConfig(method='mtp', model='nvidia/Qwen3.6-35B-A3B-NVFP4', num_spec_tokens=2), tokenizer='nvidia/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_mixed, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-35b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 24, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='marlin', linear_backend='auto')
(EngineCore pid=282) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=282) INFO 06-01 21:51:59 [parallel_state.py:1422] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:55103 backend=nccl
(EngineCore pid=282) INFO 06-01 21:51:59 [parallel_state.py:1735] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=282) INFO 06-01 21:51:59 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
(EngineCore pid=282) WARNING 06-01 21:51:59 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=282) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=282) INFO 06-01 21:52:08 [gpu_model_runner.py:5036] Starting to load model nvidia/Qwen3.6-35B-A3B-NVFP4...
(EngineCore pid=282) INFO 06-01 21:52:09 [cuda.py:433] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=282) INFO 06-01 21:52:09 [mm_encoder_attention.py:372] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=282) INFO 06-01 21:52:09 [__init__.py:569] Selected FlashInferFP8ScaledMMLinearKernel for ModelOptFp8LinearMethod
(EngineCore pid=282) INFO 06-01 21:52:09 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel (requested=auto, head_k_dim=None).
(EngineCore pid=282) INFO 06-01 21:52:09 [nvfp4.py:231] Using 'MARLIN' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=282) INFO 06-01 21:52:09 [cuda.py:318] Using AttentionBackendEnum.FLASHINFER backend.
(EngineCore pid=282) INFO 06-01 21:52:10 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.82 GiB. Available RAM: 90.19 GiB.
(EngineCore pid=282) INFO 06-01 21:52:10 [weight_utils.py:884] Prefetching checkpoint files into page cache started (in background, num_threads=8, block_size=16777216 bytes)
Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=282) INFO 06-01 21:52:12 [weight_utils.py:856] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=282) INFO 06-01 21:52:22 [weight_utils.py:856] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=282) INFO 06-01 21:52:23 [weight_utils.py:856] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=282) INFO 06-01 21:52:23 [weight_utils.py:879] Prefetching checkpoint files into page cache finished in 12.20s
Loading safetensors checkpoint shards:  33% Completed | 1/3 [01:01<02:03, 61.73s/it]
Loading safetensors checkpoint shards:  67% Completed | 2/3 [02:01<01:00, 60.63s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:12<00:00, 37.80s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:12<00:00, 44.07s/it]
(EngineCore pid=282) 
(EngineCore pid=282) INFO 06-01 21:54:23 [default_loader.py:397] Loading weights took 132.27 seconds
(EngineCore pid=282) WARNING 06-01 21:54:23 [marlin.py:34] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
(EngineCore pid=282) WARNING 06-01 21:54:23 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
(EngineCore pid=282) INFO 06-01 21:54:23 [nvfp4.py:537] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=282) INFO 06-01 21:54:27 [gpu_model_runner.py:5060] Loading drafter model...
(EngineCore pid=282) INFO 06-01 21:54:27 [vllm.py:984] Asynchronous scheduling is enabled.
(EngineCore pid=282) INFO 06-01 21:54:27 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=282) INFO 06-01 21:54:27 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=282) INFO 06-01 21:54:27 [cuda.py:378] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
(EngineCore pid=282) INFO 06-01 21:54:27 [unquantized.py:212] Using TRITON Unquantized MoE backend out of potential backends: ['FlashInfer TRTLLM', 'FlashInfer CUTLASS', 'TRITON', 'BATCHED_TRITON'].
(EngineCore pid=282) INFO 06-01 21:54:28 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.82 GiB. Available RAM: 69.37 GiB.
(EngineCore pid=282) INFO 06-01 21:54:28 [weight_utils.py:884] Prefetching checkpoint files into page cache started (in background, num_threads=8, block_size=16777216 bytes)
Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=282) INFO 06-01 21:54:28 [weight_utils.py:856] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=282) INFO 06-01 21:54:29 [weight_utils.py:856] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=282) INFO 06-01 21:54:29 [weight_utils.py:856] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=282) INFO 06-01 21:54:29 [weight_utils.py:879] Prefetching checkpoint files into page cache finished in 1.05s
Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:08<00:17,  8.56s/it]
Loading safetensors checkpoint shards:  67% Completed | 2/3 [00:09<00:03,  3.80s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:18<00:00,  6.40s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:18<00:00,  6.18s/it]
(EngineCore pid=282) 
(EngineCore pid=282) INFO 06-01 21:54:46 [default_loader.py:397] Loading weights took 18.60 seconds
(EngineCore pid=282) INFO 06-01 21:54:46 [unquantized.py:341] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=282) INFO 06-01 21:54:46 [llm_base_proposer.py:1328] Detected MTP model. Sharing target model embedding weights with the draft model.
(EngineCore pid=282) INFO 06-01 21:54:46 [llm_base_proposer.py:1384] Detected MTP model. Sharing target model lm_head weights with the draft model.
(EngineCore pid=282) INFO 06-01 21:54:47 [gpu_model_runner.py:5131] Model loading took 21.93 GiB memory and 157.947632 seconds
(EngineCore pid=282) INFO 06-01 21:54:47 [interface.py:662] Setting attention block size to 2128 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=282) INFO 06-01 21:54:47 [gpu_model_runner.py:6140] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
(EngineCore pid=282) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
(EngineCore pid=282)   raw = getter()
(EngineCore pid=282) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
(EngineCore pid=282)   raw = getter()
(EngineCore pid=282) INFO 06-01 21:55:00 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/5aec4eb8dd/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=282) INFO 06-01 21:55:00 [backends.py:1148] Dynamo bytecode transform time: 6.03 s
(EngineCore pid=282) [rank0]:W0601 21:55:05.066000 282 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=282) INFO 06-01 21:55:05 [backends.py:378] Cache the graph of compile range (1, 8192) for later use
(EngineCore pid=282) INFO 06-01 21:55:24 [backends.py:393] Compiling a graph for compile range (1, 8192) takes 23.76 s
(EngineCore pid=282) INFO 06-01 21:55:26 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/7615180f372823664c5120dbcb328b1615a34a14df30ccf3429a6ef49c49917a/rank_0_0/model
(EngineCore pid=282) INFO 06-01 21:55:26 [monitor.py:53] torch.compile took 32.13 s in total
(EngineCore pid=282) INFO 06-01 21:55:59 [marlin_utils.py:437] Marlin kernel can achieve better performance for small size_n with experimental use_atomic_add feature. You can consider set environment variable VLLM_MARLIN_USE_ATOMIC_ADD to 1 if possible.
(EngineCore pid=282) INFO 06-01 21:56:02 [monitor.py:81] Initial profiling/warmup run took 36.20 s
(EngineCore pid=282) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
(EngineCore pid=282)   raw = getter()
(EngineCore pid=282) INFO 06-01 21:56:02 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/5aec4eb8dd/rank_0_0/eagle_head for vLLM's torch.compile
(EngineCore pid=282) INFO 06-01 21:56:02 [backends.py:1148] Dynamo bytecode transform time: 0.32 s
(EngineCore pid=282) INFO 06-01 21:56:08 [backends.py:393] Compiling a graph for compile range (1, 8192) takes 6.12 s
(EngineCore pid=282) INFO 06-01 21:56:08 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/d989fa34ec7800d80e446f8796391c881bb2a2567fabe9a9b02e9d44cacdfc1b/rank_0_0/model
(EngineCore pid=282) INFO 06-01 21:56:08 [monitor.py:53] torch.compile took 6.55 s in total
(EngineCore pid=282) WARNING 06-01 21:56:09 [fused_moe.py:1071] Using default MoE config. Performance might be sub-optimal! Config file not found at /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/configs/E=256,N=512,device_name=NVIDIA_GB10.json
(EngineCore pid=282) INFO 06-01 21:56:10 [monitor.py:81] Initial profiling/warmup run took 1.29 s
(EngineCore pid=282) WARNING 06-01 21:56:11 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=282) WARNING 06-01 21:56:11 [compilation.py:1416] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for attention backend FlashInferBackend (support: AttentionCGSupport.UNIFORM_SINGLE_TOKEN_DECODE); setting cudagraph_mode=PIECEWISE
(EngineCore pid=282) INFO 06-01 21:56:11 [gpu_model_runner.py:6283] Profiling CUDA graph memory: PIECEWISE=6 (largest=24)
(EngineCore pid=282) INFO 06-01 21:56:12 [gpu_model_runner.py:6369] Estimated CUDA graph memory: 0.19 GiB total
(EngineCore pid=282) INFO 06-01 21:56:13 [gpu_worker.py:469] Available KV cache memory: 74.76 GiB
(EngineCore pid=282) INFO 06-01 21:56:13 [gpu_worker.py:484] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8484 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8516. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=282) WARNING 06-01 21:56:13 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=282) INFO 06-01 21:56:13 [kv_cache_utils.py:1733] GPU KV cache size: 6,455,296 tokens
(EngineCore pid=282) INFO 06-01 21:56:13 [kv_cache_utils.py:1734] Maximum concurrency for 262,144 tokens per request: 24.62x
(EngineCore pid=282) 2026-06-01 21:56:18,575 - INFO - autotuner.py:615 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:07<00:00,  2.86profile/s]
(EngineCore pid=282) cudnn_handle created for device_id = 0
(EngineCore pid=282) 
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:06<00:00,  3.49profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 12.36profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 60.74profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 12.34profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 61.91profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:05<00:00,  4.05profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  9.61profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 23.93profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 23.73profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 16.95profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 23.62profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 23.41profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 27.84profile/s]
(EngineCore pid=282) 2026-06-01 21:56:40,742 - INFO - autotuner.py:634 - flashinfer.jit: [Autotuner]: Autotuning process ends
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 6/6 [00:01<00:00,  3.32it/s]
(EngineCore pid=282) INFO 06-01 21:56:43 [gpu_model_runner.py:6460] Graph capturing finished in 3 secs, took 0.30 GiB
(EngineCore pid=282) INFO 06-01 21:56:43 [gpu_worker.py:622] CUDA graph pool memory: 0.3 GiB (actual), 0.19 GiB (estimated), difference: 0.11 GiB (35.9%).
(EngineCore pid=282) INFO 06-01 21:56:43 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
(EngineCore pid=282) INFO 06-01 21:56:43 [core.py:302] init engine (profile, create kv cache, warmup model) took 116.49 s (compilation: 38.68 s)
(EngineCore pid=282) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:1999: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
(EngineCore pid=282)   return environment_variables[name]()
(EngineCore pid=282) INFO 06-01 21:56:44 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) INFO 06-01 21:56:44 [api_server.py:592] Supported tasks: ['generate']
(APIServer pid=1) INFO 06-01 21:56:44 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 06-01 21:56:44 [model.py:1508] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 06-01 21:56:48 [hf.py:488] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 06-01 21:57:01 [base.py:227] Multi-modal warmup completed in 12.806s
(APIServer pid=1) INFO 06-01 21:57:01 [base.py:227] Readonly multi-modal warmup completed in 0.323s
(APIServer pid=1) INFO 06-01 21:57:02 [api_server.py:596] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 06-01 21:57:02 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.3:57494 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=282) WARNING 06-01 22:00:44 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _zero_kv_blocks_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:44 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _compute_slot_mapping_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:44 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _copy_page_indices_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) 2026-06-01 22:00:44,885 - WARNING - autotuner.py:1121 - flashinfer.jit: [AutoTuner]: No tuned config covers fp8_gemm input_shapes=(torch.Size([1, 4256, 2048]), torch.Size([1, 2048, 12288]), torch.Size([]), torch.Size([]), torch.Size([1, 4256, 12288]), torch.Size([33554432])); falling back to runner=CutlassFp8GemmRunner tactic=-1.  This shape is outside the tuning bucket range -- expand tuning_buckets / max_num_tokens during the next tuning pass to avoid this perf cliff.
(EngineCore pid=282) WARNING 06-01 22:00:45 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _causal_conv1d_fwd_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) 2026-06-01 22:00:45,216 - WARNING - autotuner.py:1121 - flashinfer.jit: [AutoTuner]: No tuned config covers fp8_gemm input_shapes=(torch.Size([1, 4256, 4096]), torch.Size([1, 4096, 2048]), torch.Size([]), torch.Size([]), torch.Size([1, 4256, 2048]), torch.Size([33554432])); falling back to runner=CutlassFp8GemmRunner tactic=-1.  This shape is outside the tuning bucket range -- expand tuning_buckets / max_num_tokens during the next tuning pass to avoid this perf cliff.
(EngineCore pid=282) 2026-06-01 22:00:45,225 - WARNING - autotuner.py:1121 - flashinfer.jit: [AutoTuner]: No tuned config covers fp8_gemm input_shapes=(torch.Size([1, 4256, 2048]), torch.Size([1, 2048, 9216]), torch.Size([]), torch.Size([]), torch.Size([1, 4256, 9216]), torch.Size([33554432])); falling back to runner=CutlassFp8GemmRunner tactic=-1.  This shape is outside the tuning bucket range -- expand tuning_buckets / max_num_tokens during the next tuning pass to avoid this perf cliff.
(EngineCore pid=282) WARNING 06-01 22:00:45 [jit_monitor.py:103] Triton kernel JIT compilation during inference: postprocess_mamba_fused_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:46 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_next_token_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:46 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_step_slot_mapping_metadata_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:46 [jit_monitor.py:103] Triton kernel JIT compilation during inference: batch_memcpy_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:46 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _fused_post_conv_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:47 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _causal_conv1d_update_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: fused_sigmoid_gating_delta_rule_update_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: expand_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=282) WARNING 06-01 22:00:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_inputs_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO:     172.18.0.3:51286 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=282) WARNING 06-01 22:00:51 [jit_monitor.py:103] Triton kernel JIT compilation during inference: fused_moe_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 06-01 22:00:52 [loggers.py:271] Engine 000: Avg prompt throughput: 908.0 tokens/s, Avg generation throughput: 26.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 31.9%
(APIServer pid=1) INFO 06-01 22:00:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 0.68 tokens/s, Drafted throughput: 0.80 tokens/s, Accepted: 169 tokens, Drafted: 198 tokens, Per-position acceptance rate: 0.919, 0.788, Avg Draft acceptance rate: 85.4%
(APIServer pid=1) INFO 06-01 22:01:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 2.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 31.9%
(APIServer pid=1) INFO 06-01 22:01:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 1.70 tokens/s, Drafted throughput: 2.60 tokens/s, Accepted: 17 tokens, Drafted: 26 tokens, Per-position acceptance rate: 0.769, 0.538, Avg Draft acceptance rate: 65.4%
(APIServer pid=1) INFO 06-01 22:01:12 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 31.9%
(APIServer pid=1) INFO:     172.18.0.3:41966 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46276 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46296 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:02:12 [loggers.py:271] Engine 000: Avg prompt throughput: 6707.6 tokens/s, Avg generation throughput: 58.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 48.0%
(APIServer pid=1) INFO 06-01 22:02:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 5.16 tokens/s, Drafted throughput: 6.40 tokens/s, Accepted: 361 tokens, Drafted: 448 tokens, Per-position acceptance rate: 0.853, 0.759, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO 06-01 22:02:22 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 29.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 48.0%
(APIServer pid=1) INFO 06-01 22:02:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.56, Accepted throughput: 17.90 tokens/s, Drafted throughput: 23.00 tokens/s, Accepted: 179 tokens, Drafted: 230 tokens, Per-position acceptance rate: 0.835, 0.722, Avg Draft acceptance rate: 77.8%
(APIServer pid=1) INFO 06-01 22:02:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 48.0%
(APIServer pid=1) INFO:     172.18.0.3:58720 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:03:22 [loggers.py:271] Engine 000: Avg prompt throughput: 277.4 tokens/s, Avg generation throughput: 3.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.8%
(APIServer pid=1) INFO 06-01 22:03:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.24, Accepted throughput: 0.35 tokens/s, Drafted throughput: 0.57 tokens/s, Accepted: 21 tokens, Drafted: 34 tokens, Per-position acceptance rate: 0.765, 0.471, Avg Draft acceptance rate: 61.8%
(APIServer pid=1) INFO 06-01 22:03:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.8%
(APIServer pid=1) INFO:     172.18.0.3:57874 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:04:52 [loggers.py:271] Engine 000: Avg prompt throughput: 287.1 tokens/s, Avg generation throughput: 10.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 69.4%
(APIServer pid=1) INFO 06-01 22:04:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 0.67 tokens/s, Drafted throughput: 1.00 tokens/s, Accepted: 60 tokens, Drafted: 90 tokens, Per-position acceptance rate: 0.756, 0.578, Avg Draft acceptance rate: 66.7%
(APIServer pid=1) INFO:     172.18.0.3:57888 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:05:02 [loggers.py:271] Engine 000: Avg prompt throughput: 237.5 tokens/s, Avg generation throughput: 34.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 69.2%
(APIServer pid=1) INFO 06-01 22:05:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 22.20 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 222 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.929, 0.833, Avg Draft acceptance rate: 88.1%
(APIServer pid=1) INFO:     172.18.0.3:36708 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:05:12 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 69.2%
(APIServer pid=1) INFO:     172.18.0.3:38308 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:05:22 [loggers.py:271] Engine 000: Avg prompt throughput: 703.7 tokens/s, Avg generation throughput: 33.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 73.4%
(APIServer pid=1) INFO 06-01 22:05:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 10.10 tokens/s, Drafted throughput: 13.20 tokens/s, Accepted: 202 tokens, Drafted: 264 tokens, Per-position acceptance rate: 0.803, 0.727, Avg Draft acceptance rate: 76.5%
(APIServer pid=1) INFO 06-01 22:05:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 73.4%
(APIServer pid=1) INFO:     172.18.0.3:54846 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:54852 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:54854 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:54860 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=282) WARNING 06-01 22:10:50 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _topk_topp_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 06-01 22:10:52 [loggers.py:271] Engine 000: Avg prompt throughput: 907.6 tokens/s, Avg generation throughput: 21.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:10:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.60, Accepted throughput: 0.39 tokens/s, Drafted throughput: 0.49 tokens/s, Accepted: 130 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.852, 0.753, Avg Draft acceptance rate: 80.2%
(APIServer pid=1) INFO 06-01 22:11:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 1.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:11:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 1.20 tokens/s, Drafted throughput: 1.40 tokens/s, Accepted: 12 tokens, Drafted: 14 tokens, Per-position acceptance rate: 0.857, 0.857, Avg Draft acceptance rate: 85.7%
(APIServer pid=1) INFO 06-01 22:11:12 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO:     172.18.0.3:41502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41518 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41520 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41532 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41536 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:14:12 [loggers.py:271] Engine 000: Avg prompt throughput: 753.7 tokens/s, Avg generation throughput: 34.0 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 72.1%
(APIServer pid=1) INFO 06-01 22:14:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 1.14 tokens/s, Drafted throughput: 1.29 tokens/s, Accepted: 216 tokens, Drafted: 246 tokens, Per-position acceptance rate: 0.927, 0.829, Avg Draft acceptance rate: 87.8%
(APIServer pid=1) INFO:     172.18.0.3:46782 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46798 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46806 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:14:22 [loggers.py:271] Engine 000: Avg prompt throughput: 1321.7 tokens/s, Avg generation throughput: 132.5 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 71.4%
(APIServer pid=1) INFO 06-01 22:14:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 80.50 tokens/s, Drafted throughput: 103.80 tokens/s, Accepted: 805 tokens, Drafted: 1038 tokens, Per-position acceptance rate: 0.850, 0.701, Avg Draft acceptance rate: 77.6%
(APIServer pid=1) INFO 06-01 22:14:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 189.7 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 71.4%
(APIServer pid=1) INFO 06-01 22:14:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 105.68 tokens/s, Drafted throughput: 167.97 tokens/s, Accepted: 1057 tokens, Drafted: 1680 tokens, Per-position acceptance rate: 0.751, 0.507, Avg Draft acceptance rate: 62.9%
(APIServer pid=1) INFO 06-01 22:14:42 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 186.7 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 71.4%
(APIServer pid=1) INFO 06-01 22:14:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 104.29 tokens/s, Drafted throughput: 164.78 tokens/s, Accepted: 1043 tokens, Drafted: 1648 tokens, Per-position acceptance rate: 0.729, 0.536, Avg Draft acceptance rate: 63.3%
(APIServer pid=1) INFO:     172.18.0.3:49256 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:14:52 [loggers.py:271] Engine 000: Avg prompt throughput: 21.8 tokens/s, Avg generation throughput: 151.1 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 71.9%
(APIServer pid=1) INFO 06-01 22:14:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.11, Accepted throughput: 79.50 tokens/s, Drafted throughput: 143.00 tokens/s, Accepted: 795 tokens, Drafted: 1430 tokens, Per-position acceptance rate: 0.677, 0.435, Avg Draft acceptance rate: 55.6%
(APIServer pid=1) INFO:     172.18.0.3:49260 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49274 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:45602 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:15:02 [loggers.py:271] Engine 000: Avg prompt throughput: 525.4 tokens/s, Avg generation throughput: 120.6 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 72.4%
(APIServer pid=1) INFO 06-01 22:15:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.12, Accepted throughput: 63.70 tokens/s, Drafted throughput: 113.80 tokens/s, Accepted: 637 tokens, Drafted: 1138 tokens, Per-position acceptance rate: 0.657, 0.462, Avg Draft acceptance rate: 56.0%
(APIServer pid=1) INFO:     172.18.0.3:41420 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41434 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:15:12 [loggers.py:271] Engine 000: Avg prompt throughput: 384.2 tokens/s, Avg generation throughput: 110.7 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:15:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.12, Accepted throughput: 58.39 tokens/s, Drafted throughput: 104.58 tokens/s, Accepted: 584 tokens, Drafted: 1046 tokens, Per-position acceptance rate: 0.660, 0.457, Avg Draft acceptance rate: 55.8%
(APIServer pid=1) INFO 06-01 22:15:22 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 126.5 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:15:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.05, Accepted throughput: 64.69 tokens/s, Drafted throughput: 123.58 tokens/s, Accepted: 647 tokens, Drafted: 1236 tokens, Per-position acceptance rate: 0.639, 0.408, Avg Draft acceptance rate: 52.3%
(APIServer pid=1) INFO 06-01 22:15:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 120.2 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:15:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.11, Accepted throughput: 63.39 tokens/s, Drafted throughput: 113.98 tokens/s, Accepted: 634 tokens, Drafted: 1140 tokens, Per-position acceptance rate: 0.670, 0.442, Avg Draft acceptance rate: 55.6%
(APIServer pid=1) INFO 06-01 22:15:42 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 124.6 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 72.8%
(APIServer pid=1) INFO 06-01 22:15:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.21, Accepted throughput: 68.19 tokens/s, Drafted throughput: 112.79 tokens/s, Accepted: 682 tokens, Drafted: 1128 tokens, Per-position acceptance rate: 0.711, 0.498, Avg Draft acceptance rate: 60.5%
(APIServer pid=1) INFO:     172.18.0.3:59520 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:59534 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:59538 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:15:52 [loggers.py:271] Engine 000: Avg prompt throughput: 537.4 tokens/s, Avg generation throughput: 100.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 72.9%
(APIServer pid=1) INFO 06-01 22:15:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 56.00 tokens/s, Drafted throughput: 88.79 tokens/s, Accepted: 560 tokens, Drafted: 888 tokens, Per-position acceptance rate: 0.734, 0.527, Avg Draft acceptance rate: 63.1%
(APIServer pid=1) INFO:     172.18.0.3:41628 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41632 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41640 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:16:02 [loggers.py:271] Engine 000: Avg prompt throughput: 1259.7 tokens/s, Avg generation throughput: 74.0 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 73.1%
(APIServer pid=1) INFO 06-01 22:16:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 42.10 tokens/s, Drafted throughput: 64.20 tokens/s, Accepted: 421 tokens, Drafted: 642 tokens, Per-position acceptance rate: 0.741, 0.570, Avg Draft acceptance rate: 65.6%
(APIServer pid=1) INFO 06-01 22:16:12 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 86.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 73.1%
(APIServer pid=1) INFO 06-01 22:16:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 48.00 tokens/s, Drafted throughput: 76.20 tokens/s, Accepted: 480 tokens, Drafted: 762 tokens, Per-position acceptance rate: 0.714, 0.546, Avg Draft acceptance rate: 63.0%
(APIServer pid=1) INFO:     172.18.0.3:37680 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50834 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50842 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:16:22 [loggers.py:271] Engine 000: Avg prompt throughput: 448.2 tokens/s, Avg generation throughput: 56.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 74.3%
(APIServer pid=1) INFO 06-01 22:16:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.47, Accepted throughput: 33.60 tokens/s, Drafted throughput: 45.60 tokens/s, Accepted: 336 tokens, Drafted: 456 tokens, Per-position acceptance rate: 0.798, 0.675, Avg Draft acceptance rate: 73.7%
(APIServer pid=1) INFO:     172.18.0.3:50848 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:16:32 [loggers.py:271] Engine 000: Avg prompt throughput: 142.0 tokens/s, Avg generation throughput: 71.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 74.8%
(APIServer pid=1) INFO 06-01 22:16:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 40.79 tokens/s, Drafted throughput: 60.99 tokens/s, Accepted: 408 tokens, Drafted: 610 tokens, Per-position acceptance rate: 0.761, 0.577, Avg Draft acceptance rate: 66.9%
(APIServer pid=1) INFO 06-01 22:16:42 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 74.8%
(APIServer pid=1) INFO:     172.18.0.3:40130 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40144 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40154 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:22:02 [loggers.py:271] Engine 000: Avg prompt throughput: 124.0 tokens/s, Avg generation throughput: 31.1 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.7%, Prefix cache hit rate: 75.4%
(APIServer pid=1) INFO 06-01 22:22:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 0.59 tokens/s, Drafted throughput: 0.70 tokens/s, Accepted: 194 tokens, Drafted: 232 tokens, Per-position acceptance rate: 0.922, 0.750, Avg Draft acceptance rate: 83.6%
(APIServer pid=1) INFO:     172.18.0.3:40160 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40168 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50460 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50466 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50478 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:22:12 [loggers.py:271] Engine 000: Avg prompt throughput: 256.3 tokens/s, Avg generation throughput: 134.8 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 76.3%
(APIServer pid=1) INFO 06-01 22:22:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.59, Accepted throughput: 82.59 tokens/s, Drafted throughput: 103.98 tokens/s, Accepted: 826 tokens, Drafted: 1040 tokens, Per-position acceptance rate: 0.877, 0.712, Avg Draft acceptance rate: 79.4%
(APIServer pid=1) INFO:     172.18.0.3:52056 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:22:22 [loggers.py:271] Engine 000: Avg prompt throughput: 75.0 tokens/s, Avg generation throughput: 186.2 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 76.4%
(APIServer pid=1) INFO 06-01 22:22:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 108.48 tokens/s, Drafted throughput: 155.57 tokens/s, Accepted: 1085 tokens, Drafted: 1556 tokens, Per-position acceptance rate: 0.803, 0.591, Avg Draft acceptance rate: 69.7%
(APIServer pid=1) INFO:     172.18.0.3:52060 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:22:32 [loggers.py:271] Engine 000: Avg prompt throughput: 122.0 tokens/s, Avg generation throughput: 179.3 tokens/s, Running: 4 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 76.5%
(APIServer pid=1) INFO 06-01 22:22:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.32, Accepted throughput: 101.96 tokens/s, Drafted throughput: 154.74 tokens/s, Accepted: 1020 tokens, Drafted: 1548 tokens, Per-position acceptance rate: 0.775, 0.543, Avg Draft acceptance rate: 65.9%
(APIServer pid=1) INFO:     172.18.0.3:56826 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:22:42 [loggers.py:271] Engine 000: Avg prompt throughput: 209.5 tokens/s, Avg generation throughput: 157.9 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 76.5%
(APIServer pid=1) INFO 06-01 22:22:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 88.49 tokens/s, Drafted throughput: 139.18 tokens/s, Accepted: 885 tokens, Drafted: 1392 tokens, Per-position acceptance rate: 0.749, 0.523, Avg Draft acceptance rate: 63.6%
(APIServer pid=1) INFO 06-01 22:22:52 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 129.0 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 76.5%
(APIServer pid=1) INFO 06-01 22:22:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.13, Accepted throughput: 68.38 tokens/s, Drafted throughput: 121.17 tokens/s, Accepted: 684 tokens, Drafted: 1212 tokens, Per-position acceptance rate: 0.686, 0.442, Avg Draft acceptance rate: 56.4%
(APIServer pid=1) INFO 06-01 22:23:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 129.2 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 76.5%
(APIServer pid=1) INFO 06-01 22:23:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.12, Accepted throughput: 68.29 tokens/s, Drafted throughput: 121.78 tokens/s, Accepted: 683 tokens, Drafted: 1218 tokens, Per-position acceptance rate: 0.675, 0.447, Avg Draft acceptance rate: 56.1%
(APIServer pid=1) INFO 06-01 22:23:12 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 127.6 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 76.5%
(APIServer pid=1) INFO 06-01 22:23:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.11, Accepted throughput: 66.99 tokens/s, Drafted throughput: 121.18 tokens/s, Accepted: 670 tokens, Drafted: 1212 tokens, Per-position acceptance rate: 0.680, 0.426, Avg Draft acceptance rate: 55.3%
(APIServer pid=1) INFO:     172.18.0.3:33266 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:23:22 [loggers.py:271] Engine 000: Avg prompt throughput: 170.8 tokens/s, Avg generation throughput: 122.9 tokens/s, Running: 3 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO 06-01 22:23:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.19, Accepted throughput: 66.69 tokens/s, Drafted throughput: 112.39 tokens/s, Accepted: 667 tokens, Drafted: 1124 tokens, Per-position acceptance rate: 0.705, 0.482, Avg Draft acceptance rate: 59.3%
(APIServer pid=1) INFO:     172.18.0.3:33276 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:23:32 [loggers.py:271] Engine 000: Avg prompt throughput: 183.4 tokens/s, Avg generation throughput: 125.0 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 76.7%
(APIServer pid=1) INFO 06-01 22:23:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 69.89 tokens/s, Drafted throughput: 110.19 tokens/s, Accepted: 699 tokens, Drafted: 1102 tokens, Per-position acceptance rate: 0.748, 0.521, Avg Draft acceptance rate: 63.4%
(APIServer pid=1) INFO 06-01 22:23:42 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 119.7 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 76.7%
(APIServer pid=1) INFO 06-01 22:23:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.13, Accepted throughput: 63.49 tokens/s, Drafted throughput: 112.39 tokens/s, Accepted: 635 tokens, Drafted: 1124 tokens, Per-position acceptance rate: 0.680, 0.450, Avg Draft acceptance rate: 56.5%
(APIServer pid=1) INFO:     172.18.0.3:53188 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:23:52 [loggers.py:271] Engine 000: Avg prompt throughput: 109.4 tokens/s, Avg generation throughput: 117.9 tokens/s, Running: 2 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 76.9%
(APIServer pid=1) INFO 06-01 22:23:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.28, Accepted throughput: 66.29 tokens/s, Drafted throughput: 103.38 tokens/s, Accepted: 663 tokens, Drafted: 1034 tokens, Per-position acceptance rate: 0.754, 0.528, Avg Draft acceptance rate: 64.1%
(APIServer pid=1) INFO:     172.18.0.3:53190 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41116 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41120 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:24:02 [loggers.py:271] Engine 000: Avg prompt throughput: 715.7 tokens/s, Avg generation throughput: 91.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 76.7%
(APIServer pid=1) INFO 06-01 22:24:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 54.79 tokens/s, Drafted throughput: 73.19 tokens/s, Accepted: 548 tokens, Drafted: 732 tokens, Per-position acceptance rate: 0.820, 0.678, Avg Draft acceptance rate: 74.9%
(APIServer pid=1) INFO 06-01 22:24:12 [loggers.py:271] Engine 000: Avg prompt throughput: 401.5 tokens/s, Avg generation throughput: 24.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO 06-01 22:24:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.21, Accepted throughput: 13.50 tokens/s, Drafted throughput: 22.40 tokens/s, Accepted: 135 tokens, Drafted: 224 tokens, Per-position acceptance rate: 0.688, 0.518, Avg Draft acceptance rate: 60.3%
(APIServer pid=1) INFO 06-01 22:24:22 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO:     172.18.0.3:51588 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:24:42 [loggers.py:271] Engine 000: Avg prompt throughput: 215.6 tokens/s, Avg generation throughput: 1.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO 06-01 22:24:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 0.27 tokens/s, Drafted throughput: 0.27 tokens/s, Accepted: 8 tokens, Drafted: 8 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:51596 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:48862 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:24:52 [loggers.py:271] Engine 000: Avg prompt throughput: 533.8 tokens/s, Avg generation throughput: 74.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO 06-01 22:24:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.66, Accepted throughput: 46.70 tokens/s, Drafted throughput: 56.40 tokens/s, Accepted: 467 tokens, Drafted: 564 tokens, Per-position acceptance rate: 0.865, 0.791, Avg Draft acceptance rate: 82.8%
(APIServer pid=1) INFO:     172.18.0.3:48874 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:58240 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:02 [loggers.py:271] Engine 000: Avg prompt throughput: 782.9 tokens/s, Avg generation throughput: 73.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 76.3%
(APIServer pid=1) INFO 06-01 22:25:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.59, Accepted throughput: 45.20 tokens/s, Drafted throughput: 57.00 tokens/s, Accepted: 452 tokens, Drafted: 570 tokens, Per-position acceptance rate: 0.849, 0.737, Avg Draft acceptance rate: 79.3%
(APIServer pid=1) INFO:     172.18.0.3:48276 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:48280 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:48294 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:12 [loggers.py:271] Engine 000: Avg prompt throughput: 126.8 tokens/s, Avg generation throughput: 69.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 76.9%
(APIServer pid=1) INFO 06-01 22:25:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.42, Accepted throughput: 41.00 tokens/s, Drafted throughput: 57.79 tokens/s, Accepted: 410 tokens, Drafted: 578 tokens, Per-position acceptance rate: 0.772, 0.647, Avg Draft acceptance rate: 70.9%
(APIServer pid=1) INFO:     172.18.0.3:52514 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:22 [loggers.py:271] Engine 000: Avg prompt throughput: 231.5 tokens/s, Avg generation throughput: 71.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 77.4%
(APIServer pid=1) INFO 06-01 22:25:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.35, Accepted throughput: 41.00 tokens/s, Drafted throughput: 60.60 tokens/s, Accepted: 410 tokens, Drafted: 606 tokens, Per-position acceptance rate: 0.746, 0.607, Avg Draft acceptance rate: 67.7%
(APIServer pid=1) INFO:     172.18.0.3:52526 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:36896 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:36912 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:36916 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:32 [loggers.py:271] Engine 000: Avg prompt throughput: 638.3 tokens/s, Avg generation throughput: 55.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 78.2%
(APIServer pid=1) INFO 06-01 22:25:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.40, Accepted throughput: 32.40 tokens/s, Drafted throughput: 46.19 tokens/s, Accepted: 324 tokens, Drafted: 462 tokens, Per-position acceptance rate: 0.766, 0.636, Avg Draft acceptance rate: 70.1%
(APIServer pid=1) INFO:     172.18.0.3:36924 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40710 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:40720 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:42 [loggers.py:271] Engine 000: Avg prompt throughput: 229.2 tokens/s, Avg generation throughput: 68.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 78.7%
(APIServer pid=1) INFO 06-01 22:25:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 39.80 tokens/s, Drafted throughput: 57.40 tokens/s, Accepted: 398 tokens, Drafted: 574 tokens, Per-position acceptance rate: 0.767, 0.620, Avg Draft acceptance rate: 69.3%
(APIServer pid=1) INFO:     172.18.0.3:36256 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-01 22:25:52 [loggers.py:271] Engine 000: Avg prompt throughput: 340.2 tokens/s, Avg generation throughput: 63.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.0%
(APIServer pid=1) INFO 06-01 22:25:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.13, Accepted throughput: 33.40 tokens/s, Drafted throughput: 59.20 tokens/s, Accepted: 334 tokens, Drafted: 592 tokens, Per-position acceptance rate: 0.655, 0.473, Avg Draft acceptance rate: 56.4%
(APIServer pid=1) INFO 06-01 22:26:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 79.0%
```