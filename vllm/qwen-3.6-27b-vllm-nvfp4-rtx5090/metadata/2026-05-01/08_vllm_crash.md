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
      # 1. FORCE DISABLE ALL JIT TUNING
      # This is the only way to stop that crash-prone 'Autotuning process starts' 
      VLLM_FLASHINFER_CHECK_SAFE_OPS: "0"
      FLASHINFER_AUTOTUNE: "0"
      VLLM_NO_USAGE_STATS: "1"
      
      # 2. WSL2 + BLACKWELL MULTIPROCESSING
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"

    command:
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 3. CONSERVATIVE MEMORY FOR INITIAL BOOT
      # Leaving more room for Windows background tasks
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "32768" # Reduced to 32k just to get a "Success" first.

      - "--kv-cache-dtype"
      - "fp8"

      # 4. FIX: Use 'marlin' or 'triton' instead of 'cutlass'
      # Blackwell TMA descriptors are failing in your WSL2 env. 
      # Triton kernels don't use TMA descriptors, avoiding the SM120 error.
      - "--quantization"
      - "compressed-tensors"
      - "--moe-backend"
      - "triton" 

      # 5. FIX: Disable speculative decoding for the very first run
      # Once we see the main model load, we will re-enable MTP.
      # - "--speculative-config"
      # - '{"method":"mtp","num_speculative_tokens":1}'

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "qwen3"
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log

2026-05-01 18:57:07.588 | WARNING 05-01 16:57:07 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299] 
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299]   █▄█▀ █     █     █     █  model   sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 18:57:07.689 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:299] 
2026-05-01 18:57:07.692 | (APIServer pid=1) INFO 05-01 16:57:07 [utils.py:233] non-default args: {'model_tag': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'host': '0.0.0.0', 'model': 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP', 'trust_remote_code': True, 'max_model_len': 32768, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['qwen3.6-27b-text-nvfp4-mtp'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-05-01 18:57:07.693 | (APIServer pid=1) WARNING 05-01 16:57:07 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 18:57:07.850 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 18:57:17.929 | (APIServer pid=1) INFO 05-01 16:57:17 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 18:57:17.960 | (APIServer pid=1) INFO 05-01 16:57:17 [nixl_utils.py:32] NIXL is available
2026-05-01 18:57:18.194 | (APIServer pid=1) INFO 05-01 16:57:18 [model.py:555] Resolved architecture: Qwen3_5ForConditionalGeneration
2026-05-01 18:57:18.195 | (APIServer pid=1) INFO 05-01 16:57:18 [model.py:1680] Using max model len 32768
2026-05-01 18:57:18.576 | (APIServer pid=1) INFO 05-01 16:57:18 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 18:57:18.576 | (APIServer pid=1) WARNING 05-01 16:57:18 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
2026-05-01 18:57:18.576 | (APIServer pid=1) INFO 05-01 16:57:18 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 18:57:18.577 | (APIServer pid=1) WARNING 05-01 16:57:18 [modelopt.py:1014] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.
2026-05-01 18:57:18.577 | (APIServer pid=1) INFO 05-01 16:57:18 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 18:57:18.577 | (APIServer pid=1) WARNING 05-01 16:57:18 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 18:57:18.577 | (APIServer pid=1) WARNING 05-01 16:57:18 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 18:57:18.577 | (APIServer pid=1) INFO 05-01 16:57:18 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 18:57:18.577 | (APIServer pid=1) INFO 05-01 16:57:18 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 18:57:21.300 | (APIServer pid=1) INFO 05-01 16:57:21 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 18:57:21.476 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 18:57:24.904 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 18:57:24.904 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 18:57:24.904 | (APIServer pid=1)     sys.exit(main())
2026-05-01 18:57:24.904 | (APIServer pid=1)              ^^^^^^
2026-05-01 18:57:24.904 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 18:57:24.904 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 18:57:24.904 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 18:57:24.904 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 18:57:24.905 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 18:57:24.905 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 18:57:24.905 | (APIServer pid=1)     return runner.run(main)
2026-05-01 18:57:24.905 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 18:57:24.905 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 18:57:24.905 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 18:57:24.905 | (APIServer pid=1)     return await main
2026-05-01 18:57:24.905 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 18:57:24.905 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 18:57:24.906 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 18:57:24.906 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 18:57:24.906 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 18:57:24.906 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:57:24.906 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:57:24.906 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.906 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 18:57:24.906 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 18:57:24.906 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 18:57:24.906 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 18:57:24.906 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.906 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 18:57:24.907 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 18:57:24.907 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 18:57:24.907 | (APIServer pid=1)     return cls(
2026-05-01 18:57:24.907 | (APIServer pid=1)            ^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 135, in __init__
2026-05-01 18:57:24.907 | (APIServer pid=1)     self.input_processor = InputProcessor(self.vllm_config, renderer)
2026-05-01 18:57:24.907 | (APIServer pid=1)                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/input_processor.py", line 61, in __init__
2026-05-01 18:57:24.907 | (APIServer pid=1)     mm_budget = MultiModalBudget(vllm_config, mm_registry)
2026-05-01 18:57:24.907 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/encoder_budget.py", line 87, in __init__
2026-05-01 18:57:24.907 | (APIServer pid=1)     all_mm_max_toks_per_item = get_mm_max_toks_per_item(
2026-05-01 18:57:24.907 | (APIServer pid=1)                                ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/encoder_budget.py", line 25, in get_mm_max_toks_per_item
2026-05-01 18:57:24.907 | (APIServer pid=1)     max_tokens_per_item = processor.info.get_mm_max_tokens_per_item(
2026-05-01 18:57:24.907 | (APIServer pid=1)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.907 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_vl.py", line 825, in get_mm_max_tokens_per_item
2026-05-01 18:57:24.908 | (APIServer pid=1)     max_image_tokens = self.get_max_image_tokens()
2026-05-01 18:57:24.908 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.908 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_vl.py", line 968, in get_max_image_tokens
2026-05-01 18:57:24.908 | (APIServer pid=1)     image_processor = self.get_image_processor()
2026-05-01 18:57:24.908 | (APIServer pid=1)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.908 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_vl.py", line 866, in get_image_processor
2026-05-01 18:57:24.908 | (APIServer pid=1)     return self.get_hf_processor(**kwargs).image_processor
2026-05-01 18:57:24.908 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.908 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_vl.py", line 859, in get_hf_processor
2026-05-01 18:57:24.908 | (APIServer pid=1)     return self.ctx.get_hf_processor(
2026-05-01 18:57:24.908 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.908 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/processing/context.py", line 204, in get_hf_processor
2026-05-01 18:57:24.909 | (APIServer pid=1)     return cached_processor_from_config(
2026-05-01 18:57:24.909 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.909 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 355, in cached_processor_from_config
2026-05-01 18:57:24.909 | (APIServer pid=1)     return cached_get_processor_without_dynamic_kwargs(
2026-05-01 18:57:24.909 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.909 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 312, in cached_get_processor_without_dynamic_kwargs
2026-05-01 18:57:24.909 | (APIServer pid=1)     processor = cached_get_processor(
2026-05-01 18:57:24.909 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.909 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 198, in get_processor
2026-05-01 18:57:24.909 | (APIServer pid=1)     processor = processor_cls.from_pretrained(
2026-05-01 18:57:24.909 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.909 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/processing_utils.py", line 1429, in from_pretrained
2026-05-01 18:57:24.910 | (APIServer pid=1)     args = cls._get_arguments_from_pretrained(pretrained_model_name_or_path, processor_dict, **kwargs)
2026-05-01 18:57:24.910 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.910 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/processing_utils.py", line 1558, in _get_arguments_from_pretrained
2026-05-01 18:57:24.910 | (APIServer pid=1)     sub_processor = auto_processor_class.from_pretrained(
2026-05-01 18:57:24.910 | (APIServer pid=1)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.910 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/models/auto/image_processing_auto.py", line 569, in from_pretrained
2026-05-01 18:57:24.910 | (APIServer pid=1)     raise initial_exception
2026-05-01 18:57:24.910 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/models/auto/image_processing_auto.py", line 556, in from_pretrained
2026-05-01 18:57:24.910 | (APIServer pid=1)     config_dict, _ = ImageProcessingMixin.get_image_processor_dict(
2026-05-01 18:57:24.910 | (APIServer pid=1)                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 18:57:24.910 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/image_processing_base.py", line 334, in get_image_processor_dict
2026-05-01 18:57:24.911 | (APIServer pid=1)     raise OSError(
2026-05-01 18:57:24.911 | (APIServer pid=1) OSError: Can't load image processor for 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP'. If you were trying to load it from 'https://huggingface.co/models', make sure you don't have a local directory with the same name. Otherwise, make sure 'sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP' is the correct path to a directory containing a preprocessor_config.json file