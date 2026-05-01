# docker compose
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

      # 1. MEMORY BUDGET (Proven stable at 90% for your WSL2 setup)
      - "--gpu-memory-utilization"
      - "0.90"  

      # 2. THE 64k EXPERIMENT
      - "--max-model-len"
      - "65536"
      
      # 3. SINGLE-USER GOD MODE
      # Forces vLLM to give the entire KV cache to one request
      - "--max-num-seqs"
      - "1"
      
      # 4. CONSERVATIVE PREFILL
      # We keep this at 4096 so the CUDA graph capture doesn't OOM 
      # while trying to digest a massive 64k prompt all at once.
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

      # 5. YOUR SUCCESSFUL KERNEL FUSION
      - "--moe-backend"
      - "cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 6. CUDA GRAPHS (The Speed Multiplier)
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

We have fast tokens per second here.

# vllm log now we are somewhere

2026-05-01 21:55:02.609 | WARNING 05-01 19:55:02 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:55:02.708 | WARNING 05-01 19:55:02 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299] 
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 21:55:02.710 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:299] 
2026-05-01 21:55:02.712 | (APIServer pid=1) INFO 05-01 19:55:02 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 65536, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.9, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 4096, 'max_num_seqs': 1, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 4, 'moe_backend': 'cutlass'}
2026-05-01 21:55:03.137 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:55:14.622 | (APIServer pid=1) INFO 05-01 19:55:14 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 21:55:14.654 | (APIServer pid=1) INFO 05-01 19:55:14 [nixl_utils.py:32] NIXL is available
2026-05-01 21:55:14.856 | (APIServer pid=1) INFO 05-01 19:55:14 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 21:55:14.856 | (APIServer pid=1) INFO 05-01 19:55:14 [model.py:1680] Using max model len 65536
2026-05-01 21:55:15.305 | (APIServer pid=1) INFO 05-01 19:55:15 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 21:55:15.306 | (APIServer pid=1) INFO 05-01 19:55:15 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=4096.
2026-05-01 21:55:15.307 | (APIServer pid=1) WARNING 05-01 19:55:15 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 21:55:15.307 | (APIServer pid=1) INFO 05-01 19:55:15 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 21:55:15.307 | (APIServer pid=1) INFO 05-01 19:55:15 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:55:15.307 | (APIServer pid=1) INFO 05-01 19:55:15 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:55:18.024 | (APIServer pid=1) INFO 05-01 19:55:18 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:55:18.179 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:55:26.334 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:55:37.327 | INFO 05-01 19:55:37 [nixl_utils.py:32] NIXL is available
2026-05-01 21:55:37.393 | (EngineCore pid=187) INFO 05-01 19:55:37 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=65536, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [4096], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 21:55:37.571 | (EngineCore pid=187) WARNING 05-01 19:55:37 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:55:37.686 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:55:38.102 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:55:40.880 | (EngineCore pid=187) INFO 05-01 19:55:40 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:39365 backend=nccl
2026-05-01 21:55:41.180 | (EngineCore pid=187) INFO 05-01 19:55:41 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 21:55:47.672 | (EngineCore pid=187) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:55:53.025 | (EngineCore pid=187) INFO 05-01 19:55:53 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 21:55:53.355 | (EngineCore pid=187) INFO 05-01 19:55:53 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 21:55:53.356 | (EngineCore pid=187) INFO 05-01 19:55:53 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 21:55:53.439 | (EngineCore pid=187) INFO 05-01 19:55:53 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 21:55:53.441 | (EngineCore pid=187) INFO 05-01 19:55:53 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 21:55:53.448 | (EngineCore pid=187) INFO 05-01 19:55:53 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 21:55:54.036 | (EngineCore pid=187) INFO 05-01 19:55:54 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 21:55:55.661 | (EngineCore pid=187) INFO 05-01 19:55:55 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.51 GiB.
2026-05-01 21:55:55.661 | (EngineCore pid=187) INFO 05-01 19:55:55 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 21:55:55.662 | (EngineCore pid=187) 
2026-05-01 21:55:55.662 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-05-01 21:56:37.610 | (EngineCore pid=187) 
2026-05-01 21:56:37.610 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:41<01:23, 41.95s/it]
2026-05-01 21:56:39.440 | (EngineCore pid=187) 
2026-05-01 21:56:39.440 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:43<00:00, 11.55s/it]
2026-05-01 21:56:39.440 | (EngineCore pid=187) 
2026-05-01 21:56:39.440 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:43<00:00, 14.59s/it]
2026-05-01 21:56:39.440 | (EngineCore pid=187) 
2026-05-01 21:56:39.479 | (EngineCore pid=187) INFO 05-01 19:56:39 [default_loader.py:384] Loading weights took 43.71 seconds
2026-05-01 21:56:39.597 | (EngineCore pid=187) INFO 05-01 19:56:39 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 21:56:40.397 | (EngineCore pid=187) INFO 05-01 19:56:40 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 46.400619 seconds
2026-05-01 21:56:40.398 | (EngineCore pid=187) INFO 05-01 19:56:40 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 21:56:40.633 | (EngineCore pid=187) INFO 05-01 19:56:40 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-05-01 21:56:59.145 | (EngineCore pid=187) INFO 05-01 19:56:59 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/900c43dbb8/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 21:56:59.145 | (EngineCore pid=187) INFO 05-01 19:56:59 [backends.py:1128] Dynamo bytecode transform time: 7.34 s
2026-05-01 21:57:02.075 | (EngineCore pid=187) INFO 05-01 19:57:02 [backends.py:376] Cache the graph of compile range (1, 4096) for later use
2026-05-01 21:57:32.598 | (EngineCore pid=187) INFO 05-01 19:57:32 [backends.py:391] Compiling a graph for compile range (1, 4096) takes 32.82 s
2026-05-01 21:57:36.255 | (EngineCore pid=187) INFO 05-01 19:57:36 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/0c25f9de76ce083001442e8ad29f0ff5f44d984792e5d38dbfd8a0cb6fa86265/rank_0_0/model
2026-05-01 21:57:36.255 | (EngineCore pid=187) INFO 05-01 19:57:36 [monitor.py:53] torch.compile took 44.34 s in total
2026-05-01 21:58:26.645 | (EngineCore pid=187) INFO 05-01 19:58:26 [monitor.py:81] Initial profiling/warmup run took 50.16 s
2026-05-01 21:58:27.359 | (EngineCore pid=187) INFO 05-01 19:58:27 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=1 (largest=1)
2026-05-01 21:58:30.822 | (EngineCore pid=187) INFO 05-01 19:58:30 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.39 GiB total
2026-05-01 21:58:31.243 | (EngineCore pid=187) INFO 05-01 19:58:31 [gpu_worker.py:440] Available KV cache memory: 3.07 GiB
2026-05-01 21:58:31.243 | (EngineCore pid=187) INFO 05-01 19:58:31 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.9000 is equivalent to --gpu-memory-utilization=0.8878 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.9122. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 21:58:31.244 | (EngineCore pid=187) INFO 05-01 19:58:31 [kv_cache_utils.py:1711] GPU KV cache size: 79,648 tokens
2026-05-01 21:58:31.244 | (EngineCore pid=187) INFO 05-01 19:58:31 [kv_cache_utils.py:1716] Maximum concurrency for 65,536 tokens per request: 4.03x
2026-05-01 21:58:31.314 | (EngineCore pid=187) 2026-05-01 19:58:31,314 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 21:58:31.458 | (EngineCore pid=187) 
2026-05-01 21:58:31.458 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:58:31.458 | [AutoTuner]: Tuning fp4_gemm:  77%|███████▋  | 10/13 [00:00<00:00, 97.36profile/s]
2026-05-01 21:58:31.458 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 99.16profile/s]
2026-05-01 21:58:31.580 | (EngineCore pid=187) 
2026-05-01 21:58:31.580 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:58:31.580 | [AutoTuner]: Tuning fp4_gemm:  92%|█████████▏| 12/13 [00:00<00:00, 114.93profile/s]
2026-05-01 21:58:31.580 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 113.48profile/s]
2026-05-01 21:58:31.769 | (EngineCore pid=187) 
2026-05-01 21:58:31.769 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:58:31.769 | [AutoTuner]: Tuning fp4_gemm:  85%|████████▍ | 11/13 [00:00<00:00, 107.37profile/s]
2026-05-01 21:58:31.769 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 96.71profile/s] 
2026-05-01 21:58:31.899 | (EngineCore pid=187) 
2026-05-01 21:58:31.899 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/13 [00:00<?, ?profile/s]
2026-05-01 21:58:31.899 | [AutoTuner]: Tuning fp4_gemm:  85%|████████▍ | 11/13 [00:00<00:00, 105.23profile/s]
2026-05-01 21:58:31.899 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 13/13 [00:00<00:00, 102.16profile/s]
2026-05-01 21:58:32.697 | (EngineCore pid=187) 2026-05-01 19:58:32,697 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 21:58:33.639 | (EngineCore pid=187) 
2026-05-01 21:58:33.639 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-05-01 21:58:33.639 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  5.85it/s]
2026-05-01 21:58:33.639 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 2/3 [00:00<00:00,  6.01it/s]
2026-05-01 21:58:33.639 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  6.07it/s]
2026-05-01 21:58:33.639 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  6.04it/s]
2026-05-01 21:58:33.974 | (EngineCore pid=187) 
2026-05-01 21:58:33.974 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/1 [00:00<?, ?it/s]
2026-05-01 21:58:33.974 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  2.98it/s]
2026-05-01 21:58:33.974 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  2.98it/s]
2026-05-01 21:58:34.393 | (EngineCore pid=187) INFO 05-01 19:58:34 [gpu_model_runner.py:6133] Graph capturing finished in 2 secs, took 0.58 GiB
2026-05-01 21:58:34.393 | (EngineCore pid=187) INFO 05-01 19:58:34 [gpu_worker.py:599] CUDA graph pool memory: 0.58 GiB (actual), 0.39 GiB (estimated), difference: 0.2 GiB (33.4%).
2026-05-01 21:58:34.485 | (EngineCore pid=187) INFO 05-01 19:58:34 [core.py:299] init engine (profile, create kv cache, warmup model) took 114.09 s (compilation: 44.34 s)
2026-05-01 21:58:34.951 | (EngineCore pid=187) INFO 05-01 19:58:34 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:58:34.951 | (EngineCore pid=187) INFO 05-01 19:58:34 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:58:34.951 | (EngineCore pid=187) INFO 05-01 19:58:34 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:58:35.306 | (APIServer pid=1) INFO 05-01 19:58:35 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 21:58:35.675 | (APIServer pid=1) WARNING 05-01 19:58:35 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-01 21:58:41.229 | (APIServer pid=1) INFO 05-01 19:58:41 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 21:58:49.886 | (APIServer pid=1) INFO 05-01 19:58:49 [base.py:233] Multi-modal warmup completed in 8.631s
2026-05-01 21:58:58.253 | (APIServer pid=1) INFO 05-01 19:58:58 [base.py:233] Readonly multi-modal warmup completed in 8.316s
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:37] Available routes are:
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 21:58:58.555 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 21:58:58.556 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 21:58:58.557 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 21:58:58.557 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 21:58:58.557 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 21:58:58.557 | (APIServer pid=1) INFO 05-01 19:58:58 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 21:58:58.657 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 21:58:58.657 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 21:58:58.911 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-01 22:03:19.972 | (APIServer pid=1) INFO 05-01 20:03:19 [loggers.py:271] Engine 000: Avg prompt throughput: 10.9 tokens/s, Avg generation throughput: 41.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.6%, Prefix cache hit rate: 0.0%
2026-05-01 22:03:29.972 | (APIServer pid=1) INFO 05-01 20:03:29 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 147.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.6%, Prefix cache hit rate: 0.0%
2026-05-01 22:03:32.378 | (APIServer pid=1) INFO:     172.18.0.1:55820 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:03:39.972 | (APIServer pid=1) INFO 05-01 20:03:39 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 33.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 22:03:48.587 | (APIServer pid=1) INFO:     172.18.0.1:38834 - "GET /v1/models HTTP/1.1" 200 OK
2026-05-01 22:03:50.105 | (APIServer pid=1) INFO 05-01 20:03:50 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 22:04:56.470 | (APIServer pid=1) INFO:     172.18.0.1:47324 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:05:00.331 | (APIServer pid=1) INFO 05-01 20:05:00 [loggers.py:271] Engine 000: Avg prompt throughput: 1908.9 tokens/s, Avg generation throughput: 26.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 22:05:00.364 | (APIServer pid=1) INFO:     172.18.0.1:47324 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:05:10.331 | (APIServer pid=1) INFO 05-01 20:05:10 [loggers.py:271] Engine 000: Avg prompt throughput: 130.0 tokens/s, Avg generation throughput: 32.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 47.9%
2026-05-01 22:05:20.475 | (APIServer pid=1) INFO 05-01 20:05:20 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 47.9%
2026-05-01 22:06:29.389 | (APIServer pid=1) INFO:     172.18.0.1:51048 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:06:30.725 | (APIServer pid=1) INFO 05-01 20:06:30 [loggers.py:271] Engine 000: Avg prompt throughput: 226.9 tokens/s, Avg generation throughput: 14.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.2%, Prefix cache hit rate: 62.4%
2026-05-01 22:06:40.726 | (APIServer pid=1) INFO 05-01 20:06:40 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 29.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 62.4%
2026-05-01 22:06:50.848 | (APIServer pid=1) INFO 05-01 20:06:50 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 62.4%
2026-05-01 22:07:27.612 | (APIServer pid=1) INFO:     172.18.0.1:34210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:07:30.975 | (APIServer pid=1) INFO 05-01 20:07:30 [loggers.py:271] Engine 000: Avg prompt throughput: 127.4 tokens/s, Avg generation throughput: 23.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 70.9%
2026-05-01 22:07:40.976 | (APIServer pid=1) INFO 05-01 20:07:40 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 70.9%
2026-05-01 22:08:57.617 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:08:59.678 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:01.345 | (APIServer pid=1) INFO 05-01 20:09:01 [loggers.py:271] Engine 000: Avg prompt throughput: 412.0 tokens/s, Avg generation throughput: 38.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.9%, Prefix cache hit rate: 78.5%
2026-05-01 22:09:01.789 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:03.929 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:06.162 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:08.556 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:10.872 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:11.346 | (APIServer pid=1) INFO 05-01 20:09:11 [loggers.py:271] Engine 000: Avg prompt throughput: 1575.2 tokens/s, Avg generation throughput: 93.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.5%, Prefix cache hit rate: 84.4%
2026-05-01 22:09:13.435 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:15.857 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:19.630 | (APIServer pid=1) INFO:     172.18.0.1:38388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 22:09:21.482 | (APIServer pid=1) INFO 05-01 20:09:21 [loggers.py:271] Engine 000: Avg prompt throughput: 2356.5 tokens/s, Avg generation throughput: 91.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 19.1%, Prefix cache hit rate: 83.9%
2026-05-01 22:09:31.483 | (APIServer pid=1) INFO 05-01 20:09:31 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 100.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.9%
2026-05-01 22:09:41.484 | (APIServer pid=1) INFO 05-01 20:09:41 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.9%