# docker compose

```yml
version: "3.9"

services:
  qwen-3-6-27b-nvfp4-mtp:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen-3-6-27b-nvfp4-mtp-stable
    hostname: qwen-3-6-27b-nvfp4-mtp
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
      # 1. FIX: Disables the autotuning that is causing the WSL2 driver reset
      FLASHINFER_AUTOTUNE: "0"
      VLLM_FLASHINFER_CHECK_SAFE_OPS: "0"
      
      # 2. FIX: Stability for Blackwell multiprocessing in WSL2
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 3. FIX: Lower utilization to 0.82 to leave "overhead" for the JIT compiler
      # WSL2 needs this extra padding to prevent driver timeouts.
      - "--gpu-memory-utilization"
      - "0.82"

      # 4. FIX: Stick to 64k for the first stable boot; we can go back to 128k later
      - "--max-model-len"
      - "65536"

      - "--max-num-seqs"
      - "2"
      - "--max-num-batched-tokens"
      - "16384"
      - "--kv-cache-dtype"
      - "fp8"

      # 5. FIX: Change 'modelopt' to 'compressed-tensors'
      # vLLM handles the sakamakismile checkpoint better with this flag.
      - "--quantization"
      - "compressed-tensors"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "qwen3"
      - "--language-model-only"
      - "--moe-backend"
      - "cutlass"

      # 6. FIX: Use the updated method string 'mtp' and lower draft tokens
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":1}'

      # 7. FIX: CRITICAL - Disable CUDA Graph capture
      # This prevents the specific 'Profiling CUDA graph memory' step where your log died.
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# Vllm log
2026-05-01 18:50:31.839 | WARNING 05-01 16:50:31 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299] 
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299]   █▄█▀ █     █     █     █  model   sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 18:50:31.934 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:299] 
2026-05-01 18:50:31.937 | (APIServer pid=1) INFO 05-01 16:50:31 [utils.py:233] non-default args: {'model_tag': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'host': '0.0.0.0', 'model': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'trust_remote_code': True, 'max_model_len': 65536, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['qwen3.6-27b-text-nvfp4-mtp'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.82, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'language_model_only': True, 'max_num_batched_tokens': 16384, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass', 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 1}}
2026-05-01 18:50:31.938 | (APIServer pid=1) WARNING 05-01 16:50:31 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 18:50:32.341 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 18:50:43.035 | (APIServer pid=1) INFO 05-01 16:50:43 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 18:50:43.069 | (APIServer pid=1) INFO 05-01 16:50:43 [nixl_utils.py:32] NIXL is available
2026-05-01 18:50:43.286 | (APIServer pid=1) INFO 05-01 16:50:43 [model.py:555] Resolved architecture: Qwen3_5ForConditionalGeneration
2026-05-01 18:50:43.286 | (APIServer pid=1) INFO 05-01 16:50:43 [model.py:1680] Using max model len 65536
2026-05-01 18:50:43.684 | (APIServer pid=1) INFO 05-01 16:50:43 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 18:50:49.715 | (APIServer pid=1) INFO 05-01 16:50:49 [model.py:555] Resolved architecture: Qwen3_5MTP
2026-05-01 18:50:49.715 | (APIServer pid=1) INFO 05-01 16:50:49 [model.py:1680] Using max model len 262144
2026-05-01 18:50:49.716 | (APIServer pid=1) INFO 05-01 16:50:49 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=16384.
2026-05-01 18:50:49.716 | (APIServer pid=1) WARNING 05-01 16:50:49 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
2026-05-01 18:50:49.716 | (APIServer pid=1) INFO 05-01 16:50:49 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 18:50:49.716 | (APIServer pid=1) WARNING 05-01 16:50:49 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-01 18:50:49.717 | (APIServer pid=1) INFO 05-01 16:50:49 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 18:50:49.717 | (APIServer pid=1) WARNING 05-01 16:50:49 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 18:50:49.717 | (APIServer pid=1) WARNING 05-01 16:50:49 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 18:50:49.717 | (APIServer pid=1) INFO 05-01 16:50:49 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 18:50:49.717 | (APIServer pid=1) INFO 05-01 16:50:49 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 18:50:52.437 | (APIServer pid=1) INFO 05-01 16:50:52 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 18:50:52.602 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 18:50:52.882 | (APIServer pid=1) INFO 05-01 16:50:52 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 18:50:59.628 | INFO 05-01 16:50:59 [nixl_utils.py:32] NIXL is available
2026-05-01 18:50:59.714 | (EngineCore pid=256) INFO 05-01 16:50:59 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', speculative_config=SpeculativeConfig(method='mtp', model='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', num_spec_tokens=1), tokenizer='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=65536, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, quantization_config=None, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-27b-text-nvfp4-mtp, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'ir_enable_torch_wrap': False, 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [16384], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['vllm_c', 'native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-05-01 18:50:59.892 | (EngineCore pid=256) WARNING 05-01 16:50:59 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 18:51:00.015 | (EngineCore pid=256) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 18:51:00.757 | (EngineCore pid=256) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 18:51:03.356 | (EngineCore pid=256) INFO 05-01 16:51:03 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 18:51:03.397 | (EngineCore pid=256) INFO 05-01 16:51:03 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:45569 backend=nccl
2026-05-01 18:51:03.653 | (EngineCore pid=256) INFO 05-01 16:51:03 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank N/A, EPLB rank N/A
2026-05-01 18:51:04.281 | (EngineCore pid=256) WARNING 05-01 16:51:04 [__init__.py:206] min_p and logit_bias parameters won't work with speculative decoding.
2026-05-01 18:51:04.315 | (EngineCore pid=256) INFO 05-01 16:51:04 [gpu_model_runner.py:4777] Starting to load model sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP...
2026-05-01 18:51:04.528 | (EngineCore pid=256) INFO 05-01 16:51:04 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 18:51:04.529 | (EngineCore pid=256) INFO 05-01 16:51:04 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 18:51:04.625 | (EngineCore pid=256) INFO 05-01 16:51:04 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 18:51:04.628 | (EngineCore pid=256) INFO 05-01 16:51:04 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 18:51:05.141 | (EngineCore pid=256) INFO 05-01 16:51:05 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 18:51:06.137 | (EngineCore pid=256) INFO 05-01 16:51:06 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-05-01 18:51:06.138 | (EngineCore pid=256) INFO 05-01 16:51:06 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.29 GiB. Available RAM: 56.31 GiB.
2026-05-01 18:51:06.138 | (EngineCore pid=256) INFO 05-01 16:51:06 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 18:51:06.138 | (EngineCore pid=256) 
2026-05-01 18:51:06.138 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-05-01 18:51:10.340 | (EngineCore pid=256) 
2026-05-01 18:51:10.340 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:04<00:00,  4.20s/it]
2026-05-01 18:51:10.340 | (EngineCore pid=256) 
2026-05-01 18:51:10.340 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:04<00:00,  4.20s/it]
2026-05-01 18:51:10.340 | (EngineCore pid=256) 
2026-05-01 18:51:12.599 | (EngineCore pid=256) INFO 05-01 16:51:12 [default_loader.py:384] Loading weights took 6.46 seconds
2026-05-01 18:51:12.687 | (EngineCore pid=256) WARNING 05-01 16:51:12 [kv_cache.py:109] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
2026-05-01 18:51:12.688 | (EngineCore pid=256) WARNING 05-01 16:51:12 [kv_cache.py:123] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
2026-05-01 18:51:12.688 | (EngineCore pid=256) WARNING 05-01 16:51:12 [kv_cache.py:162] Using uncalibrated q_scale 1.0 and/or prob_scale 1.0 with fp8 attention. This may cause accuracy issues. Please make sure q/prob scaling factors are available in the fp8 checkpoint.
2026-05-01 18:51:12.890 | (EngineCore pid=256) INFO 05-01 16:51:12 [gpu_model_runner.py:4801] Loading drafter model...
2026-05-01 18:51:13.397 | (EngineCore pid=256) INFO 05-01 16:51:13 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-05-01 18:51:13.398 | (EngineCore pid=256) INFO 05-01 16:51:13 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.29 GiB. Available RAM: 56.24 GiB.
2026-05-01 18:51:13.398 | (EngineCore pid=256) 
2026-05-01 18:51:13.398 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-05-01 18:51:12.989 | (EngineCore pid=256) 
2026-05-01 18:51:12.989 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [-00:00<00:00, -2.44it/s]
2026-05-01 18:51:12.989 | (EngineCore pid=256) 
2026-05-01 18:51:13.341 | (EngineCore pid=256) INFO 05-01 16:51:13 [default_loader.py:384] Loading weights took 1.29 seconds
2026-05-01 18:51:13.343 | (EngineCore pid=256) INFO 05-01 16:51:13 [llm_base_proposer.py:1445] Detected MTP model. Sharing target model embedding weights with the draft model.
2026-05-01 18:51:13.343 | (EngineCore pid=256) INFO 05-01 16:51:13 [llm_base_proposer.py:1501] Detected MTP model. Sharing target model lm_head weights with the draft model.
2026-05-01 18:51:13.904 | (EngineCore pid=256) INFO 05-01 16:51:13 [gpu_model_runner.py:4879] Model loading took 18.41 GiB memory and 10.177328 seconds
2026-05-01 18:51:13.905 | (EngineCore pid=256) INFO 05-01 16:51:13 [interface.py:606] Setting attention block size to 1584 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 18:51:13.905 | (EngineCore pid=256) INFO 05-01 16:51:13 [interface.py:630] Padding mamba page size by 0.51% to ensure that mamba page size and attention page size are exactly equal.
2026-05-01 18:52:08.646 | (EngineCore pid=256) INFO 05-01 16:52:08 [gpu_worker.py:440] Available KV cache memory: 4.8 GiB
2026-05-01 18:52:08.647 | (EngineCore pid=256) WARNING 05-01 16:52:08 [kv_cache_utils.py:1140] Add 3 padding layers, may waste at most 6.25% KV cache memory
2026-05-01 18:52:08.647 | (EngineCore pid=256) INFO 05-01 16:52:08 [kv_cache_utils.py:1711] GPU KV cache size: 36,432 tokens
2026-05-01 18:52:08.647 | (EngineCore pid=256) INFO 05-01 16:52:08 [kv_cache_utils.py:1716] Maximum concurrency for 65,536 tokens per request: 1.82x
2026-05-01 18:52:08.763 | (EngineCore pid=256) 2026-05-01 16:52:08,762 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 18:52:09.339 | (EngineCore pid=256) 
2026-05-01 18:52:09.339 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:52:09.339 | [AutoTuner]: Tuning fp4_gemm:  60%|██████    | 9/15 [00:00<00:00, 81.21profile/s]
2026-05-01 18:52:09.339 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:00<00:00, 27.36profile/s]
2026-05-01 18:52:09.491 | (EngineCore pid=256) 
2026-05-01 18:52:09.491 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:52:09.491 | [AutoTuner]: Tuning fp4_gemm:  73%|███████▎  | 11/15 [00:00<00:00, 101.04profile/s]
2026-05-01 18:52:09.491 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:00<00:00, 100.45profile/s]
2026-05-01 18:52:09.760 | (EngineCore pid=256) 
2026-05-01 18:52:09.760 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:52:09.760 | [AutoTuner]: Tuning fp4_gemm:  67%|██████▋   | 10/15 [00:00<00:00, 96.79profile/s]
2026-05-01 18:52:09.760 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:00<00:00, 56.32profile/s]
2026-05-01 18:52:10.969 | (EngineCore pid=256) 
2026-05-01 18:52:10.969 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/15 [00:00<?, ?profile/s]
2026-05-01 18:52:10.969 | [AutoTuner]: Tuning fp4_gemm:  40%|████      | 6/15 [00:00<00:00, 55.17profile/s]
2026-05-01 18:52:10.969 | [AutoTuner]: Tuning fp4_gemm:  80%|████████  | 12/15 [00:00<00:00, 46.51profile/s]TMA Desc Addr:   0x7ffe2fe82380
2026-05-01 18:52:10.969 | format         13
2026-05-01 18:52:10.969 | dim            3
2026-05-01 18:52:10.969 | gmem_address   0x2b12b98000
2026-05-01 18:52:10.969 | globalDim      (5120,16384,1,1,1)
2026-05-01 18:52:10.969 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.969 | boxDim         (128,128,1,1,1)
2026-05-01 18:52:10.969 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.969 | interleave     0
2026-05-01 18:52:10.969 | swizzle        2
2026-05-01 18:52:10.969 | l2Promotion    2
2026-05-01 18:52:10.969 | oobFill        0
2026-05-01 18:52:10.969 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.969 | TMA Desc Addr:   0x7ffe2fe82180
2026-05-01 18:52:10.969 | format         13
2026-05-01 18:52:10.969 | dim            3
2026-05-01 18:52:10.969 | gmem_address   0x25af6e0000
2026-05-01 18:52:10.969 | globalDim      (5120,34816,1,1,1)
2026-05-01 18:52:10.969 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.969 | boxDim         (128,128,1,1,1)
2026-05-01 18:52:10.969 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.969 | interleave     0
2026-05-01 18:52:10.969 | swizzle        2
2026-05-01 18:52:10.969 | l2Promotion    2
2026-05-01 18:52:10.969 | oobFill        0
2026-05-01 18:52:10.969 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.969 | TMA Desc Addr:   0x7ffe2fe81e00
2026-05-01 18:52:10.969 | format         1
2026-05-01 18:52:10.969 | dim            4
2026-05-01 18:52:10.969 | gmem_address   0x28cc600000
2026-05-01 18:52:10.969 | globalDim      (256,80,128,1,1)
2026-05-01 18:52:10.969 | globalStrides  (2,512,40960,5242880,0)
2026-05-01 18:52:10.969 | boxDim         (256,2,1,1,1)
2026-05-01 18:52:10.969 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.969 | interleave     0
2026-05-01 18:52:10.969 | swizzle        0
2026-05-01 18:52:10.969 | l2Promotion    2
2026-05-01 18:52:10.969 | oobFill        0
2026-05-01 18:52:10.969 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.969 | TMA Desc Addr:   0x7ffe2fe81d80
2026-05-01 18:52:10.969 | format         1
2026-05-01 18:52:10.969 | dim            4
2026-05-01 18:52:10.969 | gmem_address   0x297c0a0000
2026-05-01 18:52:10.969 | globalDim      (256,80,272,1,1)
2026-05-01 18:52:10.969 | globalStrides  (2,512,40960,11141120,0)
2026-05-01 18:52:10.969 | boxDim         (256,2,1,1,1)
2026-05-01 18:52:10.969 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.969 | interleave     0
2026-05-01 18:52:10.969 | swizzle        0
2026-05-01 18:52:10.969 | l2Promotion    2
2026-05-01 18:52:10.969 | oobFill        0
2026-05-01 18:52:10.969 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.969 | TMA Desc Addr:   0x7ffe2fe82380
2026-05-01 18:52:10.969 | format         9
2026-05-01 18:52:10.969 | dim            3
2026-05-01 18:52:10.969 | gmem_address   0x2c14b98000
2026-05-01 18:52:10.969 | globalDim      (34816,16384,1,1,1)
2026-05-01 18:52:10.969 | globalStrides  (2,69632,0,0,0)
2026-05-01 18:52:10.969 | boxDim         (32,64,1,1,1)
2026-05-01 18:52:10.969 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.969 | interleave     0
2026-05-01 18:52:10.969 | swizzle        2
2026-05-01 18:52:10.969 | l2Promotion    2
2026-05-01 18:52:10.969 | oobFill        0
2026-05-01 18:52:10.969 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.970 | TMA Desc Addr:   0x7ffe2fe82780
2026-05-01 18:52:10.970 | format         13
2026-05-01 18:52:10.970 | dim            3
2026-05-01 18:52:10.970 | gmem_address   0x2b12b98000
2026-05-01 18:52:10.970 | globalDim      (5120,16384,1,1,1)
2026-05-01 18:52:10.970 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.970 | boxDim         (256,128,1,1,1)
2026-05-01 18:52:10.970 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.970 | interleave     0
2026-05-01 18:52:10.970 | swizzle        3
2026-05-01 18:52:10.970 | l2Promotion    2
2026-05-01 18:52:10.970 | oobFill        0
2026-05-01 18:52:10.970 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.970 | TMA Desc Addr:   0x7ffe2fe82580
2026-05-01 18:52:10.970 | format         13
2026-05-01 18:52:10.970 | dim            3
2026-05-01 18:52:10.970 | gmem_address   0x25af6e0000
2026-05-01 18:52:10.970 | globalDim      (5120,34816,1,1,1)
2026-05-01 18:52:10.970 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.970 | boxDim         (256,128,1,1,1)
2026-05-01 18:52:10.970 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.970 | interleave     0
2026-05-01 18:52:10.970 | swizzle        3
2026-05-01 18:52:10.970 | l2Promotion    2
2026-05-01 18:52:10.970 | oobFill        0
2026-05-01 18:52:10.970 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.970 | TMA Desc Addr:   0x7ffe2fe82200
2026-05-01 18:52:10.970 | format         1
2026-05-01 18:52:10.970 | dim            4
2026-05-01 18:52:10.970 | gmem_address   0x28cc600000
2026-05-01 18:52:10.970 | globalDim      (256,80,128,1,1)
2026-05-01 18:52:10.970 | globalStrides  (2,512,40960,5242880,0)
2026-05-01 18:52:10.970 | boxDim         (256,4,1,1,1)
2026-05-01 18:52:10.970 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.970 | interleave     0
2026-05-01 18:52:10.970 | swizzle        0
2026-05-01 18:52:10.970 | l2Promotion    2
2026-05-01 18:52:10.970 | oobFill        0
2026-05-01 18:52:10.970 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.970 | TMA Desc Addr:   0x7ffe2fe82180
2026-05-01 18:52:10.970 | format         1
2026-05-01 18:52:10.970 | dim            4
2026-05-01 18:52:10.970 | gmem_address   0x297c0a0000
2026-05-01 18:52:10.970 | globalDim      (256,80,272,1,1)
2026-05-01 18:52:10.970 | globalStrides  (2,512,40960,11141120,0)
2026-05-01 18:52:10.970 | boxDim         (256,4,1,1,1)
2026-05-01 18:52:10.970 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.970 | interleave     0
2026-05-01 18:52:10.970 | swizzle        0
2026-05-01 18:52:10.970 | l2Promotion    2
2026-05-01 18:52:10.970 | oobFill        0
2026-05-01 18:52:10.970 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.970 | TMA Desc Addr:   0x7ffe2fe82780
2026-05-01 18:52:10.970 | format         9
2026-05-01 18:52:10.970 | dim            3
2026-05-01 18:52:10.970 | gmem_address   0x2c14b98000
2026-05-01 18:52:10.970 | globalDim      (34816,16384,1,1,1)
2026-05-01 18:52:10.970 | globalStrides  (2,69632,0,0,0)
2026-05-01 18:52:10.970 | boxDim         (32,64,1,1,1)
2026-05-01 18:52:10.970 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.970 | interleave     0
2026-05-01 18:52:10.970 | swizzle        2
2026-05-01 18:52:10.970 | l2Promotion    2
2026-05-01 18:52:10.970 | oobFill        0
2026-05-01 18:52:10.970 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82380
2026-05-01 18:52:10.971 | format         13
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x2b12b98000
2026-05-01 18:52:10.971 | globalDim      (5120,16384,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (256,128,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        3
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82180
2026-05-01 18:52:10.971 | format         13
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x25af6e0000
2026-05-01 18:52:10.971 | globalDim      (5120,34816,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (256,128,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        3
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe81e00
2026-05-01 18:52:10.971 | format         1
2026-05-01 18:52:10.971 | dim            4
2026-05-01 18:52:10.971 | gmem_address   0x28cc600000
2026-05-01 18:52:10.971 | globalDim      (256,80,128,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,512,40960,5242880,0)
2026-05-01 18:52:10.971 | boxDim         (256,4,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        0
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe81d80
2026-05-01 18:52:10.971 | format         1
2026-05-01 18:52:10.971 | dim            4
2026-05-01 18:52:10.971 | gmem_address   0x297c0a0000
2026-05-01 18:52:10.971 | globalDim      (256,80,272,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,512,40960,11141120,0)
2026-05-01 18:52:10.971 | boxDim         (256,4,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        0
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82380
2026-05-01 18:52:10.971 | format         9
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x2c14b98000
2026-05-01 18:52:10.971 | globalDim      (34816,16384,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,69632,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (32,64,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        2
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82780
2026-05-01 18:52:10.971 | format         13
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x2b12b98000
2026-05-01 18:52:10.971 | globalDim      (5120,16384,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (128,256,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        2
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82580
2026-05-01 18:52:10.971 | format         13
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x25af6e0000
2026-05-01 18:52:10.971 | globalDim      (5120,34816,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (128,128,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        2
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82200
2026-05-01 18:52:10.971 | format         1
2026-05-01 18:52:10.971 | dim            4
2026-05-01 18:52:10.971 | gmem_address   0x28cc600000
2026-05-01 18:52:10.971 | globalDim      (256,128,80,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,40960,512,5242880,0)
2026-05-01 18:52:10.971 | boxDim         (256,2,2,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        0
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82180
2026-05-01 18:52:10.971 | format         1
2026-05-01 18:52:10.971 | dim            4
2026-05-01 18:52:10.971 | gmem_address   0x297c0a0000
2026-05-01 18:52:10.971 | globalDim      (256,80,272,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,512,40960,11141120,0)
2026-05-01 18:52:10.971 | boxDim         (256,2,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        0
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.971 | TMA Desc Addr:   0x7ffe2fe82780
2026-05-01 18:52:10.971 | format         9
2026-05-01 18:52:10.971 | dim            3
2026-05-01 18:52:10.971 | gmem_address   0x2c14b98000
2026-05-01 18:52:10.971 | globalDim      (34816,16384,1,1,1)
2026-05-01 18:52:10.971 | globalStrides  (2,69632,0,0,0)
2026-05-01 18:52:10.971 | boxDim         (32,64,1,1,1)
2026-05-01 18:52:10.971 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.971 | interleave     0
2026-05-01 18:52:10.971 | swizzle        2
2026-05-01 18:52:10.971 | l2Promotion    2
2026-05-01 18:52:10.971 | oobFill        0
2026-05-01 18:52:10.971 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.972 | 2026-05-01 16:52:10,972 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 6 unsupported tactic(s) for fp4_gemm (enable debug logs to see details)
2026-05-01 18:52:10.972 | (EngineCore pid=256) 
2026-05-01 18:52:10.972 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 15/15 [00:01<00:00, 12.41profile/s]
2026-05-01 18:52:10.972 | TMA Desc Addr:   0x7ffe2fe82980
2026-05-01 18:52:10.972 | format         13
2026-05-01 18:52:10.972 | dim            3
2026-05-01 18:52:10.972 | gmem_address   0x2990ad8000
2026-05-01 18:52:10.972 | globalDim      (5120,16384,1,1,1)
2026-05-01 18:52:10.972 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.972 | boxDim         (128,128,1,1,1)
2026-05-01 18:52:10.972 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.972 | interleave     0
2026-05-01 18:52:10.972 | swizzle        2
2026-05-01 18:52:10.972 | l2Promotion    2
2026-05-01 18:52:10.972 | oobFill        0
2026-05-01 18:52:10.972 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.972 | TMA Desc Addr:   0x7ffe2fe82780
2026-05-01 18:52:10.972 | format         13
2026-05-01 18:52:10.972 | dim            3
2026-05-01 18:52:10.972 | gmem_address   0x25af6e0000
2026-05-01 18:52:10.972 | globalDim      (5120,34816,1,1,1)
2026-05-01 18:52:10.972 | globalStrides  (0,2560,0,0,0)
2026-05-01 18:52:10.972 | boxDim         (128,128,1,1,1)
2026-05-01 18:52:10.972 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.972 | interleave     0
2026-05-01 18:52:10.972 | swizzle        2
2026-05-01 18:52:10.972 | l2Promotion    2
2026-05-01 18:52:10.972 | oobFill        0
2026-05-01 18:52:10.972 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.972 | TMA Desc Addr:   0x7ffe2fe82400
2026-05-01 18:52:10.972 | format         1
2026-05-01 18:52:10.972 | dim            4
2026-05-01 18:52:10.972 | gmem_address   0x2602b40000
2026-05-01 18:52:10.972 | globalDim      (256,80,128,1,1)
2026-05-01 18:52:10.972 | globalStrides  (2,512,40960,5242880,0)
2026-05-01 18:52:10.972 | boxDim         (256,2,1,1,1)
2026-05-01 18:52:10.972 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.972 | interleave     0
2026-05-01 18:52:10.972 | swizzle        0
2026-05-01 18:52:10.972 | l2Promotion    2
2026-05-01 18:52:10.972 | oobFill        0
2026-05-01 18:52:10.972 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.972 | TMA Desc Addr:   0x7ffe2fe82380
2026-05-01 18:52:10.972 | format         1
2026-05-01 18:52:10.972 | dim            4
2026-05-01 18:52:10.972 | gmem_address   0x297c0a0000
2026-05-01 18:52:10.972 | globalDim      (256,80,272,1,1)
2026-05-01 18:52:10.972 | globalStrides  (2,512,40960,11141120,0)
2026-05-01 18:52:10.972 | boxDim         (256,2,1,1,1)
2026-05-01 18:52:10.972 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.972 | interleave     0
2026-05-01 18:52:10.972 | swizzle        0
2026-05-01 18:52:10.972 | l2Promotion    2
2026-05-01 18:52:10.972 | oobFill        0
2026-05-01 18:52:10.972 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.972 | TMA Desc Addr:   0x7ffe2fe82980
2026-05-01 18:52:10.972 | format         9
2026-05-01 18:52:10.972 | dim            3
2026-05-01 18:52:10.972 | gmem_address   0x2b26b98000
2026-05-01 18:52:10.972 | globalDim      (34816,16384,1,1,1)
2026-05-01 18:52:10.972 | globalStrides  (2,69632,0,0,0)
2026-05-01 18:52:10.972 | boxDim         (32,64,1,1,1)
2026-05-01 18:52:10.972 | elementStrides (1,1,1,1,1)
2026-05-01 18:52:10.972 | interleave     0
2026-05-01 18:52:10.972 | swizzle        2
2026-05-01 18:52:10.972 | l2Promotion    2
2026-05-01 18:52:10.972 | oobFill        0
2026-05-01 18:52:10.972 | Error: Failed to initialize the TMA descriptor 2
2026-05-01 18:52:10.973 | (EngineCore pid=256) 2026-05-01 16:52:10,973 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136] EngineCore failed to start.
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136] Traceback (most recent call last):
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     super().__init__(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 283, in _initialize_kv_caches
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     self.model_executor.initialize_from_config(kv_cache_configs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 124, in initialize_from_config
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     compilation_times: list[CompilationTimes] = self.collective_rpc(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                                                 ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) Process EngineCore:
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     result = run_method(self.driver_worker, method, args, kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 586, in compile_or_warm_up_model
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     kernel_warmup(self)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 46, in kernel_warmup
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     flashinfer_autotune(worker.model_runner)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 103, in flashinfer_autotune
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     runner._dummy_run(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5537, in _dummy_run
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     outputs = self.model(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]               ^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 695, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     hidden_states = self.language_model.model(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 467, in __call__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self.forward(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 518, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     hidden_states, residual = layer(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                               ^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 434, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     hidden_states = self.mlp(hidden_states)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                     ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_moe.py", line 115, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     gate_up, _ = self.gate_up_proj(x)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                  ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/linear.py", line 587, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     output_parallel = self.quant_method.apply(self, input_, bias)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/modelopt.py", line 1208, in apply
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self.kernel.apply_weights(layer=layer, x=x, bias=bias)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/kernels/linear/nvfp4/flashinfer.py", line 73, in apply_weights
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     out = flashinfer_scaled_fp4_mm(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]           ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 676, in flashinfer_scaled_fp4_mm
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return flashinfer_mm_fp4(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 698, in __call__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._opoverload(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_ops.py", line 865, in __call__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self._op(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 347, in backend_impl
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     result = self._backend_fns[device_type](*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_compile.py", line 54, in inner
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return disable_fn(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return fn(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 382, in wrapped_fn
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return fn(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 486, in flashinfer_mm_fp4
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return flashinfer_mm_fp4_(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/utils.py", line 1246, in wrapper
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 5100, in mm_fp4
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     runner(inputs=inputs, tactic=tactic)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 372, in __call__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     return self.forward(inputs, **kwargs)
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 989, in forward
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]     module.fp4_gemm(
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136]   File "python/tvm_ffi/cython/function.pxi", line 929, in tvm_ffi.core.Function.__call__
2026-05-01 18:52:10.981 | (EngineCore pid=256) ERROR 05-01 16:52:10 [core.py:1136] RuntimeError: [FP4 gemm Runner] Failed to initialize cutlass FP4 gemm on sm120/sm121. Error: Error Internal
2026-05-01 18:52:10.982 | (EngineCore pid=256) Traceback (most recent call last):
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 18:52:10.983 | (EngineCore pid=256)     self.run()
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 18:52:10.983 | (EngineCore pid=256)     self._target(*self._args, **self._kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 18:52:10.983 | (EngineCore pid=256)     raise e
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 18:52:10.983 | (EngineCore pid=256)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     super().__init__(
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 128, in __init__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     kv_cache_config = self._initialize_kv_caches(vllm_config)
2026-05-01 18:52:10.983 | (EngineCore pid=256)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 283, in _initialize_kv_caches
2026-05-01 18:52:10.983 | (EngineCore pid=256)     self.model_executor.initialize_from_config(kv_cache_configs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 124, in initialize_from_config
2026-05-01 18:52:10.983 | (EngineCore pid=256)     compilation_times: list[CompilationTimes] = self.collective_rpc(
2026-05-01 18:52:10.983 | (EngineCore pid=256)                                                 ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 80, in collective_rpc
2026-05-01 18:52:10.983 | (EngineCore pid=256)     result = run_method(self.driver_worker, method, args, kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/serial_utils.py", line 510, in run_method
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 586, in compile_or_warm_up_model
2026-05-01 18:52:10.983 | (EngineCore pid=256)     kernel_warmup(self)
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 46, in kernel_warmup
2026-05-01 18:52:10.983 | (EngineCore pid=256)     flashinfer_autotune(worker.model_runner)
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/warmup/kernel_warmup.py", line 103, in flashinfer_autotune
2026-05-01 18:52:10.983 | (EngineCore pid=256)     runner._dummy_run(
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/utils/_contextlib.py", line 124, in decorate_context
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 5537, in _dummy_run
2026-05-01 18:52:10.983 | (EngineCore pid=256)     outputs = self.model(
2026-05-01 18:52:10.983 | (EngineCore pid=256)               ^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 695, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     hidden_states = self.language_model.model(
2026-05-01 18:52:10.983 | (EngineCore pid=256)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 467, in __call__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self.forward(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 518, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     hidden_states, residual = layer(
2026-05-01 18:52:10.983 | (EngineCore pid=256)                               ^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 434, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     hidden_states = self.mlp(hidden_states)
2026-05-01 18:52:10.983 | (EngineCore pid=256)                     ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_moe.py", line 115, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     gate_up, _ = self.gate_up_proj(x)
2026-05-01 18:52:10.983 | (EngineCore pid=256)                  ^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1779, in _wrapped_call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._call_impl(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/nn/modules/module.py", line 1790, in _call_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return forward_call(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/linear.py", line 587, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     output_parallel = self.quant_method.apply(self, input_, bias)
2026-05-01 18:52:10.983 | (EngineCore pid=256)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/modelopt.py", line 1208, in apply
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self.kernel.apply_weights(layer=layer, x=x, bias=bias)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/kernels/linear/nvfp4/flashinfer.py", line 73, in apply_weights
2026-05-01 18:52:10.983 | (EngineCore pid=256)     out = flashinfer_scaled_fp4_mm(
2026-05-01 18:52:10.983 | (EngineCore pid=256)           ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 676, in flashinfer_scaled_fp4_mm
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return flashinfer_mm_fp4(
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 698, in __call__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._opoverload(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_ops.py", line 865, in __call__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self._op(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 347, in backend_impl
2026-05-01 18:52:10.983 | (EngineCore pid=256)     result = self._backend_fns[device_type](*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_compile.py", line 54, in inner
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return disable_fn(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_dynamo/eval_frame.py", line 1263, in _fn
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return fn(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/torch/_library/custom_ops.py", line 382, in wrapped_fn
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return fn(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/vllm/utils/flashinfer.py", line 486, in flashinfer_mm_fp4
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return flashinfer_mm_fp4_(
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/utils.py", line 1246, in wrapper
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return func(*args, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 5100, in mm_fp4
2026-05-01 18:52:10.983 | (EngineCore pid=256)     runner(inputs=inputs, tactic=tactic)
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/autotuner.py", line 372, in __call__
2026-05-01 18:52:10.983 | (EngineCore pid=256)     return self.forward(inputs, **kwargs)
2026-05-01 18:52:10.983 | (EngineCore pid=256)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "/usr/local/lib/python3.12/dist-packages/flashinfer/gemm/gemm_base.py", line 989, in forward
2026-05-01 18:52:10.983 | (EngineCore pid=256)     module.fp4_gemm(
2026-05-01 18:52:10.983 | (EngineCore pid=256)   File "python/tvm_ffi/cython/function.pxi", line 929, in tvm_ffi.core.Function.__call__
2026-05-01 18:52:10.983 | (EngineCore pid=256) RuntimeError: [FP4 gemm Runner] Failed to initialize cutlass FP4 gemm on sm120/sm121. Error: Error Internal
2026-05-01 18:52:10.983 | [rank0]:[W501 16:52:10.789509421 CUDAGuardImpl.h:126] Warning: CUDA warning: out of memory (function destroyEvent)
2026-05-01 18:52:10.207 | [rank0]:[W501 16:52:10.404837240 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 18:52:11.406 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 18:52:11.406 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 18:52:11.406 | (APIServer pid=1)     sys.exit(main())
2026-05-01 18:52:11.406 | (APIServer pid=1)              ^^^^^^
2026-05-01 18:52:11.406 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 18:52:11.406 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 18:52:11.406 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 18:52:11.407 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 18:52:11.407 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 18:52:11.407 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 18:52:11.407 | (APIServer pid=1)     return runner.run(main)
2026-05-01 18:52:11.407 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 18:52:11.407 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 18:52:11.407 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 18:52:11.407 | (APIServer pid=1)     return await main
2026-05-01 18:52:11.407 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 18:52:11.407 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 18:52:11.407 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 18:52:11.408 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:52:11.408 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:52:11.408 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 18:52:11.408 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:52:11.408 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:52:11.408 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 18:52:11.408 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 18:52:11.408 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 18:52:11.408 | (APIServer pid=1)     return cls(
2026-05-01 18:52:11.408 | (APIServer pid=1)            ^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 18:52:11.408 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 18:52:11.408 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:11.408 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 18:52:11.408 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 18:52:11.408 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 18:52:11.408 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.408 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 18:52:11.409 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 18:52:11.409 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:52:11.409 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 18:52:11.409 | (APIServer pid=1)     super().__init__(
2026-05-01 18:52:11.409 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 18:52:11.409 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 18:52:11.409 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 18:52:11.409 | (APIServer pid=1)     next(self.gen)
2026-05-01 18:52:11.409 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 18:52:11.409 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 18:52:11.409 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 18:52:11.409 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 18:52:11.409 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}