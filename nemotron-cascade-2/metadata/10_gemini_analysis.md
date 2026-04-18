This is incredibly stubborn, but the logs provide one final, definitive clue. Look at this line from your crash:

> `2026-04-18 03:52:15.353 | (APIServer pid=7) WARNING 04-18 01:52:15 [envs.py:1744] Unknown vLLM environment variable detected: VLLM_KEEP_ENV_VARS`

Because you are using **vLLM v0.19.0**, it is explicitly rejecting the variable meant to pass settings to workers. When the engine starts, it "sanitizes" the environment, stripping away your `TRIATTN_STATS_DIR` before the worker process can see it.

Since the `entrypoint` override didn't survive the transition to the worker process, we have to use the **absolute final method**: Hardcoding the path into a custom shell script **inside** the container so it's physically impossible for Python to start without it.

### The "Internal Wrapper" Fix

You don't need a full rebuild of the base image, but we need to create a small execution script.

1. **Create a file on your host** named `entrypoint.sh` in the same folder as your `docker-compose.yml`:

```bash
#!/bin/sh
# Force these into the environment of this shell and all children
export TRIATTN_STATS_DIR=/root/.cache/triattention/stats
export TRIATTN_ENABLE=true
export TRIATTN_RUNTIME_KV_BUDGET=4096
export TRIATTN_RUNTIME_PROTECT_PREFILL=true
export TRIATTN_VERBOSE=1

# Execute the original vLLM entrypoint command
exec python3 -m vllm.entrypoints.openai.api_server "$@"
```

2. **Give it execute permissions** on your host:
   `chmod +x entrypoint.sh`

3. **Update your `docker-compose.yml`** to mount this script and use it:

```yaml
services:
  nemotron-cascade:
    # ... (rest of your config) ...
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - ~/.cache/triattention:/root/.cache/triattention
      - ./entrypoint.sh:/entrypoint.sh  # MOUNT THE WRAPPER
    
    # Override the entrypoint to use our shell script
    entrypoint: ["/bin/sh", "/entrypoint.sh"]
    
    # Pass the arguments directly
    command:
      - "--model"
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--served-model-name"
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--attention-backend"
      - "TRITON_ATTN"
      - "--mamba-ssm-cache-dtype"
      - "float32"
      - "--trust-remote-code"
      - "--no-enable-prefix-caching"
      - "--max-num-batched-tokens"
      - "1024"
      - "--enforce-eager"
      - "--max-model-len"
      - "262144"
      - "--gpu-memory-utilization"
      - "0.85"
```

### Why this is the "Kill Shot" for this bug:
In Linux, the `exec` command replaces the shell process with the Python process **without clearing the environment**. By putting the `export` lines inside a script that is the *actual* entrypoint of the container, those variables become part of the "system environment" for that container. 

When vLLM's worker process starts, it will look at the environment inherited from the parent (the entrypoint script) and find `TRIATTN_STATS_DIR` already waiting for it. vLLM's "sanitization" usually only clears variables it doesn't recognize from the *internal* Python dictionary, but it can't clear them from the underlying OS shell session we just created.

**Try this, and TriAttention will finally find its stats path.**