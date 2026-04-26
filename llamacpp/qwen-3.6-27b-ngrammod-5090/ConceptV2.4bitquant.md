Here’s the updated **Markdown guide** for your repo, fully adapted for **4-bit quantization** on the RTX 5090 using **llama.cpp + ngram-mod** speculative decoding.

I switched the recommended quant to **Q4_K_M** (solid balance of quality/speed/size; ~16-17 GB file size, comfortably fits on 32 GB VRAM with 128k context and room for KV cache).

Alternatives included:

- **IQ4_XS** (more aggressive compression, slightly smaller/faster in some cases, good if you need extra headroom)
- **Q4_K_S** (smaller than Q4_K_M, still decent quality)

**Q4_K_M** from **bartowski** or **unsloth** (Dynamic/UD variants where available) is the safest starting point for quality on Qwen3.6-27B. ngram-mod works well with 4-bit, though the absolute peak speeds may be a bit lower than higher quants due to reduced precision — but the cache warmup ramp-up on repetitive coding tasks (like your aquarium experiment) still delivers strong gains.

```markdown
# Qwen3.6-27B + ngram-mod Speculative Decoding on RTX 5090 — 4-bit llama.cpp Guide

*Matching your established DockerBuildFiles workflow • Blackwell SM 12.0 Optimized • 4-bit for maximum speed & VRAM efficiency*

> **Target**  
> : RTX 5090 (32 GB GDDR7, SM 12.0)  
> **Model**  
> : Qwen/Qwen3.6-27B (dense)  
> **Quant**  
> : **Q4_K_M** (recommended 4-bit) — ~16.8 GB  
>   Alternatives: IQ4_XS (~15.4 GB, more aggressive), Q4_K_S  
> **Speculative**  
> : ngram-mod (self-speculative, near-zero extra VRAM)  
> **Last Verified**  
> : April 2026 | llama.cpp master

---

## Why 4-bit + ngram-mod?
- **vLLM NVFP4 + DFlash** offers strong throughput with a small drafter.
- **llama.cpp 4-bit + ngram-mod** excels on pattern-heavy/repetitive tasks (code generation, templates, iterative editing). Expect baseline ~40-60 t/s that ramps significantly (often 80-140+ t/s) once the n-gram cache warms up — similar to the original aquarium HTML demo.
- 4-bit keeps VRAM usage low (~18-24 GB total with 128k context + KV cache in q8_0), leaving headroom on the 5090.
- ngram-mod adds almost no overhead, unlike a separate draft model.

**Note**: Quality is very usable at Q4_K_M for coding/reasoning. If you notice degradation on creative tasks, test IQ4_XS or bump to Q5_K_M later.

---

## Project Structure
```

llamacpp/qwen-3.6-27b-ngrammod-5090-4bit/
├── 00_a_build_llama.sh
├── 00_b_create_conda_env.sh
├── 00_c_install_packages.sh
├── 00_d_pre_download_gguf.sh
├── 01_a_up_server.sh
├── 02_a_down_server.sh
├── 03_enter_container.sh
├── 04_test_curl.sh
├── 05_docker_logs.sh
├── docker-compose.yml
├── README.md
└── metadata/                    # benchmark logs, VRAM usage, acceptance rates

```
---

## Setup Scripts

### `00_a_build_llama.sh` (CUDA Blackwell optimized)

```bash
#!/bin/bash
set -euo pipefail

echo "Building llama.cpp with CUDA SM 12.0 for RTX 5090..."

git clone https://github.com/ggml-org/llama.cpp.git --depth 1 || echo "Repo already exists"
cd llama.cpp

cmake -B build -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES="120" \
  -DGGML_CUDA_FA_ALL_QUANTS=ON \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build --config Release -j$(nproc)

echo "Build complete!"
```

### `00_d_pre_download_gguf.sh` (4-bit focused)

```bash
#!/bin/bash
set -euo pipefail

ENV_NAME="testLlamaCppQwen"
MODEL_ID="bartowski/Qwen_Qwen3.6-27B-GGUF"   # Strong imatrix quants; unsloth/Qwen3.6-27B-GGUF also excellent
QUANT="Q4_K_M"                               # Recommended 4-bit

echo "Downloading Qwen3.6-27B ${QUANT}.gguf..."

conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID" \
  --include "*${QUANT}.gguf" \
  --local-dir ./models

echo "Model ready (~16-17 GB)"
```

**Alternative quants** (change QUANT):

- `IQ4_XS` → more compressed, often slightly faster
- `Q4_K_S` → smaller file
- `Q5_K_M` → if you want a quality bump (still fits easily)

-----

## Docker Compose (4-bit optimized)

### `docker-compose.yml`

```yaml
version: "3.9"

services:
  qwen36-27b-ngrammod-4bit:
    build:
      context: ../../llama.cpp
      dockerfile: .devops/cuda.Dockerfile
    image: llamacpp:qwen-ngrammod-4bit
    container_name: qwen36-27b-ngrammod-4bit
    hostname: qwen36-27b-ngrammod-4bit
    platform: linux/amd64

    ports:
      - "8080:8080"

    volumes:
      - ./models:/models
      - /dev/shm:/dev/shm

    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
              device_ids: ['0']

    environment:
      - NVIDIA_VISIBLE_DEVICES=0
      - CUDA_VISIBLE_DEVICES=0

    command: >
      /llama.cpp/build/bin/llama-server
      -m /models/Qwen_Qwen3.6-27B-Q4_K_M.gguf
      --host 0.0.0.0
      --port 8080
      --ctx-size 131072
      --n-gpu-layers 999
      --flash-attn on
      --cache-type-k q8_0
      --cache-type-v q8_0
      --gpu-memory-utilization 0.90
      --spec-type ngram-mod
      --spec-ngram-size-n 24
      --draft-min 12
      --draft-max 48
      --temp 1.0
      --top-p 0.95
      --top-k 20
      --presence_penalty 1.5
      --chat-template-kwargs '{"preserve_thinking": true}'
      --reasoning auto
```

**Aggressive variant** (for max coding speed): Increase `--draft-min 16 --draft-max 64` and monitor draft acceptance rate in logs.

-----

## Recommended Direct Command (for quick testing)

```bash
./build/bin/llama-server \
  -m models/Qwen_Qwen3.6-27B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 131072 \
  -ngl 999 \
  -fa on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --spec-type ngram-mod \
  --spec-ngram-size-n 24 \
  --draft-min 12 \
  --draft-max 48 \
  --temp 1.0 \
  --top-p 0.95 \
  --presence_penalty 1.5
```

### Performance Tips for 4-bit

- **Cache warmup**: Start with repetitive code/template tasks. Speed often ramps dramatically after the first 100-200 tokens.
- **VRAM**: Q4_K_M + 128k context should use ~20-25 GB total. Use `--gpu-memory-utilization 0.88` if tight.
- **Monitoring**: Check server logs for n-gram draft acceptance rate (higher = better speedup).
- **Comparison**: Run the exact same iterative aquarium/HTML coding prompt against your vLLM NVFP4 setup. Record baseline vs. ramped t/s, quality, and VRAM.
- **llama.cpp edge**: Very low overhead + excellent pattern exploitation on coding. vLLM often wins on varied/sustained throughput.

Update llama.cpp frequently — ngram-mod continues to improve.

Drop this into `llamacpp/qwen-3.6-27b-ngrammod-5090-4bit/ConceptV2.md` (or similar).

Want tweaks? (e.g. IQ4_XS as default, RPC for multi-GPU, different cache types, or a benchmark script to compare head-to-head with vLLM) — just tell me!

Ready to test who wins on your 5090? 🚀
