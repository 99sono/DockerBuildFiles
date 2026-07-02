# Qwen3.6-27B-NVFP4 — Second Startup Log (MTP, num_speculative_tokens=2)

## docker-compose.yml

```yaml
services:
  qwen36-27b-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen36-27b-nvfp4-nightly
    hostname: inference-server
    platform: linux/arm64
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
      HF_XET_HIGH_PERFORMANCE: "1"
      VLLM_USE_RUST_FRONTEND: "0"
    command:
      - "--model"
      - "nvidia/Qwen3.6-27B-NVFP4"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-27b}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      - "--gpu-memory-utilization"
      - "0.70"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "8"
      - "--max-num-batched-tokens"
      - "65536"
      - "--kv-cache-dtype"
      - "fp8"
      - "--dtype"
      - "auto"
      - "--quantization"
      - "modelopt"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--enable-auto-tool-choice"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"
      - "--safetensors-load-strategy"
      - "prefetch"
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":2}'
    networks:
      - development-network
networks:
  development-network:
    external: true
```

## Docker logs

```
WARNING 07-02 21:58:11 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339] 
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339]        █     █     █▄   ▄█
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.23.1rc1.dev531+ga65f93fb2
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339]   █▄█▀ █     █     █     █  model   nvidia/Qwen3.6-27B-NVFP4
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:339] 
(APIServer pid=1) INFO 07-02 21:58:11 [api_utils.py:273] non-default args: {'model_tag': 'nvidia/Qwen3.6-27B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['__REDACTED__'], 'model': 'nvidia/Qwen3.6-27B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'modelopt', 'served_model_name': ['qwen3.6-27b'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.7, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 65536, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'async_scheduling': True, 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 2}}
(APIServer pid=1) WARNING 07-02 21:58:11 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
(APIServer pid=1) WARNING 07-02 21:58:11 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
(APIServer pid=1) WARNING 07-02 21:58:11 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_URL
(APIServer pid=1) WARNING 07-02 21:58:11 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
(APIServer pid=1) INFO 07-02 21:58:20 [model.py:601] Resolved architecture: Qwen3_5ForConditionalGeneration
(APIServer pid=1) INFO 07-02 21:58:20 [model.py:1727] Using max model len 262144
(APIServer pid=1) INFO 07-02 21:58:20 [cache.py:280] Using fp8 data type to store kv cache.
(APIServer pid=1) INFO 07-02 21:58:25 [model.py:601] Resolved architecture: Qwen3_5MTP
(APIServer pid=1) INFO 07-02 21:58:25 [model.py:1727] Using max model len 262144
(APIServer pid=1) WARNING 07-02 21:58:25 [speculative.py:761] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer
(APIServer pid=1) INFO 07-02 21:58:25 [scheduler.py:252] Chunked prefill is enabled with max_num_batched_tokens=65536.
(APIServer pid=1) WARNING 07-02 21:58:25 [config.py:422] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 07-02 21:58:25 [config.py:442] Warning: Prefix caching in Mamba cache 'align' mode is currently experimental.
(APIServer pid=1) WARNING 07-02 21:58:25 [modelopt.py:384] Detected ModelOpt fp8 checkpoint (quant_algo=FP8).
(APIServer pid=1) WARNING 07-02 21:58:25 [modelopt.py:1028] Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4).
(APIServer pid=1) WARNING 07-02 21:58:25 [modelopt.py:1028] Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4).
(APIServer pid=1) INFO 07-02 21:58:25 [vllm.py:1006] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 07-02 21:58:25 [kernel.py:278] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=182) INFO 07-02 21:58:42 [core.py:114] Initializing a V1 LLM engine (v0.23.1rc1.dev531+ga65f93fb2) with config: speculative_config=SpeculativeConfig(method='mtp', model='nvidia/Qwen3.6-27B-NVFP4', num_spec_tokens=2), ...
(EngineCore pid=182) INFO 07-02 21:58:44 [parallel_state.py:1588] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:60301 backend=nccl
(EngineCore pid=182) INFO 07-02 21:58:44 [topk_topp_sampler.py:55] Using FlashInfer for top-p & top-k sampling.
(EngineCore pid=182) WARNING 07-02 21:58:44 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=182) INFO 07-02 21:58:53 [gpu_model_runner.py:5160] Starting to load model nvidia/Qwen3.6-27B-NVFP4...
(EngineCore pid=182) INFO 07-02 21:58:53 [cuda.py:542] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=182) INFO 07-02 21:58:53 [__init__.py:594] Selected FlashInferFP8ScaledMMLinearKernel for ModelOptFp8LinearMethod
(EngineCore pid=182) INFO 07-02 21:58:53 [deep_gemm.py:175] deep_gemm not found in site-packages, trying vendored vllm.third_party.deep_gemm
(EngineCore pid=182) INFO 07-02 21:58:53 [deep_gemm.py:202] DeepGEMM PDL enabled on vllm.third_party.deep_gemm.
(EngineCore pid=182) INFO 07-02 21:58:53 [deep_gemm.py:120] DeepGEMM E8M0 enabled on current platform.
(EngineCore pid=182) INFO 07-02 21:58:53 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel.
(EngineCore pid=182) INFO 07-02 21:58:54 [cuda.py:483] Using FLASHINFER attention backend.
(EngineCore pid=182) INFO 07-02 21:58:55 [weight_utils.py:849] Filesystem type for checkpoints: EXT4. Checkpoint size: 20.42 GiB. Available RAM: 86.36 GiB.
(EngineCore pid=182) INFO 07-02 21:58:55 [weight_utils.py:811] Prefetching checkpoint files into page cache started (background, num_threads=8)
(EngineCore pid=182) INFO 07-02 21:58:56 [weight_utils.py:783] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=182) INFO 07-02 21:58:56 [weight_utils.py:783] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=182) INFO 07-02 21:58:56 [weight_utils.py:783] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=182) INFO 07-02 21:58:56 [weight_utils.py:806] Prefetching checkpoint files into page cache finished in 1.08s
(EngineCore pid=182) INFO 07-02 22:00:59 [default_loader.py:430] Loading weights took 123.52 seconds
(EngineCore pid=182) WARNING 07-02 22:00:59 [marlin.py:34] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Marlin kernel fallback.
(EngineCore pid=182) WARNING 07-02 22:00:59 [kv_cache.py:134] Checkpoint does not provide a q scaling factor.
(EngineCore pid=182) WARNING 07-02 22:00:59 [kv_cache.py:148] Using KV cache scaling factor 1.0 for fp8_e4m3.
(EngineCore pid=182) INFO 07-02 22:01:01 [gpu_model_runner.py:5184] Loading drafter model...
(EngineCore pid=182) INFO 07-02 22:01:01 [weight_utils.py:849] Filesystem type for checkpoints: EXT4. Checkpoint size: 20.42 GiB. Available RAM: 67.81 GiB.
(EngineCore pid=182) INFO 07-02 22:01:03 [weight_utils.py:806] Prefetching checkpoint files into page cache finished in 1.33s
(EngineCore pid=182) INFO 07-02 22:01:13 [default_loader.py:430] Loading weights took 11.22 seconds
(EngineCore pid=182) INFO 07-02 22:01:13 [llm_base_proposer.py:1395] Detected MTP model. Sharing target model embedding weights with the draft model.
(EngineCore pid=182) INFO 07-02 22:01:13 [llm_base_proposer.py:1451] Detected MTP model. Sharing target model lm_head weights with the draft model.
(EngineCore pid=182) INFO 07-02 22:01:13 [gpu_model_runner.py:5255] Model loading took 20.57 GiB memory and 139.645153 seconds
(EngineCore pid=182) INFO 07-02 22:01:13 [interface.py:773] Setting attention block size to 1600 tokens.
(EngineCore pid=182) INFO 07-02 22:01:14 [gpu_model_runner.py:6271] Encoder cache initialized with budget of 65536 tokens.
(EngineCore pid=182) INFO 07-02 22:01:33 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/432ab28852/rank_0_0/backbone
(EngineCore pid=182) INFO 07-02 22:01:33 [backends.py:1148] Dynamo bytecode transform time: 11.01 s
(EngineCore pid=182) INFO 07-02 22:02:03 [backends.py:378] Cache the graph of compile range (1, 65536) for later use
(EngineCore pid=182) INFO 07-02 22:02:28 [backends.py:393] Compiling a graph for compile range (1, 65536) takes 54.99 s
(EngineCore pid=182) INFO 07-02 22:02:33 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/...
(EngineCore pid=182) INFO 07-02 22:02:33 [monitor.py:53] torch.compile took 70.93 s in total
(EngineCore pid=182) INFO 07-02 22:04:32 [monitor.py:81] Initial profiling/warmup run took 119.30 s
(EngineCore pid=182) INFO 07-02 22:04:32 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/432ab28852/rank_0_0/eagle_head
(EngineCore pid=182) INFO 07-02 22:04:32 [backends.py:1148] Dynamo bytecode transform time: 0.33 s
(EngineCore pid=182) INFO 07-02 22:04:44 [backends.py:393] Compiling a graph for compile range (1, 65536) takes 11.26 s
(EngineCore pid=182) INFO 07-02 22:04:44 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/...
(EngineCore pid=182) INFO 07-02 22:04:44 [monitor.py:53] torch.compile took 11.71 s in total
(EngineCore pid=182) INFO 07-02 22:04:48 [monitor.py:81] Initial profiling/warmup run took 3.79 s
(EngineCore pid=182) WARNING 07-02 22:04:53 [kv_cache_utils.py:1208] Add 3 padding layers, may waste at most 6.25% KV cache memory
(EngineCore pid=182) WARNING 07-02 22:04:53 [compilation.py:1405] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for FlashInferBackend; setting cudagraph_mode=PIECEWISE
(EngineCore pid=182) INFO 07-02 22:04:53 [gpu_model_runner.py:6483] Profiling CUDA graph memory: PIECEWISE=9 (largest=48)
(EngineCore pid=182) INFO 07-02 22:04:54 [gpu_model_runner.py:6588] Estimated CUDA graph memory: -0.81 GiB total
(EngineCore pid=182) INFO 07-02 22:04:55 [gpu_worker.py:515] Available KV cache memory: 48.6 GiB
(EngineCore pid=182) WARNING 07-02 22:04:55 [kv_cache_utils.py:1208] Add 3 padding layers, may waste at most 6.25% KV cache memory
(EngineCore pid=182) INFO 07-02 22:04:55 [kv_cache_utils.py:2146] GPU KV cache size: 1,394,129 tokens
(EngineCore pid=182) INFO 07-02 22:04:55 [kv_cache_utils.py:2147] Maximum concurrency for 262,144 tokens per request: 5.32x
(EngineCore pid=182) INFO 07-02 22:10:09 [gpu_model_runner.py:6656] Graph capturing finished in 4 secs, took 0.23 GiB
(EngineCore pid=182) INFO 07-02 22:10:09 [jit_monitor.py:71] Kernel JIT monitor activated.
(EngineCore pid=182) INFO 07-02 22:10:09 [core.py:337] init engine (profile, create kv cache, warmup model) took 535.77 s
(EngineCore pid=182) INFO 07-02 22:10:09 [kernel.py:278] Final IR op priority after setting platform defaults: IrOpPriorityConfig...
(APIServer pid=1) INFO 07-02 22:10:10 [api_server.py:619] Supported tasks: ['generate']
(APIServer pid=1) INFO 07-02 22:10:10 [parser_manager.py:37] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 07-02 22:10:10 [model.py:1479] Default vLLM sampling parameters overridden by model's generation_config.json: {'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}.
(APIServer pid=1) INFO 07-02 22:10:14 [hf.py:548] Detected the chat template content format to be 'openai'.
(APIServer pid=1) INFO 07-02 22:10:27 [base.py:236] Multi-modal warmup completed in 13.189s
(APIServer pid=1) INFO 07-02 22:10:28 [base.py:236] Readonly multi-modal warmup completed in 0.909s
(APIServer pid=1) INFO 07-02 22:10:29 [api_server.py:623] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 07-02 22:10:29 [launcher.py:37] Available routes are: ...
(APIServer pid=1) INFO:     172.18.0.3:46876 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:57410 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-02 22:11:19 [loggers.py:273] Engine 000: Avg prompt throughput: 2.3 tokens/s, Avg generation throughput: 8.1 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:11:19 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 0.75 tokens/s, Drafted throughput: 0.81 tokens/s, Accepted: 52 tokens, Drafted: 56 tokens, Per-position acceptance rate: 0.964, 0.893, Avg Draft acceptance rate: 92.9%
(APIServer pid=1) INFO 07-02 22:11:29 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 20.6 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:11:29 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.42, Accepted throughput: 12.10 tokens/s, Drafted throughput: 17.00 tokens/s, Accepted: 121 tokens, Drafted: 170 tokens, Per-position acceptance rate: 0.765, 0.659, Avg Draft acceptance rate: 71.2%
(APIServer pid=1) INFO 07-02 22:11:39 [loggers.py:273] Engine 000: Avg prompt throughput: 28.9 tokens/s, Avg generation throughput: 22.3 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:11:39 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.56, Accepted throughput: 13.60 tokens/s, Drafted throughput: 17.40 tokens/s, Accepted: 136 tokens, Drafted: 174 tokens, Per-position acceptance rate: 0.862, 0.701, Avg Draft acceptance rate: 78.2%
(APIServer pid=1) INFO 07-02 22:11:49 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 20.9 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:11:49 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.22, Accepted throughput: 11.50 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 115 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.713, 0.511, Avg Draft acceptance rate: 61.2%
(APIServer pid=1) INFO 07-02 22:11:59 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.3 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:11:59 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 13.80 tokens/s, Drafted throughput: 19.00 tokens/s, Accepted: 138 tokens, Drafted: 190 tokens, Per-position acceptance rate: 0.789, 0.663, Avg Draft acceptance rate: 72.6%
(APIServer pid=1) INFO 07-02 22:12:09 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 25.2 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:09 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 15.90 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 159 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.914, 0.796, Avg Draft acceptance rate: 85.5%
(APIServer pid=1) INFO 07-02 22:12:19 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.2 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:19 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 14.00 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 140 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.848, 0.674, Avg Draft acceptance rate: 76.1%
(APIServer pid=1) INFO:     172.18.0.3:57410 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-02 22:12:29 [loggers.py:273] Engine 000: Avg prompt throughput: 36.2 tokens/s, Avg generation throughput: 22.9 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:29 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 14.10 tokens/s, Drafted throughput: 17.80 tokens/s, Accepted: 141 tokens, Drafted: 178 tokens, Per-position acceptance rate: 0.865, 0.719, Avg Draft acceptance rate: 79.2%
(APIServer pid=1) INFO 07-02 22:12:39 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 22.5 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:39 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 13.30 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 133 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.804, 0.641, Avg Draft acceptance rate: 72.3%
(APIServer pid=1) INFO 07-02 22:12:49 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.7 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:49 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 14.50 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 145 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.870, 0.707, Avg Draft acceptance rate: 78.8%
(APIServer pid=1) INFO 07-02 22:12:59 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 22.5 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:12:59 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 13.10 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 131 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.766, 0.628, Avg Draft acceptance rate: 69.7%
(APIServer pid=1) INFO 07-02 22:13:09 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 24.3 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:13:09 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 15.00 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 150 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.882, 0.731, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO:     172.18.0.3:57410 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-02 22:13:19 [loggers.py:273] Engine 000: Avg prompt throughput: 23.5 tokens/s, Avg generation throughput: 24.4 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:13:19 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 15.40 tokens/s, Drafted throughput: 17.80 tokens/s, Accepted: 154 tokens, Drafted: 178 tokens, Per-position acceptance rate: 0.899, 0.831, Avg Draft acceptance rate: 86.5%
(APIServer pid=1) INFO 07-02 22:13:29 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 22.8 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:13:29 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.51, Accepted throughput: 13.70 tokens/s, Drafted throughput: 18.20 tokens/s, Accepted: 137 tokens, Drafted: 182 tokens, Per-position acceptance rate: 0.813, 0.692, Avg Draft acceptance rate: 75.3%
(APIServer pid=1) INFO 07-02 22:13:39 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 24.9 tokens/s, Running: 1 reqs
(APIServer pid=1) INFO 07-02 22:13:39 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 15.70 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 157 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.902, 0.804, Avg Draft acceptance rate: 85.3%
(APIServer pid=1) INFO:     172.18.0.3:57410 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-02 22:13:49 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.9 tokens/s, Running: 0 reqs
(APIServer pid=1) INFO 07-02 22:13:49 [metrics.py:120] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 0.60 tokens/s, Drafted throughput: 0.60 tokens/s, Accepted: 6 tokens, Drafted: 6 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 07-02 22:13:59 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs
```

## Performance summary

| Metric | No MTP (previous) | MTP (num_spec_tokens=2) |
|---|---|---|
| Generation throughput | ~11-12 tok/s | ~20-25 tok/s |
| Init time | 443.17 s | 535.77 s |
| Model memory | 19.78 GiB | 20.57 GiB |
| KV cache | 47.84 GiB | 48.6 GiB |
| KV cache tokens | — | 1,394,129 |
| Max concurrency (262K ctx) | — | 5.32x |
| Mean acceptance length | — | 2.4-2.7 |
| Avg draft acceptance rate | — | ~75-86% |

**vLLM default sampling** (from model's generation_config.json): temperature=1.0, top_k=20, top_p=0.95
