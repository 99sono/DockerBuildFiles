#  docker compose
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:latest
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
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true


# vllm crash
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299] 
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.0
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:51:55.782 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:299] 
2026-04-19 12:51:55.785 | (APIServer pid=1) INFO 04-19 10:51:55 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'enable_chunked_prefill': True, 'moe_backend': 'flashinfer_cutlass'}
2026-04-19 12:51:56.335 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:51:56.335 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:51:56.335 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:51:56.335 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:51:56.335 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:51:56.335 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:51:56.335 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:51:56.336 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:51:56.336 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:51:56.336 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:51:56.336 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:51:56.336 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:51:56.339 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:51:56.339 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.339 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:51:56.339 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:51:56.339 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.339 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:51:56.340 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:51:56.340 | (APIServer pid=1)     return await main
2026-04-19 12:51:56.340 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:51:56.340 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 670, in run_server
2026-04-19 12:51:56.340 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:51:56.340 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 684, in run_server_worker
2026-04-19 12:51:56.340 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:51:56.340 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.340 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:51:56.341 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:51:56.341 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.341 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:51:56.341 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:51:56.341 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.341 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:51:56.341 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:51:56.341 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.341 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 124, in build_async_engine_client_from_engine_args
2026-04-19 12:51:56.341 | (APIServer pid=1)     vllm_config = engine_args.create_engine_config(usage_context=usage_context)
2026-04-19 12:51:56.341 | (APIServer pid=1)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.341 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/engine/arg_utils.py", line 1549, in create_engine_config
2026-04-19 12:51:56.341 | (APIServer pid=1)     model_config = self.create_model_config()
2026-04-19 12:51:56.341 | (APIServer pid=1)                    ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:51:56.341 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/engine/arg_utils.py", line 1398, in create_model_config
2026-04-19 12:51:56.342 | (APIServer pid=1)     return ModelConfig(
2026-04-19 12:51:56.342 | (APIServer pid=1)            ^^^^^^^^^^^^
2026-04-19 12:51:56.342 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/pydantic/_internal/_dataclasses.py", line 121, in __init__
2026-04-19 12:51:56.342 | (APIServer pid=1)     s.__pydantic_validator__.validate_python(ArgsKwargs(args, kwargs), self_instance=s)
2026-04-19 12:51:56.342 | (APIServer pid=1) pydantic_core._pydantic_core.ValidationError: 1 validation error for ModelConfig
2026-04-19 12:51:56.342 | (APIServer pid=1)   Value error, The checkpoint you are trying to load has model type `gemma4` but Transformers does not recognize this architecture. This could be because of an issue with the checkpoint, or because your version of Transformers is out of date.
2026-04-19 12:51:56.342 | (APIServer pid=1) 
2026-04-19 12:51:56.342 | (APIServer pid=1) You can update Transformers with the command `pip install --upgrade transformers`. If this does not work, and the checkpoint is very new, then there may not be a release version that supports this model yet. In this case, you can get the most up-to-date code by installing Transformers from source with the command `pip install git+https://github.com/huggingface/transformers.git` [type=value_error, input_value=ArgsKwargs((), {'model': ...nderer_num_workers': 1}), input_type=ArgsKwargs]
2026-04-19 12:51:56.342 | (APIServer pid=1)     For further information visit https://errors.pydantic.dev/2.12/v/value_error