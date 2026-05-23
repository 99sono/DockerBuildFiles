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
      # Protect the WSL2 driver from JIT spikes
      FLASHINFER_AUTOTUNE: "0"
      VLLM_FLASHINFER_CHECK_SAFE_OPS: "0"
      VLLM_NO_USAGE_STATS: "1"
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "8192"
      
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      
      # FIX: Use 'marlin' because 'triton' doesn't support NVFP4 MoE yet
      - "--moe-backend"
      - "marlin"
      
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "32"
      - "--max-num-batched-tokens"
      - "8192"
      - "--trust-remote-code"

      # Keeping eager mode to prevent CUDA graph memory crashes
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vlllm running but unusable

2026-05-01 20:54:16.988 | WARNING 05-01 18:54:16 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:54:17.079 | WARNING 05-01 18:54:17 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299] 
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 20:54:17.080 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:299] 
2026-05-01 20:54:17.083 | (APIServer pid=1) INFO 05-01 18:54:17 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 32, 'enable_chunked_prefill': True, 'moe_backend': 'marlin'}
2026-05-01 20:54:17.084 | (APIServer pid=1) WARNING 05-01 18:54:17 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 20:54:17.488 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:54:27.491 | (APIServer pid=1) INFO 05-01 18:54:27 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 20:54:27.522 | (APIServer pid=1) INFO 05-01 18:54:27 [nixl_utils.py:32] NIXL is available
2026-05-01 20:54:27.709 | (APIServer pid=1) INFO 05-01 18:54:27 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 20:54:27.710 | (APIServer pid=1) INFO 05-01 18:54:27 [model.py:1680] Using max model len 8192
2026-05-01 20:54:28.151 | (APIServer pid=1) INFO 05-01 18:54:28 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 20:54:28.152 | (APIServer pid=1) INFO 05-01 18:54:28 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-05-01 20:54:28.152 | (APIServer pid=1) WARNING 05-01 18:54:28 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 20:54:28.152 | (APIServer pid=1) INFO 05-01 18:54:28 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 20:54:28.152 | (APIServer pid=1) INFO 05-01 18:54:28 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 20:54:28.152 | (APIServer pid=1) WARNING 05-01 18:54:28 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 20:54:28.152 | (APIServer pid=1) WARNING 05-01 18:54:28 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 20:54:28.153 | (APIServer pid=1) INFO 05-01 18:54:28 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 20:54:28.153 | (APIServer pid=1) INFO 05-01 18:54:28 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 20:54:30.819 | (APIServer pid=1) INFO 05-01 18:54:30 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 20:54:30.980 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:54:39.201 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:54:50.140 | INFO 05-01 18:54:50 [nixl_utils.py:32] NIXL is available
2026-05-01 20:54:50.202 | (EngineCore pid=187) INFO 05-01 18:54:50 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'ir_enable_torch_wrap': False, 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['vllm_c', 'native']), enable_flashinfer_autotune=True, moe_backend='marlin')
2026-05-01 20:54:50.360 | (EngineCore pid=187) WARNING 05-01 18:54:50 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:54:50.475 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:54:50.899 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:54:53.469 | (EngineCore pid=187) INFO 05-01 18:54:53 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:51001 backend=nccl
2026-05-01 20:54:53.784 | (EngineCore pid=187) INFO 05-01 18:54:53 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 20:55:00.200 | (EngineCore pid=187) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:55:05.703 | (EngineCore pid=187) INFO 05-01 18:55:05 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 20:55:06.109 | (EngineCore pid=187) INFO 05-01 18:55:06 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 20:55:06.110 | (EngineCore pid=187) INFO 05-01 18:55:06 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 20:55:06.201 | (EngineCore pid=187) INFO 05-01 18:55:06 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 20:55:06.201 | (EngineCore pid=187) INFO 05-01 18:55:06 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 20:55:06.206 | (EngineCore pid=187) INFO 05-01 18:55:06 [nvfp4.py:209] Using 'MARLIN' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
2026-05-01 20:55:06.936 | (EngineCore pid=187) INFO 05-01 18:55:06 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 21:01:17.930 | (EngineCore pid=187) INFO 05-01 19:01:17 [weight_utils.py:615] Time spent downloading weights for RedHatAI/Qwen3.6-35B-A3B-NVFP4: 367.850928 seconds
2026-05-01 21:01:18.214 | (EngineCore pid=187) INFO 05-01 19:01:18 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 55.38 GiB.
2026-05-01 21:01:18.214 | (EngineCore pid=187) INFO 05-01 19:01:18 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 21:01:18.215 | (EngineCore pid=187) 
2026-05-01 21:01:18.215 | Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
2026-05-01 21:01:41.572 | (EngineCore pid=187) 
2026-05-01 21:01:41.572 | Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:23<00:46, 23.36s/it]
2026-05-01 21:01:42.821 | (EngineCore pid=187) 
2026-05-01 21:01:42.821 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:24<00:00,  6.52s/it]
2026-05-01 21:01:42.821 | (EngineCore pid=187) 
2026-05-01 21:01:42.821 | Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:24<00:00,  8.20s/it]
2026-05-01 21:01:42.821 | (EngineCore pid=187) 
2026-05-01 21:01:42.862 | (EngineCore pid=187) INFO 05-01 19:01:42 [default_loader.py:384] Loading weights took 24.57 seconds
2026-05-01 21:01:42.947 | (EngineCore pid=187) WARNING 05-01 19:01:42 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
2026-05-01 21:01:43.686 | (EngineCore pid=187) INFO 05-01 19:01:43 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
2026-05-01 21:01:54.486 | (EngineCore pid=187) INFO 05-01 19:01:54 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 406.898504 seconds
2026-05-01 21:01:54.486 | (EngineCore pid=187) INFO 05-01 19:01:54 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 21:01:54.729 | (EngineCore pid=187) INFO 05-01 19:01:54 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
2026-05-01 21:03:12.857 | (EngineCore pid=187) INFO 05-01 19:03:12 [gpu_worker.py:440] Available KV cache memory: 0.32 GiB
2026-05-01 21:03:12.858 | (EngineCore pid=187) INFO 05-01 19:03:12 [kv_cache_utils.py:1711] GPU KV cache size: 6,288 tokens
2026-05-01 21:03:12.858 | (EngineCore pid=187) INFO 05-01 19:03:12 [kv_cache_utils.py:1716] Maximum concurrency for 8,192 tokens per request: 1.50x
2026-05-01 21:03:12.880 | (EngineCore pid=187) 2026-05-01 19:03:12,880 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 21:03:13.070 | (EngineCore pid=187) 
2026-05-01 21:03:13.070 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 21:03:13.070 | [AutoTuner]: Tuning fp4_gemm:  50%|█████     | 7/14 [00:00<00:00, 64.91profile/s]
2026-05-01 21:03:13.070 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 80.88profile/s]
2026-05-01 21:03:13.190 | (EngineCore pid=187) 
2026-05-01 21:03:13.190 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 21:03:13.190 | [AutoTuner]: Tuning fp4_gemm:  86%|████████▌ | 12/14 [00:00<00:00, 119.88profile/s]
2026-05-01 21:03:13.190 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 118.67profile/s]
2026-05-01 21:03:13.387 | (EngineCore pid=187) 
2026-05-01 21:03:13.387 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 21:03:13.387 | [AutoTuner]: Tuning fp4_gemm:  79%|███████▊  | 11/14 [00:00<00:00, 108.49profile/s]
2026-05-01 21:03:13.387 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 84.04profile/s] 
2026-05-01 21:03:13.540 | (EngineCore pid=187) 
2026-05-01 21:03:13.540 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/14 [00:00<?, ?profile/s]
2026-05-01 21:03:13.540 | [AutoTuner]: Tuning fp4_gemm:  79%|███████▊  | 11/14 [00:00<00:00, 105.16profile/s]
2026-05-01 21:03:13.540 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 14/14 [00:00<00:00, 98.14profile/s] 
2026-05-01 21:03:14.051 | (EngineCore pid=187) 2026-05-01 19:03:14,051 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 21:03:14.173 | (EngineCore pid=187) INFO 05-01 19:03:14 [core.py:306] init engine (profile, create kv cache, warmup model) took 79.69 s
2026-05-01 21:03:14.460 | (EngineCore pid=187) INFO 05-01 19:03:14 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 21:03:14.460 | (EngineCore pid=187) WARNING 05-01 19:03:14 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 21:03:14.460 | (EngineCore pid=187) WARNING 05-01 19:03:14 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 21:03:14.461 | (EngineCore pid=187) INFO 05-01 19:03:14 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 21:03:14.461 | (EngineCore pid=187) INFO 05-01 19:03:14 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 21:03:14.461 | (EngineCore pid=187) INFO 05-01 19:03:14 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 21:03:14.567 | (APIServer pid=1) INFO 05-01 19:03:14 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 21:03:14.926 | (APIServer pid=1) WARNING 05-01 19:03:14 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-01 21:03:20.643 | (APIServer pid=1) INFO 05-01 19:03:20 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 21:03:29.040 | (APIServer pid=1) INFO 05-01 19:03:29 [base.py:233] Multi-modal warmup completed in 8.369s
2026-05-01 21:03:37.373 | (APIServer pid=1) INFO 05-01 19:03:37 [base.py:233] Readonly multi-modal warmup completed in 8.313s
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:37] Available routes are:
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 21:03:37.680 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 21:03:37.681 | (APIServer pid=1) INFO 05-01 19:03:37 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 21:03:37.883 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 21:03:37.883 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 21:03:38.140 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-01 21:05:38.468 | (APIServer pid=1) INFO 05-01 19:05:38 [loggers.py:271] Engine 000: Avg prompt throughput: 10.9 tokens/s, Avg generation throughput: 0.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:05:48.469 | (APIServer pid=1) INFO 05-01 19:05:48 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:05:58.469 | (APIServer pid=1) INFO 05-01 19:05:58 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:08.544 | (APIServer pid=1) INFO 05-01 19:06:08 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:18.545 | (APIServer pid=1) INFO 05-01 19:06:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:28.545 | (APIServer pid=1) INFO 05-01 19:06:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:38.622 | (APIServer pid=1) INFO 05-01 19:06:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:48.622 | (APIServer pid=1) INFO 05-01 19:06:48 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:06:58.623 | (APIServer pid=1) INFO 05-01 19:06:58 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:08.731 | (APIServer pid=1) INFO 05-01 19:07:08 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:18.732 | (APIServer pid=1) INFO 05-01 19:07:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:28.731 | (APIServer pid=1) INFO 05-01 19:07:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:38.832 | (APIServer pid=1) INFO 05-01 19:07:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:48.833 | (APIServer pid=1) INFO 05-01 19:07:48 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:07:58.834 | (APIServer pid=1) INFO 05-01 19:07:58 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:08.910 | (APIServer pid=1) INFO 05-01 19:08:08 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:18.910 | (APIServer pid=1) INFO 05-01 19:08:18 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:28.911 | (APIServer pid=1) INFO 05-01 19:08:28 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:38.991 | (APIServer pid=1) INFO 05-01 19:08:38 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:48.991 | (APIServer pid=1) INFO 05-01 19:08:48 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:08:58.991 | (APIServer pid=1) INFO 05-01 19:08:58 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.6%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:09.076 | (APIServer pid=1) INFO 05-01 19:09:09 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:19.077 | (APIServer pid=1) INFO 05-01 19:09:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:29.077 | (APIServer pid=1) INFO 05-01 19:09:29 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:39.167 | (APIServer pid=1) INFO 05-01 19:09:39 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:49.167 | (APIServer pid=1) INFO 05-01 19:09:49 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:09:59.167 | (APIServer pid=1) INFO 05-01 19:09:59 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:10:09.245 | (APIServer pid=1) INFO 05-01 19:10:09 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:10:19.245 | (APIServer pid=1) INFO 05-01 19:10:19 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.7%, Prefix cache hit rate: 0.0%
2026-05-01 21:10:22.523 | (APIServer pid=1) INFO:     172.18.0.1:53778 - "POST /v1/chat/completions HTTP/1.1" 200 OK