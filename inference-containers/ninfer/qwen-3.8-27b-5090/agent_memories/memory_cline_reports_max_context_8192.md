# Agent Memory: Cline Context Window Limit & NInfer Max Context Investigation

> **Date:** 2026-08-25  
> **Environment:** RTX 5090 (32 GB GDDR7), WSL2 Ubuntu, Docker  
> **NInfer Commit:** `feaf4dd0983fdaeb2ba4c06eec6da350e644fb3a` (upstream master)  
> **Model:** Qwen 3.8-27B NVFP4 (`qwen3_8_27b_nvfp4.ninfer`, 20.02 GiB)  

---

## 1. Problem Statement

When using Cline with the local NInfer OpenAI-compatible endpoint (`http://localhost:8000/v1`), Cline failed during prompt submission with the following error:

```text
prepared prompt has 13340 tokens, exceeding Engine max_context 8192
```

Even though the server log during startup indicated:
```text
KV capacity auto resolved=65536 tokens pages=1024/1024 runtime=5.39 GiB free-after-weights=10.81 GiB free-after-startup=5.22 GiB headroom=1.00 GiB slack=5.42 GiB graphs=0.00 MiB/656.00 MiB
```

---

## 2. Root Cause Analysis in NInfer Source Code

Investigation of the NInfer engine codebase cloned at `/home/nuno/dev/github_third_party/ninfer` (commit `feaf4dd0983fdaeb2ba4c06eec6da350e644fb3a`) revealed the hard default:

### A. Default Server Options (`src/serve/serve_options.h`)
```cpp
struct ServeOptions {
    bool help_requested = false;
    std::string artifact_path;
    std::string host = "127.0.0.1";
    int port         = 8080;
    std::string api_key;                          // empty => no auth
    std::optional<std::string> model_id_override; // unset => artifact identity.model_id
    std::string request_log_jsonl;                // empty => structured request logging disabled
    std::uint32_t max_context              = 8192; // <--- HARD DEFAULT LIMIT
    KvCapacityPolicy kv_capacity           = KvCapacityPolicy::explicit_capacity(8192);
    std::uint32_t max_concurrency          = 1;
    ...
```

### B. Prompt Validation Check (`src/runtime/engine/engine.cpp`)
When a prompt is submitted via `/v1/chat/completions`, the engine validates the prompt token length against `target_ptr->capacity`:
```cpp
PreparedPrompt Engine::prepare(PromptInput input, const PreparationControl& control) const {
    ...
    if (info.prompt_tokens > target_ptr->capacity) {
        throw RequestError(
            RequestErrorKind::ContextLengthExceeded,
            context_capacity_error(info.prompt_tokens, target_ptr->capacity));
    }
```
If `--max-context` is not explicitly set in the command line / compose arguments, `target_ptr->capacity` is capped at the default `8192` tokens regardless of the global KV cache pool size.

---

## 3. Initial Docker Compose Configuration (Benchmark Preset)

File: `inference-containers/ninfer/qwen-3.8-27b-5090/nvfp4/docker-compose.yml`

```yaml
services:
  qwen-38-27b-ninfer-server:
    # NInfer C++/CUDA Blackwell-optimized inference server
    image: ninfer:latest
    container_name: qwen-3.8-27b-ninfer-5090
    hostname: inference-server
    platform: linux/amd64
    ports:
      - "${INFERENCE_SERVER_PORT:-8000}:8000"

    volumes:
      - ./models:/models:ro
      - /dev/shm:/dev/shm

    shm_size: "32g"
    ipc: host

    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8000/v1/models"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 120s

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      - CUDA_VISIBLE_DEVICES=0
      - NVIDIA_VISIBLE_DEVICES=0

    command:
      - "ninfer-serve"
      - "/models/qwen3_8_27b_nvfp4.ninfer"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      - "--model-id"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.8-27b}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--spec"
      - "mtp"
      - "--draft-tokens"
      - "3"
      - "--kv-dtype"
      - "int8"
      - "--kv-capacity"
      - "auto"
      - "--max-concurrency"
      - "8"
      - "--prefill-chunk"
      - "1024"
      - "--temperature"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "20"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

---

## 4. Key Learnings & Strategy for Next Experiment

1. **Explicit `--max-context` is required**: When serving coding agents like Cline (which regularly exceed 10k–50k tokens), `--max-context <N>` must be explicitly passed.
2. **Concurrency Trade-off**: High concurrency (`--max-concurrency 8`) pre-allocates multiple GDN state slots and CUDA graph arenas, consuming VRAM that could otherwise be used for longer single-session context.
3. **Single Session Coding Preset**: For Cline, setting `--max-concurrency 1` minimizes recurrent state memory overhead, allowing maximum KV cache allocation for large context (testing 120k+).
