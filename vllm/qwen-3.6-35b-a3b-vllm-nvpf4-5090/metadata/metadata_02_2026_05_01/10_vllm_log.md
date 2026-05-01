# managed to get it to boot up with culass 


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
      # 1. FIX: REMOVED `expandable_segments:True`
      # We need PyTorch to keep memory contiguous so the TMA hardware 
      # can map the Cutlass FP4 kernels without crashing.
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      # Critical for very large KV-cache allocations
      PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      
      # VLLM_USE_V2_MODEL_RUNNER: "1"
      # 2. FIX: Turn autotuning BACK ON so it can find the native hardware paths
      # FLASHINFER_AUTOTUNE: "1"

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

      # 3. Memory budget set to standard safe levels
      - "--gpu-memory-utilization"
      - "0.90"  

      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "4"
      - "--max-num-batched-tokens"
      - "4096" 

      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # 4. FIX: Use Red Hat's specific hybrid backend
      - "--moe-backend"
      # - "flashinfer_cutlass" # mandated by redhat.
      - "cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 5. Bring back CUDA graphs to eliminate CPU bottlenecks
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log 

2026-05-01 21:34:18.930 | WARNING 05-01 19:34:18 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:34:19.032 | WARNING 05-01 19:34:19 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299] 
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 21:34:19.036 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:299] 
2026-05-01 21:34:19.039 | (APIServer pid=1) INFO 05-01 19:34:19 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.9, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 4096, 'max_num_seqs': 4, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 4, 'moe_backend': 'cutlass'}
2026-05-01 21:34:19.196 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:34:30.514 | (APIServer pid=1) INFO 05-01 19:34:30 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 21:34:30.548 | (APIServer pid=1) INFO 05-01 19:34:30 [nixl_utils.py:32] NIXL is available
2026-05-01 21:34:30.737 | (APIServer pid=1) INFO 05-01 19:34:30 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 21:34:30.737 | (APIServer pid=1) INFO 05-01 19:34:30 [model.py:1680] Using max model len 8192
2026-05-01 21:34:31.147 | (APIServer pid=1) INFO 05-01 19:34:31 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 21:34:31.148 | (APIServer pid=1) INFO 05-01 19:34:31 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=4096.
2026-05-01 21:34:31.148 | (APIServer pid=1) WARNING 05-01 19:34:31 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 21:34:31.148 | (APIServer pid=1) INFO 05-01 19:34:31 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 21:34:31.149 | (APIServer pid=1) INFO 05-01 19:34:31 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:34:31.149 | (APIServer pid=1) INFO 05-01 19:34:31 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:34:33.870 | (APIServer pid=1) INFO 05-01 19:34:33 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:34:34.034 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:34:42.263 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:34:53.861 | INFO 05-01 19:34:53 [nixl_utils.py:32] NIXL is available
2026-05-01 21:34:53.940 | (EngineCore pid=187) INFO 05-01 19:34:53 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [4096], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 21:34:54.164 | (EngineCore pid=187) WARNING 05-01 19:34:54 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:34:54.333 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:34:54.805 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:34:58.076 | (EngineCore pid=187) INFO 05-01 19:34:58 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:38841 backend=nccl
2026-05-01 21:34:58.395 | (EngineCore pid=187) INFO 05-01 19:34:58 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 21:35:05.523 | (EngineCore pid=187) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:35:11.884 | (EngineCore pid=187) INFO 05-01 19:35:11 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 21:35:12.351 | (EngineCore pid=187) INFO 05-01 19:35:12 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 21:35:12.352 | (EngineCore pid=187) INFO 05-01 19:35:12 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 21:35:12.465 | (EngineCore pid=187) INFO 05-01 19:35:12 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 21:35:12.467 | (EngineCore pid=187) INFO 05-01 19:35:12 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 21:35:12.477 | (EngineCore pid=187) INFO 05-01 19:35:12 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 21:35:13.387 | (EngineCore pid=187) INFO 05-01 19:35:13 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 21:35:15.285 | (EngineCore pid=187) INFO 05-01 19:35:15 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.66 GiB.
2026-05-01 21:35:15.285 | (EngineCore pid=187) INFO 05-01 19:35:15 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 21:35:15.286 | (EngineCore pid=187) 
2026-05-01 21:35:15.286 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-05-01 21:36:09.624 | (EngineCore pid=187) 
2026-05-01 21:36:09.624 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:54<01:48, 54.34s/it]
2026-05-01 21:36:11.841 | (EngineCore pid=187) 
2026-05-01 21:36:11.841 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:56<00:00, 14.91s/it]
2026-05-01 21:36:11.841 | (EngineCore pid=187) 
2026-05-01 21:36:11.841 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:56<00:00, 18.85s/it]
2026-05-01 21:36:11.841 | (EngineCore pid=187) 
2026-05-01 21:36:11.889 | (EngineCore pid=187) INFO 05-01 19:36:11 [default_loader.py:384] Loading weights took 56.40 seconds
2026-05-01 21:36:12.134 | (EngineCore pid=187) INFO 05-01 19:36:12 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 21:36:12.961 | (EngineCore pid=187) INFO 05-01 19:36:12 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 59.860567 seconds
2026-05-01 21:36:12.962 | (EngineCore pid=187) INFO 05-01 19:36:12 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 21:36:13.280 | (EngineCore pid=187) INFO 05-01 19:36:13 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-05-01 21:36:34.460 | (EngineCore pid=187) INFO 05-01 19:36:34 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/7c10152ca9/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 21:36:34.461 | (EngineCore pid=187) INFO 05-01 19:36:34 [backends.py:1128] Dynamo bytecode transform time: 8.38 s
2026-05-01 21:36:37.951 | (EngineCore pid=187) INFO 05-01 19:36:37 [backends.py:376] Cache the graph of compile range (1, 4096) for later use
2026-05-01 21:37:13.645 | (EngineCore pid=187) INFO 05-01 19:37:13 [backends.py:391] Compiling a graph for compile range (1, 4096) takes 38.41 s
2026-05-01 21:37:17.848 | (EngineCore pid=187) INFO 05-01 19:37:17 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/9eefdb871fc1f9b40a369709d53c561afe2853ee004b24228333bddf8dafbb7f/rank_0_0/model
2026-05-01 21:37:17.848 | (EngineCore pid=187) INFO 05-01 19:37:17 [monitor.py:53] torch.compile took 51.57 s in total
2026-05-01 21:38:09.615 | (EngineCore pid=187) INFO 05-01 19:38:09 [monitor.py:81] Initial profiling/warmup run took 51.57 s
2026-05-01 21:38:10.423 | (EngineCore pid=187) INFO 05-01 19:38:10 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=3 (largest=4)
2026-05-01 21:38:13.770 | (EngineCore pid=187) INFO 05-01 19:38:13 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.45 GiB total
2026-05-01 21:38:14.202 | (EngineCore pid=187) INFO 05-01 19:38:14 [gpu_worker.py:440] Available KV cache memory: 2.95 GiB
2026-05-01 21:38:14.202 | (EngineCore pid=187) INFO 05-01 19:38:14 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.9000 is equivalent to --gpu-memory-utilization=0.8859 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.9141. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 21:38:14.203 | (EngineCore pid=187) INFO 05-01 19:38:14 [kv_cache_utils.py:1711] GPU KV cache size: 75,456 tokens
2026-05-01 21:38:14.203 | (EngineCore pid=187) INFO 05-01 19:38:14 [kv_cache_utils.py:1716] Maximum concurrency for 8,192 tokens per request: 14.70x
2026-05-01 21:38:14.257 | (EngineCore pid=187) 2026-05-01 19:38:14,257 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 21:38:14.408 | (EngineCore pid=187) 
2026-05-01 21:38:14.408 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:38:14.408 | [AutoTuner]: Tuning fp4_gemm:  77%|███████▋  | 10/13 [00:00<00:00, 98.91profile/s]
2026-05-01 21:38:14.408 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 93.71profile/s]
2026-05-01 21:38:14.528 | (EngineCore pid=187) 
2026-05-01 21:38:14.528 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:38:14.528 | [AutoTuner]: Tuning fp4_gemm:  92%|█████████▏| 12/13 [00:00<00:00, 116.54profile/s]
2026-05-01 21:38:14.528 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 114.96profile/s]
2026-05-01 21:38:14.725 | (EngineCore pid=187) 
2026-05-01 21:38:14.725 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:38:14.725 | [AutoTuner]: Tuning fp4_gemm:  85%|████████▍ | 11/13 [00:00<00:00, 106.92profile/s]
2026-05-01 21:38:14.725 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 97.50profile/s] 
2026-05-01 21:38:14.855 | (EngineCore pid=187) 
2026-05-01 21:38:14.855 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:38:14.855 | [AutoTuner]: Tuning fp4_gemm:  85%|████████▍ | 11/13 [00:00<00:00, 104.64profile/s]
2026-05-01 21:38:14.855 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 101.85profile/s]
2026-05-01 21:38:15.769 | (EngineCore pid=187) 2026-05-01 19:38:15,769 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 21:38:17.217 | (EngineCore pid=187) 
2026-05-01 21:38:17.217 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-05-01 21:38:17.217 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  5.21it/s]
2026-05-01 21:38:17.217 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 2/3 [00:00<00:00,  5.50it/s]
2026-05-01 21:38:17.217 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  2.60it/s]
2026-05-01 21:38:17.217 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  3.02it/s]
2026-05-01 21:38:18.096 | (EngineCore pid=187) 
2026-05-01 21:38:18.096 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/3 [00:00<?, ?it/s]
2026-05-01 21:38:18.096 | Capturing CUDA graphs (decode, FULL):  33%|███▎      | 1/3 [00:00<00:00,  2.92it/s]
2026-05-01 21:38:18.096 | Capturing CUDA graphs (decode, FULL):  67%|██████▋   | 2/3 [00:00<00:00,  3.82it/s]
2026-05-01 21:38:18.096 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 3/3 [00:00<00:00,  3.40it/s]
2026-05-01 21:38:18.096 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 3/3 [00:00<00:00,  3.41it/s]
2026-05-01 21:38:18.525 | (EngineCore pid=187) INFO 05-01 19:38:18 [gpu_model_runner.py:6133] Graph capturing finished in 3 secs, took 0.67 GiB
2026-05-01 21:38:18.525 | (EngineCore pid=187) INFO 05-01 19:38:18 [gpu_worker.py:599] CUDA graph pool memory: 0.67 GiB (actual), 0.45 GiB (estimated), difference: 0.22 GiB (32.7%).
2026-05-01 21:38:18.618 | (EngineCore pid=187) INFO 05-01 19:38:18 [core.py:299] init engine (profile, create kv cache, warmup model) took 125.66 s (compilation: 51.57 s)
2026-05-01 21:38:19.104 | (EngineCore pid=187) INFO 05-01 19:38:19 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:38:19.105 | (EngineCore pid=187) INFO 05-01 19:38:19 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:38:19.105 | (EngineCore pid=187) INFO 05-01 19:38:19 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:38:19.464 | (APIServer pid=1) INFO 05-01 19:38:19 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 21:38:19.899 | (APIServer pid=1) WARNING 05-01 19:38:19 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-01 21:38:25.364 | (APIServer pid=1) INFO 05-01 19:38:25 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 21:38:33.840 | (APIServer pid=1) INFO 05-01 19:38:33 [base.py:233] Multi-modal warmup completed in 8.457s
2026-05-01 21:38:42.656 | (APIServer pid=1) INFO 05-01 19:38:42 [base.py:233] Readonly multi-modal warmup completed in 8.648s
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:37] Available routes are:
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 21:38:42.945 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 21:38:42.946 | (APIServer pid=1) INFO 05-01 19:38:42 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 21:38:43.052 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 21:38:43.052 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 21:38:43.315 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-01 21:41:37.117 | (APIServer pid=1) ERROR 05-01 19:41:37 [serving.py:218] Error with model error=ErrorInfo(message='The model `RedHatAI/Qwen3.6-35B-A3B-NVFP4` does not exist.', type='NotFoundError', param='model', code=404)
2026-05-01 21:41:37.117 | (APIServer pid=1) INFO:     172.18.0.1:49352 - "POST /v1/chat/completions HTTP/1.1" 404 Not Found
2026-05-01 21:42:14.020 | (APIServer pid=1) INFO 05-01 19:42:14 [loggers.py:271] Engine 000: Avg prompt throughput: 10.9 tokens/s, Avg generation throughput: 105.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.7%, Prefix cache hit rate: 0.0%

