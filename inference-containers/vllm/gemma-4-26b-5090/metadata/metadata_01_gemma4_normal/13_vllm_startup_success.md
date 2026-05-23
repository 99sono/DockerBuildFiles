# docker compose that worked
```yaml
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4
    hostname: gemma-4-26b-it-nvfp4
    runtime: nvidia
    restart: unless-stopped
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
      - NVIDIA_VISIBLE_DEVICES=all
      - HF_HUB_ENABLE_HF_TRANSFER=1
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "98304"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      - "--moe-backend"
      - "cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log
2026-04-19 13:04:53.903 | WARNING 04-19 11:04:53 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299] 
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 13:04:53.989 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:299] 
2026-04-19 13:04:53.991 | (APIServer pid=1) INFO 04-19 11:04:53 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 13:04:54.392 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 13:05:04.092 | (APIServer pid=1) INFO 04-19 11:05:04 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 13:05:04.093 | (APIServer pid=1) INFO 04-19 11:05:04 [model.py:1685] Using max model len 98304
2026-04-19 13:05:04.382 | (APIServer pid=1) INFO 04-19 11:05:04 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 13:05:04.383 | (APIServer pid=1) INFO 04-19 11:05:04 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 13:05:04.384 | (APIServer pid=1) INFO 04-19 11:05:04 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 13:05:04.384 | (APIServer pid=1) INFO 04-19 11:05:04 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:05:07.672 | (APIServer pid=1) INFO 04-19 11:05:07 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 13:05:16.926 | (EngineCore pid=196) INFO 04-19 11:05:16 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [2048], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 13:05:17.125 | (EngineCore pid=196) WARNING 04-19 11:05:17 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 13:05:17.543 | (EngineCore pid=196) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 13:05:20.911 | (EngineCore pid=196) INFO 04-19 11:05:20 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:37715 backend=nccl
2026-04-19 13:05:21.226 | (EngineCore pid=196) INFO 04-19 11:05:21 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 13:05:21.820 | (EngineCore pid=196) INFO 04-19 11:05:21 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 13:05:22.288 | (EngineCore pid=196) INFO 04-19 11:05:22 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 13:05:22.288 | (EngineCore pid=196) INFO 04-19 11:05:22 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:05:22.289 | (EngineCore pid=196) INFO 04-19 11:05:22 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 13:05:22.298 | (EngineCore pid=196) INFO 04-19 11:05:22 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 13:05:22.330 | (EngineCore pid=196) INFO 04-19 11:05:22 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 13:05:22.348 | (EngineCore pid=196) INFO 04-19 11:05:22 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 13:05:22.406 | (EngineCore pid=196) INFO 04-19 11:05:22 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 13:05:23.073 | (EngineCore pid=196) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 13:05:23.074 | (EngineCore pid=196) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 13:05:23.916 | (EngineCore pid=196) INFO 04-19 11:05:23 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 15.30 GiB. Available RAM: 56.45 GiB.
2026-04-19 13:05:23.916 | (EngineCore pid=196) INFO 04-19 11:05:23 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 13:05:23.917 | (EngineCore pid=196) 
2026-04-19 13:05:23.917 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-04-19 13:05:48.483 | (EngineCore pid=196) 
2026-04-19 13:05:48.483 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.57s/it]
2026-04-19 13:05:48.483 | (EngineCore pid=196) 
2026-04-19 13:05:48.483 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.57s/it]
2026-04-19 13:05:48.483 | (EngineCore pid=196) 
2026-04-19 13:05:49.180 | (EngineCore pid=196) INFO 04-19 11:05:49 [default_loader.py:384] Loading weights took 25.31 seconds
2026-04-19 13:05:49.396 | (EngineCore pid=196) INFO 04-19 11:05:49 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 13:05:49.460 | (EngineCore pid=196) WARNING 04-19 11:05:49 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
2026-04-19 13:05:50.078 | (EngineCore pid=196) INFO 04-19 11:05:50 [gpu_model_runner.py:4837] Model loading took 15.77 GiB memory and 27.614537 seconds
2026-04-19 13:05:50.323 | (EngineCore pid=196) INFO 04-19 11:05:50 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 2496 tokens, and profiled with 1 video items of the maximum feature size.
2026-04-19 13:06:05.907 | (EngineCore pid=196) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 13:06:05.907 | (EngineCore pid=196)   warnings.warn(
2026-04-19 13:06:06.674 | (EngineCore pid=196) WARNING 04-19 11:06:06 [op.py:236] Priority not set for op rms_norm, using native implementation.
2026-04-19 13:06:19.764 | (EngineCore pid=196) INFO 04-19 11:06:19 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/d3774ae4ac/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 13:06:19.764 | (EngineCore pid=196) INFO 04-19 11:06:19 [backends.py:1137] Dynamo bytecode transform time: 11.29 s
2026-04-19 13:06:32.663 | (EngineCore pid=196) INFO 04-19 11:06:32 [backends.py:377] Cache the graph of compile range (1, 2048) for later use
2026-04-19 13:07:00.922 | (EngineCore pid=196) INFO 04-19 11:07:00 [backends.py:398] Compiling a graph for compile range (1, 2048) takes 40.20 s
2026-04-19 13:07:06.315 | (EngineCore pid=196) INFO 04-19 11:07:06 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/ee27382bdededdbe070fe2cd8643c30f0fd4fe21f80a550442e86dae7583d870/rank_0_0/model
2026-04-19 13:07:06.315 | (EngineCore pid=196) INFO 04-19 11:07:06 [monitor.py:48] torch.compile took 57.88 s in total
2026-04-19 13:07:07.735 | (EngineCore pid=196) INFO 04-19 11:07:07 [monitor.py:76] Initial profiling/warmup run took 1.42 s
2026-04-19 13:07:14.161 | (EngineCore pid=196) INFO 04-19 11:07:14 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=512
2026-04-19 13:07:14.193 | (EngineCore pid=196) INFO 04-19 11:07:14 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=51 (largest=512), FULL=35 (largest=256)
2026-04-19 13:07:18.913 | (EngineCore pid=196) INFO 04-19 11:07:18 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.83 GiB total
2026-04-19 13:07:19.351 | (EngineCore pid=196) INFO 04-19 11:07:19 [gpu_worker.py:436] Available KV cache memory: 8.29 GiB
2026-04-19 13:07:19.351 | (EngineCore pid=196) INFO 04-19 11:07:19 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.8000 to 0.8260 to maintain the same effective KV cache size.
2026-04-19 13:07:19.352 | (EngineCore pid=196) INFO 04-19 11:07:19 [kv_cache_utils.py:1319] GPU KV cache size: 72,400 tokens
2026-04-19 13:07:19.352 | (EngineCore pid=196) INFO 04-19 11:07:19 [kv_cache_utils.py:1324] Maximum concurrency for 98,304 tokens per request: 6.73x
2026-04-19 13:07:19.413 | (EngineCore pid=196) 2026-04-19 11:07:19,413 - INFO - autotuner.py:446 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-04-19 13:07:20.729 | (EngineCore pid=196) 2026-04-19 11:07:20,728 - INFO - autotuner.py:455 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-04-19 13:07:28.697 | (EngineCore pid=196) 
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/51 [00:00<?, ?it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   2%|▏         | 1/51 [00:00<00:07,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   4%|▍         | 2/51 [00:00<00:06,  7.15it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   6%|▌         | 3/51 [00:00<00:06,  7.30it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   8%|▊         | 4/51 [00:00<00:06,  7.38it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  10%|▉         | 5/51 [00:00<00:06,  7.22it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  12%|█▏        | 6/51 [00:00<00:06,  7.14it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  14%|█▎        | 7/51 [00:00<00:06,  7.06it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  16%|█▌        | 8/51 [00:01<00:06,  6.89it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  18%|█▊        | 9/51 [00:01<00:06,  6.84it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  20%|█▉        | 10/51 [00:01<00:06,  6.80it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  22%|██▏       | 11/51 [00:01<00:05,  6.78it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  24%|██▎       | 12/51 [00:01<00:05,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  25%|██▌       | 13/51 [00:01<00:05,  6.68it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  27%|██▋       | 14/51 [00:02<00:05,  6.67it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  29%|██▉       | 15/51 [00:02<00:05,  6.68it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  31%|███▏      | 16/51 [00:02<00:05,  6.72it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 17/51 [00:02<00:05,  6.74it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  35%|███▌      | 18/51 [00:02<00:04,  6.70it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  37%|███▋      | 19/51 [00:02<00:04,  6.68it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  39%|███▉      | 20/51 [00:02<00:04,  6.74it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  41%|████      | 21/51 [00:03<00:04,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  43%|████▎     | 22/51 [00:03<00:04,  6.81it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  45%|████▌     | 23/51 [00:03<00:04,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  47%|████▋     | 24/51 [00:03<00:03,  6.85it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  49%|████▉     | 25/51 [00:03<00:03,  6.83it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  51%|█████     | 26/51 [00:03<00:03,  6.83it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  53%|█████▎    | 27/51 [00:03<00:03,  6.67it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  55%|█████▍    | 28/51 [00:04<00:03,  6.70it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  57%|█████▋    | 29/51 [00:04<00:03,  6.70it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  59%|█████▉    | 30/51 [00:04<00:03,  6.69it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  61%|██████    | 31/51 [00:04<00:02,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  63%|██████▎   | 32/51 [00:04<00:02,  6.83it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  65%|██████▍   | 33/51 [00:04<00:02,  6.71it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 34/51 [00:04<00:02,  6.72it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  69%|██████▊   | 35/51 [00:05<00:02,  6.71it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  71%|███████   | 36/51 [00:05<00:02,  6.72it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  73%|███████▎  | 37/51 [00:05<00:02,  6.79it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  75%|███████▍  | 38/51 [00:05<00:01,  6.78it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  76%|███████▋  | 39/51 [00:05<00:01,  6.80it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  78%|███████▊  | 40/51 [00:05<00:01,  6.76it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  80%|████████  | 41/51 [00:06<00:01,  6.70it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  82%|████████▏ | 42/51 [00:06<00:01,  6.78it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  84%|████████▍ | 43/51 [00:06<00:01,  6.65it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  86%|████████▋ | 44/51 [00:06<00:01,  6.74it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  88%|████████▊ | 45/51 [00:06<00:00,  6.75it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  90%|█████████ | 46/51 [00:06<00:00,  6.74it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  92%|█████████▏| 47/51 [00:06<00:00,  6.78it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  94%|█████████▍| 48/51 [00:07<00:00,  6.81it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  96%|█████████▌| 49/51 [00:07<00:00,  6.88it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  98%|█████████▊| 50/51 [00:07<00:00,  6.84it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 51/51 [00:07<00:00,  6.48it/s]
2026-04-19 13:07:28.697 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 51/51 [00:07<00:00,  6.78it/s]
2026-04-19 13:07:38.492 | (EngineCore pid=196) 
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/35 [00:00<?, ?it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):   3%|▎         | 1/35 [00:00<00:05,  5.94it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):   6%|▌         | 2/35 [00:00<00:05,  6.25it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):   9%|▊         | 3/35 [00:00<00:04,  6.42it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  11%|█▏        | 4/35 [00:00<00:04,  6.48it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  14%|█▍        | 5/35 [00:00<00:04,  6.56it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  17%|█▋        | 6/35 [00:00<00:04,  6.59it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  20%|██        | 7/35 [00:01<00:04,  6.66it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  23%|██▎       | 8/35 [00:01<00:04,  6.70it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  26%|██▌       | 9/35 [00:01<00:03,  6.68it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  29%|██▊       | 10/35 [00:01<00:03,  6.65it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  31%|███▏      | 11/35 [00:01<00:03,  6.62it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  34%|███▍      | 12/35 [00:01<00:03,  6.61it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  37%|███▋      | 13/35 [00:01<00:03,  6.57it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  40%|████      | 14/35 [00:02<00:03,  6.54it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  43%|████▎     | 15/35 [00:02<00:03,  6.63it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  46%|████▌     | 16/35 [00:02<00:02,  6.65it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  49%|████▊     | 17/35 [00:02<00:02,  6.63it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  51%|█████▏    | 18/35 [00:02<00:02,  6.62it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  54%|█████▍    | 19/35 [00:02<00:02,  6.66it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  57%|█████▋    | 20/35 [00:03<00:02,  6.73it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  60%|██████    | 21/35 [00:03<00:02,  6.72it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  63%|██████▎   | 22/35 [00:03<00:01,  6.77it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  66%|██████▌   | 23/35 [00:03<00:01,  6.74it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  69%|██████▊   | 24/35 [00:03<00:01,  6.77it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  71%|███████▏  | 25/35 [00:03<00:01,  6.74it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  74%|███████▍  | 26/35 [00:03<00:01,  6.74it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  77%|███████▋  | 27/35 [00:04<00:01,  6.75it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  80%|████████  | 28/35 [00:04<00:01,  6.73it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  83%|████████▎ | 29/35 [00:04<00:00,  6.82it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  86%|████████▌ | 30/35 [00:04<00:00,  6.82it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  89%|████████▊ | 31/35 [00:06<00:02,  1.50it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  91%|█████████▏| 32/35 [00:07<00:02,  1.09it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  94%|█████████▍| 33/35 [00:08<00:01,  1.47it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL):  97%|█████████▋| 34/35 [00:08<00:00,  1.92it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 35/35 [00:09<00:00,  1.17it/s]
2026-04-19 13:07:38.492 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 35/35 [00:09<00:00,  3.57it/s]
2026-04-19 13:07:38.956 | (EngineCore pid=196) INFO 04-19 11:07:38 [gpu_model_runner.py:6086] Graph capturing finished in 18 secs, took 0.41 GiB
2026-04-19 13:07:38.957 | (EngineCore pid=196) INFO 04-19 11:07:38 [gpu_worker.py:597] CUDA graph pool memory: 0.41 GiB (actual), 0.83 GiB (estimated), difference: 0.42 GiB (103.5%).
2026-04-19 13:07:39.068 | (EngineCore pid=196) INFO 04-19 11:07:39 [core.py:299] init engine (profile, create kv cache, warmup model) took 108.99 s (compilation: 51.49 s)
2026-04-19 13:07:39.582 | (EngineCore pid=196) INFO 04-19 11:07:39 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:07:39.606 | (APIServer pid=1) INFO 04-19 11:07:39 [api_server.py:598] Supported tasks: ['generate']
2026-04-19 13:07:39.964 | (APIServer pid=1) WARNING 04-19 11:07:39 [model.py:1442] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 64, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-04-19 13:07:46.215 | (APIServer pid=1) INFO 04-19 11:07:46 [hf.py:314] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
2026-04-19 13:08:01.712 | (APIServer pid=1) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 13:08:01.712 | (APIServer pid=1)   warnings.warn(
2026-04-19 13:08:01.855 | (APIServer pid=1) INFO 04-19 11:08:01 [base.py:245] Multi-modal warmup completed in 15.544s
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:37] Available routes are:
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /tokenize, Methods: POST
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /detokenize, Methods: POST
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /load, Methods: GET
2026-04-19 13:08:02.113 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /version, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /health, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /metrics, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/models, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /ping, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /ping, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /invocations, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-04-19 13:08:02.114 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-04-19 13:08:02.115 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-04-19 13:08:02.115 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-04-19 13:08:02.115 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-04-19 13:08:02.115 | (APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-04-19 13:08:02.215 | (APIServer pid=1) INFO:     Started server process [1]
2026-04-19 13:08:02.215 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-04-19 13:08:02.480 | (APIServer pid=1) INFO:     Application startup complete.