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
      # JIT Tuning disabled to protect the WSL2 driver
      FLASHINFER_AUTOTUNE: "0"
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"

    command:
      - "--model"
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 1. FIX: Just use the valid flag to bypass the missing vision config
      - "--language-model-only"

      # 2. CONSERVATIVE MEMORY & CONTEXT
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "32768"
      - "--kv-cache-dtype"
      - "fp8"

      # 3. KERNEL STABILITY (Triton over Cutlass to avoid TMA descriptor crash)
      - "--quantization"
      - "compressed-tensors"
      - "--moe-backend"
      - "triton" 

      # 4. ENGINE ERGONOMICS
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "qwen3"
      
      # 5. WSL2 GRAPH CRASH PREVENTION
      # quote: (APIServer pid=1) INFO 05-01 17:08:18 [vllm.py:1089] Cudagraph is disabled under eager mode
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```    

# vllm log - really slow
2026-05-01 19:08:06.391 | WARNING 05-01 17:08:06 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:08:06.486 | WARNING 05-01 17:08:06 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299] 
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299]   █▄█▀ █     █     █     █  model   sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 19:08:06.490 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:299] 
2026-05-01 19:08:06.493 | (APIServer pid=1) INFO 05-01 17:08:06 [utils.py:233] non-default args: {'model_tag': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'host': '0.0.0.0', 'model': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'trust_remote_code': True, 'max_model_len': 32768, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['qwen3.6-27b-text-nvfp4-mtp'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'language_model_only': True, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-05-01 19:08:06.998 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 19:08:17.909 | (APIServer pid=1) INFO 05-01 17:08:17 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 19:08:17.941 | (APIServer pid=1) INFO 05-01 17:08:17 [nixl_utils.py:32] NIXL is available
2026-05-01 19:08:18.143 | (APIServer pid=1) INFO 05-01 17:08:18 [model.py:555] Resolved architecture: Qwen3_5ForConditionalGeneration
2026-05-01 19:08:18.143 | (APIServer pid=1) INFO 05-01 17:08:18 [model.py:1680] Using max model len 32768
2026-05-01 19:08:18.586 | (APIServer pid=1) INFO 05-01 17:08:18 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 19:08:18.587 | (APIServer pid=1) WARNING 05-01 17:08:18 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
2026-05-01 19:08:18.587 | (APIServer pid=1) INFO 05-01 17:08:18 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 19:08:18.587 | (APIServer pid=1) WARNING 05-01 17:08:18 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-01 19:08:18.587 | (APIServer pid=1) INFO 05-01 17:08:18 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 19:08:18.587 | (APIServer pid=1) WARNING 05-01 17:08:18 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 19:08:18.587 | (APIServer pid=1) WARNING 05-01 17:08:18 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 19:08:18.587 | (APIServer pid=1) INFO 05-01 17:08:18 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 19:08:18.588 | (APIServer pid=1) INFO 05-01 17:08:18 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 19:08:21.326 | (APIServer pid=1) INFO 05-01 17:08:21 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 19:08:21.485 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 19:08:21.512 | (APIServer pid=1) INFO 05-01 17:08:21 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 19:08:28.085 | INFO 05-01 17:08:28 [nixl_utils.py:32] NIXL is available
2026-05-01 19:08:28.173 | (EngineCore pid=187) INFO 05-01 17:08:28 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', speculative_config=None, tokenizer='sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=32768, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, quantization_config=None, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-27b-text-nvfp4-mtp, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'ir_enable_torch_wrap': False, 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [2048], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['vllm_c', 'native']), enable_flashinfer_autotune=True, moe_backend='triton')
2026-05-01 19:08:28.357 | (EngineCore pid=187) WARNING 05-01 17:08:28 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:08:28.478 | (EngineCore pid=187) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 19:08:29.022 | (EngineCore pid=187) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 19:08:31.545 | (EngineCore pid=187) INFO 05-01 17:08:31 [registry.py:126] All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.
2026-05-01 19:08:31.587 | (EngineCore pid=187) INFO 05-01 17:08:31 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:59169 backend=nccl
2026-05-01 19:08:31.839 | (EngineCore pid=187) INFO 05-01 17:08:31 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank N/A, EPLB rank N/A
2026-05-01 19:08:32.486 | (EngineCore pid=187) INFO 05-01 17:08:32 [gpu_model_runner.py:4777] Starting to load model sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP...
2026-05-01 19:08:32.716 | (EngineCore pid=187) INFO 05-01 17:08:32 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 19:08:32.717 | (EngineCore pid=187) INFO 05-01 17:08:32 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 19:08:32.825 | (EngineCore pid=187) INFO 05-01 17:08:32 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 19:08:32.828 | (EngineCore pid=187) INFO 05-01 17:08:32 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 19:08:33.706 | (EngineCore pid=187) INFO 05-01 17:08:33 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
2026-05-01 19:08:34.711 | (EngineCore pid=187) INFO 05-01 17:08:34 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-05-01 19:08:34.712 | (EngineCore pid=187) INFO 05-01 17:08:34 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 18.29 GiB. Available RAM: 56.42 GiB.
2026-05-01 19:08:34.712 | (EngineCore pid=187) INFO 05-01 17:08:34 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-05-01 19:08:34.712 | (EngineCore pid=187) 
2026-05-01 19:08:34.712 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-05-01 19:08:52.245 | (EngineCore pid=187) 
2026-05-01 19:08:52.245 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:17<00:00, 17.53s/it]
2026-05-01 19:08:52.245 | (EngineCore pid=187) 
2026-05-01 19:08:52.245 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:17<00:00, 17.53s/it]
2026-05-01 19:08:52.245 | (EngineCore pid=187) 
2026-05-01 19:08:53.050 | (EngineCore pid=187) INFO 05-01 17:08:53 [default_loader.py:384] Loading weights took 18.35 seconds
2026-05-01 19:08:53.165 | (EngineCore pid=187) WARNING 05-01 17:08:53 [kv_cache.py:109] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
2026-05-01 19:08:53.166 | (EngineCore pid=187) WARNING 05-01 17:08:53 [kv_cache.py:123] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
2026-05-01 19:08:53.166 | (EngineCore pid=187) WARNING 05-01 17:08:53 [kv_cache.py:162] Using uncalibrated q_scale 1.0 and/or prob_scale 1.0 with fp8 attention. This may cause accuracy issues. Please make sure q/prob scaling factors are available in the fp8 checkpoint.
2026-05-01 19:08:53.839 | (EngineCore pid=187) INFO 05-01 17:08:53 [gpu_model_runner.py:4879] Model loading took 17.62 GiB memory and 20.695716 seconds
2026-05-01 19:08:53.840 | (EngineCore pid=187) INFO 05-01 17:08:53 [interface.py:606] Setting attention block size to 1568 tokens to ensure that attention page size is >= mamba page size.
2026-05-01 19:08:53.840 | (EngineCore pid=187) INFO 05-01 17:08:53 [interface.py:630] Padding mamba page size by 0.13% to ensure that mamba page size and attention page size are exactly equal.
2026-05-01 19:09:48.200 | (EngineCore pid=187) INFO 05-01 17:09:48 [gpu_worker.py:440] Available KV cache memory: 6.67 GiB
2026-05-01 19:09:48.201 | (EngineCore pid=187) INFO 05-01 17:09:48 [kv_cache_utils.py:1711] GPU KV cache size: 53,312 tokens
2026-05-01 19:09:48.201 | (EngineCore pid=187) INFO 05-01 17:09:48 [kv_cache_utils.py:1716] Maximum concurrency for 32,768 tokens per request: 5.15x
2026-05-01 19:09:48.378 | (EngineCore pid=187) 2026-05-01 17:09:48,378 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-05-01 19:09:48.574 | (EngineCore pid=187) 
2026-05-01 19:09:48.574 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:48.574 | [AutoTuner]: Tuning fp4_gemm:  67%|██████▋   | 8/12 [00:00<00:00, 75.80profile/s]
2026-05-01 19:09:48.574 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 63.64profile/s]
2026-05-01 19:09:48.695 | (EngineCore pid=187) 
2026-05-01 19:09:48.695 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:48.695 | [AutoTuner]: Tuning fp4_gemm:  92%|█████████▏| 11/12 [00:00<00:00, 101.44profile/s]
2026-05-01 19:09:48.695 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 101.15profile/s]
2026-05-01 19:09:48.829 | (EngineCore pid=187) 
2026-05-01 19:09:48.829 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:48.829 | [AutoTuner]: Tuning fp4_gemm:  83%|████████▎ | 10/12 [00:00<00:00, 96.02profile/s]
2026-05-01 19:09:48.829 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 91.06profile/s]
2026-05-01 19:09:49.105 | (EngineCore pid=187) 
2026-05-01 19:09:49.105 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:49.105 | [AutoTuner]: Tuning fp4_gemm:  50%|█████     | 6/12 [00:00<00:00, 51.12profile/s]
2026-05-01 19:09:49.105 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 42.88profile/s]
2026-05-01 19:09:49.105 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 43.92profile/s]
2026-05-01 19:09:49.285 | (EngineCore pid=187) 
2026-05-01 19:09:49.285 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:49.285 | [AutoTuner]: Tuning fp4_gemm:  67%|██████▋   | 8/12 [00:00<00:00, 78.97profile/s]
2026-05-01 19:09:49.285 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 67.47profile/s]
2026-05-01 19:09:49.499 | (EngineCore pid=187) 
2026-05-01 19:09:49.499 | [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/12 [00:00<?, ?profile/s]
2026-05-01 19:09:49.499 | [AutoTuner]: Tuning fp4_gemm:  75%|███████▌  | 9/12 [00:00<00:00, 86.48profile/s]
2026-05-01 19:09:49.499 | [AutoTuner]: Tuning fp4_gemm: 100%|██████████| 12/12 [00:00<00:00, 75.52profile/s]
2026-05-01 19:09:50.755 | (EngineCore pid=187) 2026-05-01 17:09:50,755 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-05-01 19:09:50.893 | (EngineCore pid=187) INFO 05-01 17:09:50 [core.py:306] init engine (profile, create kv cache, warmup model) took 57.05 s
2026-05-01 19:09:51.184 | (EngineCore pid=187) INFO 05-01 17:09:51 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 19:09:51.184 | (EngineCore pid=187) WARNING 05-01 17:09:51 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 19:09:51.184 | (EngineCore pid=187) WARNING 05-01 17:09:51 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 19:09:51.184 | (EngineCore pid=187) INFO 05-01 17:09:51 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 19:09:51.184 | (EngineCore pid=187) INFO 05-01 17:09:51 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 19:09:51.184 | (EngineCore pid=187) INFO 05-01 17:09:51 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 19:09:51.189 | (APIServer pid=1) INFO 05-01 17:09:51 [api_server.py:598] Supported tasks: ['generate']
2026-05-01 19:09:51.796 | (APIServer pid=1) WARNING 05-01 17:09:51 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-05-01 19:09:54.246 | (APIServer pid=1) INFO 05-01 17:09:54 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
2026-05-01 19:09:55.573 | (APIServer pid=1) WARNING 05-01 17:09:55 [base.py:265] Multi-modal warmup failed
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:37] Available routes are:
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /tokenize, Methods: POST
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /detokenize, Methods: POST
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /load, Methods: GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /version, Methods: GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /health, Methods: GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /metrics, Methods: GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/models, Methods: GET
2026-05-01 19:09:55.825 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /ping, Methods: GET
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /ping, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /invocations, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-05-01 19:09:55.826 | (APIServer pid=1) INFO 05-01 17:09:55 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-05-01 19:09:55.921 | (APIServer pid=1) INFO:     Started server process [1]
2026-05-01 19:09:55.921 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-05-01 19:09:56.179 | (APIServer pid=1) INFO:     Application startup complete.
2026-05-01 19:15:06.687 | (APIServer pid=1) INFO:     172.18.0.1:48308 - "GET /v1/models HTTP/1.1" 200 OK
2026-05-01 19:17:56.399 | (APIServer pid=1) INFO 05-01 17:17:56 [loggers.py:271] Engine 000: Avg prompt throughput: 2.4 tokens/s, Avg generation throughput: 0.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 19:18:06.398 | (APIServer pid=1) INFO 05-01 17:18:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-05-01 19:21:05.110 | (APIServer pid=1) INFO:     172.18.0.1:43372 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:21:16.481 | (APIServer pid=1) INFO 05-01 17:21:16 [loggers.py:271] Engine 000: Avg prompt throughput: 1872.3 tokens/s, Avg generation throughput: 5.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.9%, Prefix cache hit rate: 0.0%
2026-05-01 19:21:22.202 | (APIServer pid=1) INFO:     172.18.0.1:43372 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:21:26.507 | (APIServer pid=1) INFO 05-01 17:21:26 [loggers.py:271] Engine 000: Avg prompt throughput: 230.8 tokens/s, Avg generation throughput: 6.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.6%, Prefix cache hit rate: 45.0%
2026-05-01 19:21:36.507 | (APIServer pid=1) INFO 05-01 17:21:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.6%, Prefix cache hit rate: 45.0%
2026-05-01 19:21:46.508 | (APIServer pid=1) INFO 05-01 17:21:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 5.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 45.0%
2026-05-01 19:21:56.526 | (APIServer pid=1) INFO 05-01 17:21:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 45.0%
2026-05-01 19:22:51.457 | (APIServer pid=1) INFO:     172.18.0.1:50376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:22:56.572 | (APIServer pid=1) INFO 05-01 17:22:56 [loggers.py:271] Engine 000: Avg prompt throughput: 889.8 tokens/s, Avg generation throughput: 2.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:06.573 | (APIServer pid=1) INFO 05-01 17:23:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:16.573 | (APIServer pid=1) INFO 05-01 17:23:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:26.598 | (APIServer pid=1) INFO 05-01 17:23:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:36.598 | (APIServer pid=1) INFO 05-01 17:23:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:46.599 | (APIServer pid=1) INFO 05-01 17:23:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 54.6%
2026-05-01 19:23:53.458 | (APIServer pid=1) INFO:     172.18.0.1:50376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:23:56.627 | (APIServer pid=1) INFO 05-01 17:23:56 [loggers.py:271] Engine 000: Avg prompt throughput: 1034.8 tokens/s, Avg generation throughput: 5.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 56.9%
2026-05-01 19:24:06.627 | (APIServer pid=1) INFO 05-01 17:24:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 56.9%
2026-05-01 19:24:16.628 | (APIServer pid=1) INFO 05-01 17:24:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.2%, Prefix cache hit rate: 56.9%
2026-05-01 19:24:18.353 | (APIServer pid=1) INFO:     172.18.0.1:50376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:24:26.653 | (APIServer pid=1) INFO 05-01 17:24:26 [loggers.py:271] Engine 000: Avg prompt throughput: 339.0 tokens/s, Avg generation throughput: 6.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:24:36.654 | (APIServer pid=1) INFO 05-01 17:24:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:24:46.654 | (APIServer pid=1) INFO 05-01 17:24:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:24:56.679 | (APIServer pid=1) INFO 05-01 17:24:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:06.679 | (APIServer pid=1) INFO 05-01 17:25:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:16.680 | (APIServer pid=1) INFO 05-01 17:25:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:26.705 | (APIServer pid=1) INFO 05-01 17:25:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:36.705 | (APIServer pid=1) INFO 05-01 17:25:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:46.706 | (APIServer pid=1) INFO 05-01 17:25:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:25:56.732 | (APIServer pid=1) INFO 05-01 17:25:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:26:06.732 | (APIServer pid=1) INFO 05-01 17:26:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.3%, Prefix cache hit rate: 61.8%
2026-05-01 19:26:16.733 | (APIServer pid=1) INFO 05-01 17:26:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 4.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.8%
2026-05-01 19:26:26.749 | (APIServer pid=1) INFO 05-01 17:26:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.8%
2026-05-01 19:29:46.865 | (APIServer pid=1) INFO 05-01 17:29:46 [loggers.py:271] Engine 000: Avg prompt throughput: 2.4 tokens/s, Avg generation throughput: 2.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:29:56.880 | (APIServer pid=1) INFO 05-01 17:29:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:06.880 | (APIServer pid=1) INFO 05-01 17:30:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:16.881 | (APIServer pid=1) INFO 05-01 17:30:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:26.904 | (APIServer pid=1) INFO 05-01 17:30:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:36.905 | (APIServer pid=1) INFO 05-01 17:30:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:46.905 | (APIServer pid=1) INFO 05-01 17:30:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:30:56.933 | (APIServer pid=1) INFO 05-01 17:30:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:06.934 | (APIServer pid=1) INFO 05-01 17:31:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:16.934 | (APIServer pid=1) INFO 05-01 17:31:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:26.953 | (APIServer pid=1) INFO 05-01 17:31:26 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:36.953 | (APIServer pid=1) INFO 05-01 17:31:36 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:46.953 | (APIServer pid=1) INFO 05-01 17:31:46 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:31:56.983 | (APIServer pid=1) INFO 05-01 17:31:56 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:32:06.984 | (APIServer pid=1) INFO 05-01 17:32:06 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:32:16.984 | (APIServer pid=1) INFO 05-01 17:32:16 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 1.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.7%
2026-05-01 19:32:27.003 | (APIServer pid=1) INFO 05-01 17:32:27 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.7%
2026-05-01 19:35:27.152 | (APIServer pid=1) INFO 05-01 17:35:27 [loggers.py:271] Engine 000: Avg prompt throughput: 10.7 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:35:37.152 | (APIServer pid=1) INFO 05-01 17:35:37 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:35:47.153 | (APIServer pid=1) INFO 05-01 17:35:47 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:35:57.179 | (APIServer pid=1) INFO 05-01 17:35:57 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:07.179 | (APIServer pid=1) INFO 05-01 17:36:07 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:17.180 | (APIServer pid=1) INFO 05-01 17:36:17 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:27.204 | (APIServer pid=1) INFO 05-01 17:36:27 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:37.204 | (APIServer pid=1) INFO 05-01 17:36:37 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:47.204 | (APIServer pid=1) INFO 05-01 17:36:47 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:36:57.229 | (APIServer pid=1) INFO 05-01 17:36:57 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:07.229 | (APIServer pid=1) INFO 05-01 17:37:07 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:17.229 | (APIServer pid=1) INFO 05-01 17:37:17 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:27.252 | (APIServer pid=1) INFO 05-01 17:37:27 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:37.253 | (APIServer pid=1) INFO 05-01 17:37:37 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:47.253 | (APIServer pid=1) INFO 05-01 17:37:47 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:37:57.278 | (APIServer pid=1) INFO 05-01 17:37:57 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:07.278 | (APIServer pid=1) INFO 05-01 17:38:07 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:17.278 | (APIServer pid=1) INFO 05-01 17:38:17 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:27.303 | (APIServer pid=1) INFO 05-01 17:38:27 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:37.304 | (APIServer pid=1) INFO 05-01 17:38:37 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:47.303 | (APIServer pid=1) INFO 05-01 17:38:47 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 61.7%
2026-05-01 19:38:57.327 | (APIServer pid=1) INFO 05-01 17:38:57 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:07.328 | (APIServer pid=1) INFO 05-01 17:39:07 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:17.328 | (APIServer pid=1) INFO 05-01 17:39:17 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:27.352 | (APIServer pid=1) INFO 05-01 17:39:27 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:37.353 | (APIServer pid=1) INFO 05-01 17:39:37 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:46.390 | (APIServer pid=1) INFO:     172.18.0.1:47494 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-05-01 19:39:47.354 | (APIServer pid=1) INFO 05-01 17:39:47 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 6.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.7%
2026-05-01 19:39:57.371 | (APIServer pid=1) INFO 05-01 17:39:57 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 61.7%
2026-05-01 19:43:58.066 | (EngineCore pid=187) INFO 05-01 17:43:58 [core.py:1238] Shutdown initiated (timeout=0)
2026-05-01 19:43:58.066 | (EngineCore pid=187) INFO 05-01 17:43:58 [core.py:1261] Shutdown complete
2026-05-01 19:43:58.090 | (APIServer pid=1) INFO:     Shutting down
2026-05-01 19:43:58.190 | (APIServer pid=1) INFO:     Waiting for application shutdown.
2026-05-01 19:43:58.190 | (APIServer pid=1) INFO:     Application shutdown complete.
2026-05-01 19:43:58.190 | (APIServer pid=1) INFO:     Finished server process [1]
2026-05-01 19:43:58.813 | [rank0]:[W501 17:43:58.817087526 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())