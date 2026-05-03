# docker compose
```compose
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-aarch64-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    platform: linux/arm64
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
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      # Asynchronous CPU/GPU overlap for max speed
      # VLLM_USE_V2_MODEL_RUNNER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "Qwen3.6-35B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # --- MEMORY & CONTEXT ---
      # --gpu-memory-utilization: Fraction of GPU VRAM reserved for the model.
      #   0.90 = 90% of 32GB = ~28.8 GB available for model weights + KV cache.
      #   Higher values give more KV cache for longer context but risk OOM.
      #
      # --max-model-len: Maximum context length (prompt + response) in tokens.
      #   This is the maximum number of tokens that can be active in the KV cache
      #   at any time. 65536 = ~64K tokens = maximum context window.
      #   - Prompt tokens + response tokens must fit within this limit.
      #   - If you paste a 50K token document, the model can generate up to ~15K tokens.
      #   - Lower this value (e.g., 32768) to free up KV cache memory for other settings.
      #
      # --max-num-seqs: Maximum number of concurrent request sequences.
      #   Set to 1 for single-user mode (recommended to save memory).
      - "--gpu-memory-utilization"
      - "0.90"  
      - "--max-model-len"
      - "65536"
      - "--max-num-seqs"
      - "1"

      # --- BATCHING / PREFILL OPTIMIZATION ---
      # --max-num-batched-tokens controls how many tokens the model can process
      # during the prompt prefill phase (before generating output tokens).
      #
      # Higher values = faster prompt processing but more GPU memory consumed
      # for KV cache allocation. Lower values = slower prefill but more memory
      # available for context window.
      #
      # DGX Spark (Grace Blackwell) trade-offs observed:
      #   - 16384: Fastest prefill, but only 33k KV cache (OOM at 65k context)
      #   -  8192: Good balance, 75k KV cache (supports 65k context) ★ RECOMMENDED
      #   -  4096: Slowest prefill, but 75k+ KV cache (maximum context headroom)
      #
      # 8192 is the baseline for 65k context on this hardware.
      - "--max-num-batched-tokens"
      - "8192"

      # --- ARCHITECTURE & QUANTIZATION ---
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # --- KERNEL FUSION (The Speed Unlock) ---
      - "--moe-backend"
      - "cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # --- STARTUP OPTIMIZATIONS (Boot Faster) ---
      # Force disk I/O overlap
      - "--safetensors-load-strategy"
      - "prefetch"
      
      # Stop capturing useless batch graphs you won't use in single-user mode
      - "--max-cudagraph-capture-size"
      - "1"

    networks:
      - development-network

networks:
  development-network:
    external: true

```

# vllm log
WARNING 05-03 17:10:31 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299] 
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:299] 
(APIServer pid=1) INFO 05-03 17:10:31 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 65536, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.9, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 1, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 1, 'moe_backend': 'cutlass'}
(APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(APIServer pid=1) INFO 05-03 17:10:37 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
(APIServer pid=1) INFO 05-03 17:10:37 [nixl_utils.py:32] NIXL is available
(APIServer pid=1) INFO 05-03 17:10:38 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-03 17:10:38 [model.py:1680] Using max model len 65536
(APIServer pid=1) INFO 05-03 17:10:38 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 05-03 17:10:38 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
(APIServer pid=1) WARNING 05-03 17:10:38 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-03 17:10:38 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-03 17:10:38 [vllm.py:840] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-03 17:10:38 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(APIServer pid=1) INFO 05-03 17:10:40 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
INFO 05-03 17:10:55 [nixl_utils.py:32] NIXL is available
(EngineCore pid=125) INFO 05-03 17:10:55 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=65536, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 1, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
(EngineCore pid=125) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=125) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(EngineCore pid=125) INFO 05-03 17:10:58 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:54571 backend=nccl
(EngineCore pid=125) INFO 05-03 17:10:58 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=125) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=125) INFO 05-03 17:11:09 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
(EngineCore pid=125) INFO 05-03 17:11:09 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=125) INFO 05-03 17:11:09 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=125) INFO 05-03 17:11:09 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
(EngineCore pid=125) INFO 05-03 17:11:09 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=125) INFO 05-03 17:11:09 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=125) INFO 05-03 17:11:10 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
(EngineCore pid=125) INFO 05-03 17:11:12 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 87.35 GiB.
(EngineCore pid=125) INFO 05-03 17:11:12 [weight_utils.py:874] Prefetching checkpoint files into page cache started (in background)
(EngineCore pid=125) 
Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=125) INFO 05-03 17:11:13 [weight_utils.py:851] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=125) INFO 05-03 17:11:14 [weight_utils.py:851] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=125) INFO 05-03 17:11:34 [weight_utils.py:851] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=125) INFO 05-03 17:11:34 [weight_utils.py:869] Prefetching checkpoint files into page cache finished in 21.81s
(EngineCore pid=125) 
Loading safetensors checkpoint shards:  33% Completed | 1/3 [01:52<03:44, 112.01s/it]
(EngineCore pid=125) 
Loading safetensors checkpoint shards: 100% Completed | 3/3 [01:58<00:00, 31.36s/it]
(EngineCore pid=125)  
Loading safetensors checkpoint shards: 100% Completed | 3/3 [01:58<00:00, 39.42s/it]
(EngineCore pid=125) 
(EngineCore pid=125) INFO 05-03 17:13:10 [default_loader.py:384] Loading weights took 118.35 seconds
(EngineCore pid=125) INFO 05-03 17:13:10 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=125) INFO 05-03 17:13:12 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 121.519687 seconds
(EngineCore pid=125) INFO 05-03 17:13:12 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=125) INFO 05-03 17:13:12 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
(EngineCore pid=125) INFO 05-03 17:13:23 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/89f70b98b7/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=125) INFO 05-03 17:13:23 [backends.py:1128] Dynamo bytecode transform time: 4.05 s
(EngineCore pid=125) [rank0]:W0503 17:13:28.130000 125 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=125) INFO 05-03 17:13:29 [backends.py:376] Cache the graph of compile range (1, 8192) for later use
(EngineCore pid=125) INFO 05-03 17:13:50 [backends.py:391] Compiling a graph for compile range (1, 8192) takes 26.74 s
(EngineCore pid=125) INFO 05-03 17:13:52 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/91db3f8f18b4de70b0ce343da060acf2c81349e58f1f40272bbd68485e14e73a/rank_0_0/model
(EngineCore pid=125) INFO 05-03 17:13:52 [monitor.py:53] torch.compile took 33.09 s in total
(EngineCore pid=125) INFO 05-03 17:14:30 [monitor.py:81] Initial profiling/warmup run took 37.68 s
(EngineCore pid=125) INFO 05-03 17:14:30 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=1 (largest=1), FULL=1 (largest=1)
(EngineCore pid=125) INFO 05-03 17:14:32 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.43 GiB total
(EngineCore pid=125) INFO 05-03 17:14:33 [gpu_worker.py:440] Available KV cache memory: 82.42 GiB
(EngineCore pid=125) INFO 05-03 17:14:33 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.9000 is equivalent to --gpu-memory-utilization=0.8964 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.9036. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=125) INFO 05-03 17:14:33 [kv_cache_utils.py:1711] GPU KV cache size: 2,158,880 tokens
(EngineCore pid=125) INFO 05-03 17:14:33 [kv_cache_utils.py:1716] Maximum concurrency for 65,536 tokens per request: 108.50x
(EngineCore pid=125) 2026-05-03 17:14:40,528 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(EngineCore pid=125) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  86%|████████▌ | 12/14 [00:00<00:00, 109.64profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 94.71profile/s] 
(EngineCore pid=125) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  93%|█████████▎| 13/14 [00:00<00:00, 127.19profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 110.05profile/s]
(EngineCore pid=125) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  57%|█████▋    | 8/14 [00:00<00:00, 76.21profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 39.16profile/s]
(EngineCore pid=125) 
[AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
[AutoTuner]: Tuning fp4_gemm:  86%|████████▌ | 12/14 [00:00<00:00, 103.88profile/s]
[AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 73.15profile/s] 
(EngineCore pid=125) 2026-05-03 17:14:43,132 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
(EngineCore pid=125) 
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/1 [00:00<?, ?it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00,  9.87it/s]
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00,  9.86it/s]
(EngineCore pid=125) 
Capturing CUDA graphs (decode, FULL):   0%|          | 0/1 [00:00<?, ?it/s]
Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  4.04it/s]
Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  4.04it/s]
(EngineCore pid=125) INFO 05-03 17:14:44 [gpu_model_runner.py:6133] Graph capturing finished in 1 secs, took 0.64 GiB
(EngineCore pid=125) INFO 05-03 17:14:44 [gpu_worker.py:599] CUDA graph pool memory: 0.64 GiB (actual), 0.43 GiB (estimated), difference: 0.2 GiB (31.6%).
(EngineCore pid=125) INFO 05-03 17:14:44 [core.py:299] init engine (profile, create kv cache, warmup model) took 92.21 s (compilation: 33.09 s)
(EngineCore pid=125) INFO 05-03 17:14:44 [vllm.py:840] Asynchronous scheduling is enabled.
(EngineCore pid=125) INFO 05-03 17:14:44 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(EngineCore pid=125) INFO 05-03 17:14:44 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) INFO 05-03 17:14:46 [api_server.py:598] Supported tasks: ['generate']
(APIServer pid=1) WARNING 05-03 17:14:47 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-03 17:14:53 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-03 17:15:02 [base.py:233] Multi-modal warmup completed in 8.771s
(APIServer pid=1) INFO 05-03 17:15:09 [base.py:233] Readonly multi-modal warmup completed in 7.233s
(APIServer pid=1) INFO 05-03 17:15:10 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /docs, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-03 17:15:10 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
