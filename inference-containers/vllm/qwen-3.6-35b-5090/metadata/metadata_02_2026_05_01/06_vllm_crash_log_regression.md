# docker compose that caused regression

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
      # Let FlashInfer autotune so Cutlass can find the fast Blackwell path
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 1. THE VRAM TRICK: Drop to 70% utilization.
      # This reserves ~9.6 GB of pure, untouched VRAM specifically for 
      # the Cutlass compiler and CUDA graph capture to do their heavy lifting.
      - "--gpu-memory-utilization"
      - "0.70"  

      # 2. Keep context and batching low so we don't blow up the workspace
      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "2"
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

      # 3. BACK TO NATIVE SILICON SPEED
      - "--moe-backend"
      - "cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 4. BRING BACK CUDA GRAPHS, BUT LIMIT THEM
      # This prevents the WSL2 memory crash while still giving you the speed boost.
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```    

# vllm regression - crash log

2026-05-01 21:14:35.360 | WARNING 05-01 19:14:35 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:14:35.452 | WARNING 05-01 19:14:35 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299] 
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 21:14:35.454 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:299] 
2026-05-01 21:14:35.457 | (APIServer pid=1) INFO 05-01 19:14:35 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.7, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 4096, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 4, 'moe_backend': 'cutlass'}
2026-05-01 21:14:46.196 | (APIServer pid=1) INFO 05-01 19:14:46 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 21:14:46.227 | (APIServer pid=1) INFO 05-01 19:14:46 [nixl_utils.py:32] NIXL is available
2026-05-01 21:14:46.422 | (APIServer pid=1) INFO 05-01 19:14:46 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 21:14:46.422 | (APIServer pid=1) INFO 05-01 19:14:46 [model.py:1680] Using max model len 8192
2026-05-01 21:14:46.794 | (APIServer pid=1) INFO 05-01 19:14:46 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 21:14:46.795 | (APIServer pid=1) INFO 05-01 19:14:46 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=4096.
2026-05-01 21:14:46.795 | (APIServer pid=1) WARNING 05-01 19:14:46 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 21:14:46.795 | (APIServer pid=1) INFO 05-01 19:14:46 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 21:14:46.795 | (APIServer pid=1) INFO 05-01 19:14:46 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:14:46.795 | (APIServer pid=1) INFO 05-01 19:14:46 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-05-01 21:14:46.908 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:14:49.568 | (APIServer pid=1) INFO 05-01 19:14:49 [compilation.py:303] Enabled custom fusions: act_quant
2026-05-01 21:14:49.724 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:14:57.927 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:15:09.565 | INFO 05-01 19:15:09 [nixl_utils.py:32] NIXL is available
2026-05-01 21:15:09.631 | (EngineCore pid=187) INFO 05-01 19:15:09 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [4096], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 21:15:09.806 | (EngineCore pid=187) WARNING 05-01 19:15:09 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 21:15:09.934 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 21:15:13.055 | (EngineCore pid=187) INFO 05-01 19:15:13 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:42787 backend=nccl
2026-05-01 21:15:13.364 | (EngineCore pid=187) INFO 05-01 19:15:13 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 21:15:14.254 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 21:15:19.747 | (EngineCore pid=187) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 21:15:25.080 | (EngineCore pid=187) INFO 05-01 19:15:25 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 21:15:25.426 | (EngineCore pid=187) INFO 05-01 19:15:25 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 21:15:25.427 | (EngineCore pid=187) INFO 05-01 19:15:25 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 21:15:25.529 | (EngineCore pid=187) INFO 05-01 19:15:25 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 21:15:25.530 | (EngineCore pid=187) INFO 05-01 19:15:25 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 21:15:25.536 | (EngineCore pid=187) INFO 05-01 19:15:25 [nvfp4.py:209] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 21:15:25.959 | (EngineCore pid=187) INFO 05-01 19:15:25 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 21:15:27.537 | (EngineCore pid=187) INFO 05-01 19:15:27 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 56.67 GiB.
2026-05-01 21:15:27.538 | (EngineCore pid=187) INFO 05-01 19:15:27 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 21:15:27.538 | (EngineCore pid=187) 
2026-05-01 21:15:27.538 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-05-01 21:15:52.192 | (EngineCore pid=187) 
2026-05-01 21:15:52.192 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:24<00:49, 24.65s/it]
2026-05-01 21:15:55.800 | (EngineCore pid=187) 
2026-05-01 21:15:55.800 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:28<00:00,  7.73s/it]
2026-05-01 21:15:55.800 | (EngineCore pid=187) 
2026-05-01 21:15:55.800 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:28<00:00,  9.42s/it]
2026-05-01 21:15:55.800 | (EngineCore pid=187) 
2026-05-01 21:15:55.933 | (EngineCore pid=187) INFO 05-01 19:15:55 [default_loader.py:384] Loading weights took 28.31 seconds
2026-05-01 21:15:56.061 | (EngineCore pid=187) INFO 05-01 19:15:56 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 21:15:56.652 | (EngineCore pid=187) INFO 05-01 19:15:56 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 30.729705 seconds
2026-05-01 21:15:56.653 | (EngineCore pid=187) INFO 05-01 19:15:56 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 21:15:56.897 | (EngineCore pid=187) INFO 05-01 19:15:56 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-05-01 21:16:14.784 | (EngineCore pid=187) INFO 05-01 19:16:14 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/7c10152ca9/rank_0_0/backbone for vLLM's torch.compile
2026-05-01 21:16:14.784 | (EngineCore pid=187) INFO 05-01 19:16:14 [backends.py:1128] Dynamo bytecode transform time: 7.29 s
2026-05-01 21:16:17.773 | (EngineCore pid=187) INFO 05-01 19:16:17 [backends.py:376] Cache the graph of compile range (1, 4096) for later use
2026-05-01 21:16:48.107 | (EngineCore pid=187) INFO 05-01 19:16:48 [backends.py:391] Compiling a graph for compile range (1, 4096) takes 32.74 s
2026-05-01 21:16:51.743 | (EngineCore pid=187) INFO 05-01 19:16:51 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/9eefdb871fc1f9b40a369709d53c561afe2853ee004b24228333bddf8dafbb7f/rank_0_0/model
2026-05-01 21:16:51.743 | (EngineCore pid=187) INFO 05-01 19:16:51 [monitor.py:53] torch.compile took 44.17 s in total
2026-05-01 21:17:40.058 | (EngineCore pid=187) INFO 05-01 19:17:40 [monitor.py:81] Initial profiling/warmup run took 48.14 s
2026-05-01 21:17:40.799 | (EngineCore pid=187) INFO 05-01 19:17:40 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=2 (largest=2)
2026-05-01 21:17:44.614 | (EngineCore pid=187) INFO 05-01 19:17:44 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.42 GiB total
2026-05-01 21:17:45.024 | (EngineCore pid=187) INFO 05-01 19:17:45 [gpu_worker.py:440] Available KV cache memory: -3.31 GiB
2026-05-01 21:17:45.024 | (EngineCore pid=187) INFO 05-01 19:17:45 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.7000 is equivalent to --gpu-memory-utilization=0.6868 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.7132. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136] EngineCore failed to start.
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136] Traceback (most recent call last):
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     super().__init__(
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 261, in _initialize_kv_caches
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     kv_cache_configs = get_kv_cache_configs(
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]                        ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1998, in get_kv_cache_configs
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     _check_enough_kv_cache_memory(
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 696, in _check_enough_kv_cache_memory
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136]     raise ValueError(
2026-05-01 21:17:45.026 | (EngineCore pid=187) ERROR 05-01 19:17:45 [core.py:1136] ValueError: No available memory for the cache blocks. Try increasing `gpu_memory_utilization` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-05-01 21:17:45.026 | (EngineCore pid=187) Process EngineCore:
2026-05-01 21:17:45.026 | (EngineCore pid=187) Traceback (most recent call last):
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 21:17:45.026 | (EngineCore pid=187)     self.run()
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 21:17:45.026 | (EngineCore pid=187)     self._target(*self._args, **self._kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 21:17:45.026 | (EngineCore pid=187)     raise e
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 21:17:45.026 | (EngineCore pid=187)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:45.026 | (EngineCore pid=187)     return func(*args, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 21:17:45.026 | (EngineCore pid=187)     super().__init__(
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 21:17:45.026 | (EngineCore pid=187)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 21:17:45.026 | (EngineCore pid=187)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:45.026 | (EngineCore pid=187)     return func(*args, **kwargs)
2026-05-01 21:17:45.026 | (EngineCore pid=187)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 261, in _initialize_kv_caches
2026-05-01 21:17:45.026 | (EngineCore pid=187)     kv_cache_configs = get_kv_cache_configs(
2026-05-01 21:17:45.026 | (EngineCore pid=187)                        ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 1998, in get_kv_cache_configs
2026-05-01 21:17:45.026 | (EngineCore pid=187)     _check_enough_kv_cache_memory(
2026-05-01 21:17:45.026 | (EngineCore pid=187)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/core/kv_cache_utils.py", line 696, in _check_enough_kv_cache_memory
2026-05-01 21:17:45.026 | (EngineCore pid=187)     raise ValueError(
2026-05-01 21:17:45.026 | (EngineCore pid=187) ValueError: No available memory for the cache blocks. Try increasing `gpu_memory_utilization` when initializing the engine. See https://docs.vllm.ai/en/latest/configuration/conserving_memory/ for more details.
2026-05-01 21:17:45.998 | [rank0]:[W501 19:17:45.059554788 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 21:17:47.660 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 21:17:47.661 | (APIServer pid=1)     sys.exit(main())
2026-05-01 21:17:47.661 | (APIServer pid=1)              ^^^^^^
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 21:17:47.661 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 21:17:47.661 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 21:17:47.661 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 21:17:47.661 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 21:17:47.661 | (APIServer pid=1)     return runner.run(main)
2026-05-01 21:17:47.661 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 21:17:47.661 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 21:17:47.661 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 21:17:47.661 | (APIServer pid=1)     return await main
2026-05-01 21:17:47.661 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 21:17:47.661 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 21:17:47.662 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 21:17:47.662 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 21:17:47.662 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 21:17:47.662 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 21:17:47.662 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 21:17:47.662 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 21:17:47.662 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 21:17:47.662 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 21:17:47.662 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 21:17:47.662 | (APIServer pid=1)     return cls(
2026-05-01 21:17:47.662 | (APIServer pid=1)            ^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 21:17:47.662 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 21:17:47.662 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:47.662 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 21:17:47.662 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 21:17:47.662 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 21:17:47.662 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.662 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 21:17:47.663 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 21:17:47.663 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 21:17:47.663 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 21:17:47.663 | (APIServer pid=1)     super().__init__(
2026-05-01 21:17:47.663 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 21:17:47.663 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 21:17:47.663 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 21:17:47.663 | (APIServer pid=1)     next(self.gen)
2026-05-01 21:17:47.663 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 21:17:47.663 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 21:17:47.663 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 21:17:47.663 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 21:17:47.663 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}