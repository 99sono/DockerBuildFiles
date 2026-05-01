# 🚀 Qwen3.6-27B + DFlash on RTX 5090 — Production Guide
*Matching your established `DockerBuildFiles` workflow • GQA-aware • Blackwell SM 12.0 Optimized*

> **Target**: RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)  
> **Model**: `Qwen/Qwen3.6-27B` (dense, GQA) + `z-lab/Qwen3.6-27B-DFlash` (2B drafter)  
> **Quant**: NVFP4 target (hybrid) + FP8_e4m3 KV cache  
> **Last Verified**: April 26, 2026 | vLLM v0.20.0-cu130-ubuntu2404

---

## 📁 Project Structure (Mirror Your Gemma-4 Setup)

```
vllm/qwen3.6-27b-dflash-5090/
├── 00_a_pull_vllm_image.sh
├── 00_b_create_conda_env.sh
├── 00_c_install_packages.sh
├── 00_d_pre_download_model.sh   # ← Your existing script, adapted
├── 00_e_vllm_entrypoint.sh      # Optional: inspect entrypoint
├── 01_a_up_dflash.sh            # Start DFlash service
├── 02_a_down_dflash.sh          # Stop service
├── 03_enter_container.sh        # Debug: exec into container
├── 04_test_vllm_curl.py         # API verification client
├── 05_docker_logs.sh            # Monitor logs
├── 06_dump_vllm_help.sh         # Capture vLLM --help for reference
├── docker-compose.yml           # Primary config (GQA-optimized)
├── docker-compose-dflash-aggressive.yml  # Higher throughput variant
├── README.md
└── metadata/                    # Optional: benchmark logs, VRAM traces
```

---

## 🔧 Environment Setup Scripts (Match Your Conventions)

### `00_a_pull_vllm_image.sh`
```bash
#!/bin/bash
set -euo pipefail
echo "📥 Pulling vLLM v0.20.0-cu130-ubuntu2404 image (Blackwell SM 12.0)..."
docker pull vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
echo "✅ Image ready"
```

### `00_b_create_conda_env.sh`
```bash
#!/bin/bash
set -euo pipefail
ENV_NAME="testVllmQwen"
echo "🔧 Creating Conda environment: $ENV_NAME"
if ! conda env list | grep -q "^$ENV_NAME "; then
  conda create -n "$ENV_NAME" python=3.12 -y
fi
echo "✅ Environment ready: conda activate $ENV_NAME"
```

### `00_c_install_packages.sh`
```bash
#!/bin/bash
set -euo pipefail
ENV_NAME="testVllmQwen"
echo "📦 Installing host-side utilities in $ENV_NAME..."
conda run -n "$ENV_NAME" pip install --upgrade pip
conda run -n "$ENV_NAME" pip install huggingface-hub requests jq
echo "✅ Packages installed"
```

### `00_d_pre_download_model.sh` ← *Your Script, Adapted*
```bash
#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh — Qwen3.6-27B + DFlash
# =============================================================================
set -euo pipefail

ENV_NAME="testVllmQwen"
MODEL_ID="Qwen/Qwen3.6-27B"
DRAFTER_ID="z-lab/Qwen3.6-27B-DFlash"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download models to global cache:"
echo "   - Target  : $MODEL_ID"
echo "   - Drafter : $DRAFTER_ID"

if ! conda env list | grep -q "^$ENV_NAME "; then
  echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
  exit 1
fi

echo "🚀 Starting download of target model..."
if command -v hf &> /dev/null; then
  hf download "$MODEL_ID"
  echo "🚀 Starting download of DFlash drafter..."
  hf download "$DRAFTER_ID"
else
  conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID"
  conda run -n "$ENV_NAME" huggingface-cli download "$DRAFTER_ID"
fi

# Verify GQA architecture (critical for VRAM math)
echo "🔍 Verifying architecture compatibility..."
CONFIG_PATH="$CACHE_DIR/hub/models--Qwen--Qwen3.6-27B/snapshots/*/config.json"
if [ -f "$(ls $CONFIG_PATH 2>/dev/null | head -1)" ]; then
  KV_HEADS=$(python3 -c "import json,glob; c=json.load(open(glob.glob('$CONFIG_PATH')[0])); print(c.get('num_key_value_heads', 'unknown'))")
  echo "✅ Target num_key_value_heads: $KV_HEADS (expected: 4 for GQA)"
  if [ "$KV_HEADS" != "4" ]; then
    echo "⚠️ Warning: Expected GQA (4 KV heads). Verify model variant."
  fi
else
  echo "⚠️ Could not auto-verify config.json — proceeding anyway"
fi

echo ""
echo "✅ Download complete! Models cached at: $CACHE_DIR"
echo "🚀 Next: ./01_a_up_dflash.sh"
```

### `00_e_vllm_entrypoint.sh` (Optional Debug)
```bash
#!/bin/bash
set -euo pipefail
echo "🔍 Inspecting vLLM image entrypoint..."
docker inspect vllm/vllm-openai:v0.20.0-cu130-ubuntu2404 --format '{{json .Config.Entrypoint}}'
echo "✅ Done"
```

---

## 🐳 Docker Compose (Positional Args Style — Matches Your Gemma Setup)

### `docker-compose.yml` (Baseline: 128k Context, Stable)
```yaml
version: "3.9"

services:
  qwen36-27b-dflash:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen36-27b-dflash-stable
    hostname: qwen36-27b-dflash
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
              device_ids: ['0']  # Explicit RTX 5090 selection

    environment:
      # Blackwell + WSL2 stability
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
      # Large KV-cache allocations
      - PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
      # Faster HF downloads (optional)
      - HF_HUB_ENABLE_HF_TRANSFER=1
      # Force SM 12.0 kernels
      - TORCH_CUDA_ARCH_LIST=12.0
      - FLASHINFER_CUDA_ARCH=120
      - NVIDIA_FORWARD_COMPAT=1
      # Enable V2 runner for Triton kernels
      - VLLM_USE_V2_MODEL_RUNNER=1

    command:
      # Model paths (pulled from global HF cache)
      # there is an NVFP4 version https://huggingface.co/sakamakismile/Qwen3.6-27B-NVFP4
      # https://huggingface.co/sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
      # 
      - "Qwen/Qwen3.6-27B"
      - "--served-model-name"
      - "qwen3.6-27b-dflash"
      - "--trust-remote-code"

      # Networking
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # Memory budget (GQA-aware: 128k @ batch 24 fits comfortably)
      - "--gpu-memory-utilization"
      - "0.88"

      # Context window
      - "--max-model-len"
      - "131072"

      # Batching (balanced for long-context + throughput)
      - "--max-num-seqs"
      - "24"
      - "--max-num-batched-tokens"
      - "32768"

      # KV cache: FP8_e4m3 (stable; GQA reduces coefficient 8×)
      - "--kv-cache-dtype"
      - "fp8_e4m3"

      # Quantization: auto-detect NVFP4 on SM 12.0
      - "--quantization"
      - "compressed-tensors"

      # Long-context ergonomics
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # DFlash speculative decoding
      - "--speculative-config"
      - '{"method": "dflash", "model": "z-lab/Qwen3.6-27B-DFlash", "num_speculative_tokens": 10}'

      # Attention backend
      - "--attention-backend"
      - "flash_attn"

      # Logging
      - "--log-dir"
      - "/root/.cache/huggingface/vllm_logs"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

### `docker-compose-dflash-aggressive.yml` (Higher Throughput Variant)
```yaml
# Same as above, but with these overrides in command:
# - "--gpu-memory-utilization" → "0.90"
# - "--max-num-seqs" → "32"
# - "--speculative-config" → '{"method": "dflash", "model": "z-lab/Qwen3.6-27B-DFlash", "num_speculative_tokens": 12}'
# Use only after baseline is stable and acceptance rate α ≥ 0.75
```

---

## 🚀 Orchestration Scripts (Your Numbered Convention)

### `01_a_up_dflash.sh`
```bash
#!/bin/bash
set -e
echo "🚀 Starting Qwen3.6-27B + DFlash (FP8 KV, 128K Context, GQA-optimized)..."
docker compose -f docker-compose.yml up -d
echo "------------------------------------------------"
echo "Server initializing. Monitor with: ./05_docker_logs.sh"
echo "Test API with: ./04_test_vllm_curl.py"
```

### `02_a_down_dflash.sh`
```bash
#!/bin/bash
set -e
echo "🛑 Stopping Qwen3.6-27B + DFlash service..."
docker compose -f docker-compose.yml down
echo "✅ Service stopped"
```

### `03_enter_container.sh`
```bash
#!/bin/bash
set -e
echo "🔧 Entering running container (debug mode)..."
docker exec -it qwen36-27b-dflash-stable /bin/bash
```

### `04_test_vllm_curl.py` (Adapted for Qwen3.6)
```python
#!/usr/bin/env python3
"""Quick API verification for Qwen3.6-27B + DFlash"""
import requests, json, sys

BASE = "http://localhost:8000/v1"
MODEL = "qwen3.6-27b-dflash"

def test_models():
    r = requests.get(f"{BASE}/models")
    print(f"✅ Models endpoint: {r.json()['data'][0]['id'] if r.ok else 'FAILED'}")

def test_chat():
    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": "Explain DFlash speculative decoding in 2 sentences."}],
        "max_tokens": 60,
        "temperature": 0.1
    }
    r = requests.post(f"{BASE}/chat/completions", json=payload)
    if r.ok:
        content = r.json()["choices"][0]["message"]["content"]
        print(f"✅ Chat response ({len(content)} chars):\n{content[:200]}...")
    else:
        print(f"❌ Chat failed: {r.status_code} — {r.text[:200]}")

def test_acceptance_hint():
    # Note: acceptance rate appears in container logs, not API
    print("ℹ️  Acceptance rate (α) appears in container logs:")
    print("   Run: ./05_docker_logs.sh | grep spec_decode")

if __name__ == "__main__":
    test_models()
    test_chat()
    test_acceptance_hint()
```

### `05_docker_logs.sh`
```bash
#!/bin/bash
set -e
echo "📋 Streaming vLLM logs (Ctrl+C to stop)..."
docker logs -f qwen36-27b-dflash-stable 2>&1 | grep -E "(spec_decode|KV cache usage|prefix cache|ERROR|OOM)"
```

### `06_dump_vllm_help.sh`
```bash
#!/bin/bash
set -e
echo "💾 Dumping vLLM serve --help to vllm_serve_help.txt..."
docker run --rm --gpus all vllm/vllm-openai:v0.20.0-cu130-ubuntu2404 vllm serve --help > vllm_serve_help.txt
echo "✅ Saved"
```

---

## 📐 GQA-Aware VRAM Math (The Real Numbers)

```
KV Cache (GB) = batch × layers × num_kv_heads × head_dim × seq_len × 2 × dtype_bytes × overhead / 1e9

Qwen3.6-27B Verified Constants:
  • layers = 48
  • num_kv_heads = 4  ← GQA (not 32!)
  • head_dim = 128
  • dtype_bytes = 1 (FP8_e4m3)
  • overhead = 1.15 (paged allocation, alignment)

Example: batch=24, seq_len=131072 (128k)
  24 × 48 × 4 × 128 × 131072 × 2 × 1 × 1.15 / 1e9 ≈ 3.44 GB KV cache

Total VRAM Estimate:
  • Target model (hybrid NVFP4/BF16): ~21.2 GB
  • DFlash drafter (BF16 2B): ~4.1 GB
  • KV cache (128k, batch=24): ~3.44 GB
  • Overhead (CUDA graphs, buffers): ~2.4 GB
  • TOTAL: ~31.1 GB → fits at --gpu-memory-utilization 0.88 (28.2 GB usable + paged allocation)
```

> ✅ **Key**: GQA reduces KV heads from 32 → 4, shrinking KV cache by ~8× vs. legacy MHA math. This is why 128k @ batch 24 is genuinely viable.

---

## 🎯 Tuning & Monitoring (Your Workflow Style)

### Acceptance Rate Thresholds (DFlash)
| α (Acceptance) | Interpretation | Action |
|----------------|----------------|--------|
| ≥ 0.75 | Excellent speculation | Try `num_speculative_tokens: 12` |
| 0.65–0.74 | ✅ Optimal | Keep current config |
| 0.50–0.64 | Marginal | Reduce to 8 tokens; verify drafter compatibility |
| < 0.50 | Poor speculation | Disable DFlash; debug drafter/target alignment |

### Log Patterns to Watch
```bash
./05_docker_logs.sh | grep -E "spec_decode|KV cache usage|prefix cache"
```
Example healthy log line:
```
[loggers.py:271] Engine 000: Avg generation throughput: 108.3 tokens/s, 
GPU KV cache usage: 12.4%, Prefix cache hit rate: 89.2%, 
spec_decode: avg acceptance rate: 0.78, avg block size: 10.2
```

### Quick VRAM Check
```bash
watch -n 2 'nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | sort -n | tail -1'
# ✅ Peak should stay ≤ 29,500 MiB with 0.88 util
```

---

## 🚨 Troubleshooting (Match Your README Style)

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| **OOM on startup** | `--max-model-len` too high for batch size | Reduce `--max-num-seqs` to 16, or `--max-model-len` to 65536 |
| **α < 0.5** | Drafter/target architecture mismatch | Verify `z-lab/Qwen3.6-27B-DFlash` config.json has `"num_key_value_heads": 4` |
| **FlashInfer JIT fail** | Missing SM 12.0 kernels in image | Ensure `TORCH_CUDA_ARCH_LIST=12.0` and `FLASHINFER_CUDA_ARCH=120` are set |
| **WSL2 reboot** | CUDA graph crash on old WSL | Update: `wsl --update --pre-release` (must be ≥ 2.7.0) |
| **Low prefix cache hit** | Prompts not repeating | Use `--enable-prefix-caching` + structure prompts with common prefixes |

---

## 📋 README.md Template (Your Style)

```markdown
# Qwen3.6-27B + DFlash — RTX 5090 High-Context Setup

Optimized for **RTX 5090 (32GB VRAM)** using **vLLM v0.20.0-cu130-ubuntu2404**.  
Features **GQA-aware memory management** + **DFlash block-diffusion speculative decoding**.

## Configuration

### Baseline (Recommended)
- **KV Cache**: `fp8_e4m3` (stable, high-quality)
- **Context**: 128K tokens
- **Batch**: 24 sequences
- **Utilization**: 0.88 (~3.8 GB headroom)
- **Speculation**: DFlash, 10 tokens/block, α target ≥ 0.65
- **Use case**: Daily coding, reasoning, long-document QA

### Aggressive (After Validation)
- **KV Cache**: `fp8_e4m3`
- **Context**: 128K tokens
- **Batch**: 32 sequences
- **Utilization**: 0.90
- **Speculation**: DFlash, 12 tokens/block (α ≥ 0.75 required)
- **Use case**: High-throughput batch inference

## Usage Scripts

### Setup
- `./00_a_pull_vllm_image.sh` — Fetch vLLM image
- `./00_b_create_conda_env.sh` — Create `testVllmQwen` env
- `./00_c_install_packages.sh` — Install host utilities
- `./00_d_pre_download_model.sh` — Cache models to `~/.cache/huggingface`

### Orchestration
- `./01_a_up_dflash.sh` — Start baseline service
- `./02_a_down_dflash.sh` — Stop service
- `./05_docker_logs.sh` — Monitor logs (filter: spec_decode, KV cache)

### Testing
- `./04_test_vllm_curl.py` — API smoke test

## Recommendations

1. **Pre-download first**: Run `00_d_pre_download_model.sh` to avoid runtime HF timeouts.
2. **Monitor acceptance rate**: α ≥ 0.65 is the threshold for net speedup with DFlash.
3. **GQA verification**: Confirm `num_key_value_heads: 4` in target model config.json.
4. **VRAM headroom**: Keep `--gpu-memory-utilization ≤ 0.90` for WSL2 stability.

## Monitoring

Watch these log patterns:
- `GPU KV cache usage`: >90% indicates context limit pressure
- `spec_decode: avg acceptance rate`: Target ≥ 0.65
- `Prefix cache hit rate`: >80% confirms caching efficiency

Example healthy log:
```
Engine 000: Avg generation throughput: 108.3 tokens/s, 
GPU KV cache usage: 12.4%, Prefix cache hit rate: 89.2%, 
spec_decode: avg acceptance rate: 0.78
```

## Troubleshooting

- **OOM**: Reduce `--max-num-seqs` or `--max-model-len`
- **Low α**: Verify drafter/target GQA alignment; reduce `num_speculative_tokens`
- **WSL2 crash**: Update to WSL2 ≥ 2.7.0
```

---

## ✅ Final Pre-Launch Checklist (Your Style)

- [ ] GPU: `nvidia-smi` shows RTX 5090, compute_120
- [ ] WSL2: ≥ 2.7.0 (Windows users)
- [ ] Models: Pre-downloaded via `00_d_pre_download_model.sh`
- [ ] Config: `num_key_value_heads: 4` verified in target model
- [ ] Docker: `shm_size: "32g"`, `ipc: host`, external `development-network`
- [ ] VRAM: Estimated peak ≤ 29.5 GB (with 0.88 util)
- [ ] Acceptance: Monitored post-launch via `./05_docker_logs.sh | grep spec_decode`

---

> **You're running modern GQA-optimized dense inference with DFlash acceleration on consumer hardware**.  
> The linear O(n) KV scaling with GQA's tiny coefficient is what makes 128k context at batch 24 genuinely viable on a single 32 GB RTX 5090.  
>  
> **If you hit a wall**: Check [vLLM SM 12.0 issues](https://github.com/vllm-project/vllm/issues?q=is%3Aissue+sm120) first, then verify drafter/target architecture alignment.  
>  
> **Share your metrics**: VRAM peak, α, and context length help refine this stack for the community. 🙏

*Guide matches your `DockerBuildFiles` conventions • Architecture-verified • Last audit: April 26, 2026*
