# docker compose
```yml
version: "3.9"

services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-stable
    hostname: gemma-4-26b-it-nvfp4
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
      # Model
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
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

      # NVFP4 MoE backend (performance path)
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

# vllm log
2026-04-24 00:37:36.166 | WARNING 04-23 22:37:36 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-24 00:37:36.270 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299] 
2026-04-24 00:37:36.270 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299]        █     █     █▄   ▄█
2026-04-24 00:37:36.271 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-24 00:37:36.271 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-24 00:37:36.271 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-24 00:37:36.271 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:299] 
2026-04-24 00:37:36.273 | (APIServer pid=1) INFO 04-23 22:37:36 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 256000, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 16384, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-24 00:37:36.452 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-24 00:37:47.168 | (APIServer pid=1) INFO 04-23 22:37:47 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-24 00:37:47.169 | (APIServer pid=1) INFO 04-23 22:37:47 [model.py:1685] Using max model len 256000
2026-04-24 00:37:47.593 | (APIServer pid=1) INFO 04-23 22:37:47 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-24 00:37:47.593 | (APIServer pid=1) INFO 04-23 22:37:47 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=16384.
2026-04-24 00:37:47.594 | (APIServer pid=1) INFO 04-23 22:37:47 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-24 00:37:47.594 | (APIServer pid=1) INFO 04-23 22:37:47 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-24 00:37:47.594 | (APIServer pid=1) INFO 04-23 22:37:47 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-24 00:37:51.088 | (APIServer pid=1) INFO 04-23 22:37:51 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-24 00:37:58.858 | (EngineCore pid=176) INFO 04-23 22:37:58 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=256000, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [16384], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-24 00:37:59.088 | (EngineCore pid=176) WARNING 04-23 22:37:59 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-24 00:37:59.400 | (EngineCore pid=176) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-24 00:38:02.974 | (EngineCore pid=176) INFO 04-23 22:38:02 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:60615 backend=nccl
2026-04-24 00:38:03.288 | (EngineCore pid=176) INFO 04-23 22:38:03 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-24 00:38:03.957 | (EngineCore pid=176) INFO 04-23 22:38:03 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-24 00:38:04.473 | (EngineCore pid=176) INFO 04-23 22:38:04 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-24 00:38:04.474 | (EngineCore pid=176) INFO 04-23 22:38:04 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-24 00:38:04.474 | (EngineCore pid=176) INFO 04-23 22:38:04 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-24 00:38:04.499 | (EngineCore pid=176) INFO 04-23 22:38:04 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-24 00:38:04.545 | (EngineCore pid=176) INFO 04-23 22:38:04 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-24 00:38:04.566 | (EngineCore pid=176) INFO 04-23 22:38:04 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-24 00:38:04.684 | (EngineCore pid=176) INFO 04-23 22:38:04 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-24 00:38:05.604 | (EngineCore pid=176) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-24 00:38:05.604 | (EngineCore pid=176) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-24 00:38:06.522 | (EngineCore pid=176) INFO 04-23 22:38:06 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 15.30 GiB. Available RAM: 57.46 GiB.
2026-04-24 00:38:06.522 | (EngineCore pid=176) INFO 04-23 22:38:06 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-24 00:38:06.523 | (EngineCore pid=176) 
2026-04-24 00:38:06.523 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-04-24 00:38:30.373 | (EngineCore pid=176) 
2026-04-24 00:38:30.373 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:23<00:00, 23.85s/it]
2026-04-24 00:38:30.373 | (EngineCore pid=176) 
2026-04-24 00:38:30.373 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:23<00:00, 23.85s/it]
2026-04-24 00:38:30.373 | (EngineCore pid=176) 
2026-04-24 00:38:31.157 | (EngineCore pid=176) INFO 04-23 22:38:31 [default_loader.py:384] Loading weights took 26.99 seconds
2026-04-24 00:38:31.389 | (EngineCore pid=176) INFO 04-23 22:38:31 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-24 00:38:31.415 | (EngineCore pid=176) WARNING 04-23 22:38:31 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
2026-04-24 00:38:32.113 | (EngineCore pid=176) INFO 04-23 22:38:32 [gpu_model_runner.py:4837] Model loading took 15.67 GiB memory and 29.741232 seconds
2026-04-24 00:38:32.377 | (EngineCore pid=176) INFO 04-23 22:38:32 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 6 video items of the maximum feature size.
2026-04-24 00:38:49.187 | (EngineCore pid=176) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-24 00:38:49.187 | (EngineCore pid=176)   warnings.warn(
2026-04-24 00:38:50.033 | (EngineCore pid=176) WARNING 04-23 22:38:50 [op.py:236] Priority not set for op rms_norm, using native implementation.
2026-04-24 00:39:12.278 | (EngineCore pid=176) INFO 04-23 22:39:12 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/03e199898d/rank_0_0/backbone for vLLM's torch.compile
2026-04-24 00:39:12.279 | (EngineCore pid=176) INFO 04-23 22:39:12 [backends.py:1137] Dynamo bytecode transform time: 12.31 s
2026-04-24 00:39:24.584 | (EngineCore pid=176) INFO 04-23 22:39:24 [backends.py:377] Cache the graph of compile range (1, 16384) for later use
2026-04-24 00:39:54.431 | (EngineCore pid=176) INFO 04-23 22:39:54 [backends.py:398] Compiling a graph for compile range (1, 16384) takes 45.67 s
2026-04-24 00:40:00.165 | (EngineCore pid=176) INFO 04-23 22:40:00 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/64af2851a3da79fae799143d9a58be2b65f28d2e64ebce66973afa09746f84a3/rank_0_0/model
2026-04-24 00:40:00.165 | (EngineCore pid=176) INFO 04-23 22:40:00 [monitor.py:48] torch.compile took 64.81 s in total
2026-04-24 00:40:02.880 | (EngineCore pid=176) INFO 04-23 22:40:02 [monitor.py:76] Initial profiling/warmup run took 2.72 s
2026-04-24 00:40:03.418 | (EngineCore pid=176) INFO 04-23 22:40:03 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=4
2026-04-24 00:40:03.424 | (EngineCore pid=176) INFO 04-23 22:40:03 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=2 (largest=2)
2026-04-24 00:40:09.429 | (EngineCore pid=176) INFO 04-23 22:40:09 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.26 GiB total
2026-04-24 00:40:09.899 | (EngineCore pid=176) INFO 04-23 22:40:09 [gpu_worker.py:436] Available KV cache memory: 7.15 GiB
2026-04-24 00:40:09.899 | (EngineCore pid=176) INFO 04-23 22:40:09 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.8500 to 0.8582 to maintain the same effective KV cache size.
2026-04-24 00:40:09.899 | (EngineCore pid=176) INFO 04-23 22:40:09 [kv_cache_utils.py:1319] GPU KV cache size: 62,496 tokens
2026-04-24 00:40:09.899 | (EngineCore pid=176) INFO 04-23 22:40:09 [kv_cache_utils.py:1324] Maximum concurrency for 256,000 tokens per request: 1.74x
2026-04-24 00:40:10.078 | (EngineCore pid=176) 2026-04-23 22:40:10,077 - INFO - autotuner.py:446 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-04-24 00:40:12.238 | (EngineCore pid=176) 2026-04-23 22:40:12,238 - INFO - autotuner.py:455 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-04-24 00:40:13.224 | (EngineCore pid=176) 
2026-04-24 00:40:13.224 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-04-24 00:40:13.224 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  6.42it/s]
2026-04-24 00:40:13.224 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 2/3 [00:00<00:00,  6.74it/s]
2026-04-24 00:40:13.224 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  6.89it/s]
2026-04-24 00:40:13.224 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  6.81it/s]
2026-04-24 00:40:13.524 | (EngineCore pid=176) 
2026-04-24 00:40:13.524 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/2 [00:00<?, ?it/s]
2026-04-24 00:40:13.524 | Capturing CUDA graphs (decode, FULL):  50%|█████     | 1/2 [00:00<00:00,  7.01it/s]
2026-04-24 00:40:13.524 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  6.61it/s]
2026-04-24 00:40:13.524 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  6.66it/s]
2026-04-24 00:40:13.996 | (EngineCore pid=176) INFO 04-23 22:40:13 [gpu_model_runner.py:6086] Graph capturing finished in 2 secs, took 0.26 GiB
2026-04-24 00:40:13.996 | (EngineCore pid=176) INFO 04-23 22:40:13 [gpu_worker.py:597] CUDA graph pool memory: 0.26 GiB (actual), 0.26 GiB (estimated), difference: 0.0 GiB (0.1%).
2026-04-24 00:40:14.074 | (EngineCore pid=176) INFO 04-23 22:40:14 [core.py:299] init engine (profile, create kv cache, warmup model) took 101.96 s (compilation: 57.98 s)
2026-04-24 00:40:14.607 | (EngineCore pid=176) INFO 04-23 22:40:14 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-24 00:40:14.625 | (APIServer pid=1) INFO 04-23 22:40:14 [api_server.py:598] Supported tasks: ['generate']
2026-04-24 00:40:15.042 | (APIServer pid=1) WARNING 04-23 22:40:15 [model.py:1442] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 64, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-04-24 00:40:19.605 | (APIServer pid=1) INFO 04-23 22:40:19 [hf.py:314] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
2026-04-24 00:40:36.578 | (APIServer pid=1) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-24 00:40:36.578 | (APIServer pid=1)   warnings.warn(
2026-04-24 00:40:36.731 | (APIServer pid=1) INFO 04-23 22:40:36 [base.py:245] Multi-modal warmup completed in 17.030s
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:37] Available routes are:
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /docs, Methods: GET, HEAD
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /tokenize, Methods: POST
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /detokenize, Methods: POST
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /load, Methods: GET
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /version, Methods: GET
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /health, Methods: GET
2026-04-24 00:40:36.996 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /metrics, Methods: GET
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/models, Methods: GET
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /ping, Methods: GET
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /ping, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /invocations, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-04-24 00:40:36.997 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-04-24 00:40:36.998 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-04-24 00:40:36.998 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-04-24 00:40:36.998 | (APIServer pid=1) INFO 04-23 22:40:36 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-04-24 00:40:37.102 | (APIServer pid=1) INFO:     Started server process [1]
2026-04-24 00:40:37.102 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-04-24 00:40:37.389 | (APIServer pid=1) INFO:     Application startup complete.