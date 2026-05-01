# docker compsoe
```yml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
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

      # --- MEMORY & CONTEXT (The 64k God Mode) ---
      - "--gpu-memory-utilization"
      - "0.90"  
      - "--max-model-len"
      - "65536"
      - "--max-num-seqs"
      - "1"

      # --- BATCHING (Fast Prompt Processing) ---
      - "--max-num-batched-tokens"
      - "8192" # 8192 # 4096 #- "16384" 

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

2026-05-01 22:44:30.255 | WARNING 05-01 20:44:30 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 22:44:30.354 | WARNING 05-01 20:44:30 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299] 
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 22:44:30.355 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:299] 
2026-05-01 22:44:30.358 | (APIServer pid=1) INFO 05-01 20:44:30 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 65536, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.9, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 1, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 1, 'moe_backend': 'cutlass'}
2026-05-01 22:44:30.764 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 22:44:40.873 | (APIServer pid=1) INFO 05-01 20:44:40 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 22:44:40.905 | (APIServer pid=1) INFO 05-01 20:44:40 [nixl_utils.py:32] NIXL is available
2026-05-01 22:44:41.105 | (APIServer pid=1) INFO 05-01 20:44:41 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 22:44:41.105 | (APIServer pid=1) INFO 05-01 20:44:41 [model.py:1680] Using max model len 65536
2026-05-01 22:44:41.468 | (APIServer pid=1) INFO 05-01 20:44:41 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 22:44:41.468 | (APIServer pid=1) INFO 05-01 20:44:41 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-05-01 22:44:41.469 | (APIServer pid=1) WARNING 05-01 20:44:41 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 22:44:41.469 | (APIServer pid=1) INFO 05-01 20:44:41 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 22:44:41.469 | (APIServer pid=1) INFO 05-01 20:44:41 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 22:44:41.469 | (APIServer pid=1) INFO 05-01 20:44:41 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 22:44:44.243 | (APIServer pid=1) INFO 05-01 20:44:44 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 22:44:44.397 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 22:44:52.596 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 22:45:03.749 | INFO 05-01 20:45:03 [nixl_utils.py:32] NIXL is available
2026-05-01 22:45:03.814 | (EngineCore pid=187) INFO 05-01 20:45:03 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=65536, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 1, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 22:45:03.974 | (EngineCore pid=187) WARNING 05-01 20:45:03 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 22:45:04.091 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 22:45:04.379 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 22:45:07.065 | (EngineCore pid=187) INFO 05-01 20:45:07 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:57119 backend=nccl
2026-05-01 22:45:07.367 | (EngineCore pid=187) INFO 05-01 20:45:07 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 22:45:13.626 | (EngineCore pid=187) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 22:45:18.895 | (EngineCore pid=187) INFO 05-01 20:45:18 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 22:45:19.294 | (EngineCore pid=187) INFO 05-01 20:45:19 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 22:45:19.296 | (EngineCore pid=187) INFO 05-01 20:45:19 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 22:45:19.407 | (EngineCore pid=187) INFO 05-01 20:45:19 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 22:45:19.408 | (EngineCore pid=187) INFO 05-01 20:45:19 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 22:45:19.416 | (EngineCore pid=187) INFO 05-01 20:45:19 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 22:45:20.202 | (EngineCore pid=187) INFO 05-01 20:45:20 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 22:45:21.853 | (EngineCore pid=187) INFO 05-01 20:45:21 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.47 GiB.
2026-05-01 22:45:21.853 | (EngineCore pid=187) INFO 05-01 20:45:21 [weight_utils.py:874] Prefetching checkpoint files into page cache started (in background)
2026-05-01 22:45:21.854 | (EngineCore pid=187) 
2026-05-01 22:45:21.854 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-05-01 22:45:22.917 | (EngineCore pid=187) INFO 05-01 20:45:22 [weight_utils.py:851] Prefetching checkpoint files: 10% (1/3)
2026-05-01 22:45:23.558 | (EngineCore pid=187) INFO 05-01 20:45:23 [weight_utils.py:851] Prefetching checkpoint files: 20% (2/3)
2026-05-01 22:45:39.939 | (EngineCore pid=187) INFO 05-01 20:45:39 [weight_utils.py:851] Prefetching checkpoint files: 30% (3/3)
2026-05-01 22:45:39.941 | (EngineCore pid=187) INFO 05-01 20:45:39 [weight_utils.py:869] Prefetching checkpoint files into page cache finished in 17.92s
2026-05-01 22:45:49.213 | (EngineCore pid=187) 
2026-05-01 22:45:49.213 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:27<00:54, 27.36s/it]
2026-05-01 22:45:52.814 | (EngineCore pid=187) 
2026-05-01 22:45:52.814 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:30<00:00,  8.43s/it]
2026-05-01 22:45:52.814 | (EngineCore pid=187) 
2026-05-01 22:45:52.814 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:30<00:00, 10.32s/it]
2026-05-01 22:45:52.814 | (EngineCore pid=187) 
2026-05-01 22:45:52.944 | (EngineCore pid=187) INFO 05-01 20:45:52 [default_loader.py:384] Loading weights took 30.92 seconds
2026-05-01 22:45:53.096 | (EngineCore pid=187) INFO 05-01 20:45:53 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 22:45:53.672 | (EngineCore pid=187) INFO 05-01 20:45:53 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 33.868409 seconds
2026-05-01 22:45:53.673 | (EngineCore pid=187) INFO 05-01 20:45:53 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 22:45:54.063 | (EngineCore pid=187) INFO 05-01 20:45:54 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-05-01 22:46:13.236 | (EngineCore pid=187) INFO 05-01 20:46:13 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/cdd6b5ad4e/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 22:46:13.236 | (EngineCore pid=187) INFO 05-01 20:46:13 [backends.py:1128] Dynamo bytecode transform time: 7.58 s
2026-05-01 22:46:16.273 | (EngineCore pid=187) INFO 05-01 20:46:16 [backends.py:376] Cache the graph of compile range (1, 8192) for later use
2026-05-01 22:46:47.950 | (EngineCore pid=187) INFO 05-01 20:46:47 [backends.py:391] Compiling a graph for compile range (1, 8192) takes 34.06 s
2026-05-01 22:46:51.637 | (EngineCore pid=187) INFO 05-01 20:46:51 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/91db3f8f18b4de70b0ce343da060acf2c81349e58f1f40272bbd68485e14e73a/rank_0_0/model
2026-05-01 22:46:51.637 | (EngineCore pid=187) INFO 05-01 20:46:51 [monitor.py:53] torch.compile took 45.84 s in total
2026-05-01 22:47:42.240 | (EngineCore pid=187) INFO 05-01 20:47:42 [monitor.py:81] Initial profiling/warmup run took 49.91 s
2026-05-01 22:47:43.008 | (EngineCore pid=187) INFO 05-01 20:47:43 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=1 (largest=1), FULL=1 (largest=1)
2026-05-01 22:47:46.354 | (EngineCore pid=187) INFO 05-01 20:47:46 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.36 GiB total
2026-05-01 22:47:46.772 | (EngineCore pid=187) INFO 05-01 20:47:46 [gpu_worker.py:440] Available KV cache memory: 2.95 GiB
2026-05-01 22:47:46.772 | (EngineCore pid=187) INFO 05-01 20:47:46 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.9000 is equivalent to --gpu-memory-utilization=0.8886 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.9114. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 22:47:46.772 | (EngineCore pid=187) INFO 05-01 20:47:46 [kv_cache_utils.py:1711] GPU KV cache size: 75,456 tokens
2026-05-01 22:47:46.772 | (EngineCore pid=187) INFO 05-01 20:47:46 [kv_cache_utils.py:1716] Maximum concurrency for 65,536 tokens per request: 3.87x
2026-05-01 22:47:46.841 | (EngineCore pid=187) 2026-05-01 20:47:46,840 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 22:47:47.002 | (EngineCore pid=187) 
2026-05-01 22:47:47.002 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 22:47:47.002 | [AutoTuner]: Tuning fp4_gemm:  71%|███████▏  | 10/14 [00:00<00:00, 98.77profile/s]
2026-05-01 22:47:47.002 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 98.82profile/s]
2026-05-01 22:47:47.134 | (EngineCore pid=187) 
2026-05-01 22:47:47.134 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 22:47:47.134 | [AutoTuner]: Tuning fp4_gemm:  86%|████████▌ | 12/14 [00:00<00:00, 116.66profile/s]
2026-05-01 22:47:47.134 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 112.40profile/s]
2026-05-01 22:47:47.355 | (EngineCore pid=187) 
2026-05-01 22:47:47.355 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 22:47:47.355 | [AutoTuner]: Tuning fp4_gemm:  79%|███████▊  | 11/14 [00:00<00:00, 109.52profile/s]
2026-05-01 22:47:47.355 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 87.77profile/s] 
2026-05-01 22:47:47.499 | (EngineCore pid=187) 
2026-05-01 22:47:47.499 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 22:47:47.499 | [AutoTuner]: Tuning fp4_gemm:  79%|███████▊  | 11/14 [00:00<00:00, 107.05profile/s]
2026-05-01 22:47:47.499 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 98.81profile/s] 
2026-05-01 22:47:48.331 | (EngineCore pid=187) 2026-05-01 20:47:48,331 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 22:47:48.951 | (EngineCore pid=187) 
2026-05-01 22:47:48.951 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/1 [00:00<?, ?it/s]
2026-05-01 22:47:48.951 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00,  5.93it/s]
2026-05-01 22:47:48.951 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00,  5.93it/s]
2026-05-01 22:47:49.272 | (EngineCore pid=187) 
2026-05-01 22:47:49.272 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/1 [00:00<?, ?it/s]
2026-05-01 22:47:49.272 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  3.12it/s]
2026-05-01 22:47:49.272 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  3.12it/s]
2026-05-01 22:47:49.690 | (EngineCore pid=187) INFO 05-01 20:47:49 [gpu_model_runner.py:6133] Graph capturing finished in 1 secs, took 0.73 GiB
2026-05-01 22:47:49.690 | (EngineCore pid=187) INFO 05-01 20:47:49 [gpu_worker.py:599] CUDA graph pool memory: 0.73 GiB (actual), 0.36 GiB (estimated), difference: 0.36 GiB (50.1%).
2026-05-01 22:47:49.780 | (EngineCore pid=187) INFO 05-01 20:47:49 [core.py:299] init engine (profile, create kv cache, warmup model) took 116.11 s (compilation: 45.84 s)
2026-05-01 22:47:50.250 | (EngineCore pid=187) INFO 05-01 20:47:50 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 22:47:50.250 | (EngineCore pid=187) INFO 05-01 20:47:50 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 22:47:50.250 | (EngineCore pid=187) INFO 05-01 20:47:50 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 22:47:50.601 | (APIServer pid=1) INFO 05-01 20:47:50 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 22:47:50.968 | (APIServer pid=1) WARNING 05-01 20:47:50 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-01 22:47:56.533 | (APIServer pid=1) INFO 05-01 20:47:56 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 22:48:05.131 | (APIServer pid=1) INFO 05-01 20:48:05 [base.py:233] Multi-modal warmup completed in 8.569s
2026-05-01 22:48:13.371 | (APIServer pid=1) INFO 05-01 20:48:13 [base.py:233] Readonly multi-modal warmup completed in 8.191s
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:37] Available routes are:
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 22:48:13.676 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 22:48:13.677 | (APIServer pid=1) INFO 05-01 20:48:13 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 22:48:13.786 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 22:48:13.786 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 22:48:14.050 | (APIServer pid=1) INFO:     Application startup complete.