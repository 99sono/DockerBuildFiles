# Qwen3.8-27B Server on RTX 5090 (llama.cpp)

> Unsloth Dynamic UD-Q4_K_XL (largest 4-bit) • MTP speculative decoding • Blackwell SM 12.0

**Target Hardware:** RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)
**Model:** `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL` (17.9 GB)
**Speculative Decoding:** MTP (Multi-Token Prediction) with `--spec-type draft-mtp`
**Server Port:** `8000`

---

## Model Facts (from Unsloth docs & HF config)

- **Family:** Qwen3.8-27B — dense 27B, hybrid thinking model with vision + reasoning
- **Architecture:** `qwen3_5` — same family already supported by the llama.cpp image used here
- **Context:** 262,144 native (extensible to 1M via YaRN)
- **MTP:** Baked into the GGUF (`unsloth_fixed_mtp: true`, `mtp_num_hidden_layers: 1`) → no separate draft model needed
- **Hybrid attention:** 3× linear-attention (Gated DeltaNet) + 1× full-attention per group. Only 16 of 64 layers are full-attention, so the KV cache is tiny — 256K context fits in 32 GB VRAM
- **Vision:** Native vision-language model; vision encoder lives in separate `mmproj-*.gguf` files (not needed for text/coding use)

### Why UD-Q4_K_XL?

From the HF file listing, this is the **largest 4-bit quant** available:

| Quant | Size |
|---|---|
| `UD-Q4_K_XL` | **17.9 GB** ← chosen |
| `Q4_1` | 17.5 GB |
| `Q4_K_M` | 17.1 GB |
| `IQ4_NL` | 16.3 GB |
| `IQ4_XS` | 15.7 GB |

The 32 GB+ quants (`UD-Q6_K_XL` 25.9 GB, `Q8_0` 29 GB, `UD-Q8_K_XL` 31.5 GB) don't leave enough headroom on this PC's RAM, so we use the largest 4-bit.

---

## Quick Start

```bash
# 1. Create conda env (only once) + install host-side tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 2. Pre-download the GGUF into ./unsloth/models/ (~17.9 GB)
#    Download is EXTERNAL — llama.cpp never downloads; it serves the local file via -m.
cd unsloth && ./00_d_pre_download_model.sh

# 3. Start the server
cd unsloth && ./01_up.sh

# 4. Test the server
./04_test_curl.sh
```

### Scripts

```
qwen-3.8-27b-5090/
├── 00_a_pull_image.sh              # Pull llama.cpp server-cuda13 image
├── 00_b_create_conda_env.sh        # Create testLlamaCppQwen conda env
├── 00_c_install_packages.sh        # Install huggingface-hub, openai, python-dotenv
├── 04_test_curl.sh                 # Test API call on port 8000
├── .env.example                    # Environment template (copy to .env)
├── README.md
├── test/                           # Test prompts
└── unsloth/
    ├── 00_d_pre_download_model.sh  # Pre-download GGUF weights (skip if cached)
    ├── 00_e_force_download_model.sh# Force re-download (corrupt/update)
    ├── 01_up.sh                    # Start server (docker compose up -d)
    ├── 02_down.sh                  # Stop server
    ├── 03_enter_container.sh       # Bash into running container
    ├── 05_a_follow_logs.sh         # Live tail of logs
    ├── 05_b_dump_logs.sh           # Dump full logs to metadata/ (masked)
    ├── 06_dump_help.sh             # Dump server version/help
    ├── docker-compose.yml          # llama-server MTP config
    └── metadata/                   # Benchmark logs, VRAM traces
```

---

## Recommended Sampling (from Unsloth Qwen3.8 docs)

Qwen3.8-27B is a hybrid thinking model. The docs recommend different defaults per mode:

| Parameter | Thinking Mode | Instruct (non-thinking) Mode |
|---|---|---|
| `temperature` | 1.0 | 0.7 |
| `top_p` | 0.95 | 0.80 |
| `top_k` | 20 | 20 |
| `min_p` | 0.0 | 0.0 |
| `presence_penalty` | 0.0 | 1.5 |
| `repetition_penalty` | 1.0 | 1.0 |

The docker-compose.yml ships with **Thinking Mode** defaults. Override per-request via the OpenAI API if needed (e.g. `temperature`, `presence_penalty`).

### Reasoning Control

Qwen3.8-27B supports `reasoning_effort` to tune reasoning depth:
- `xhigh` (default): complex tasks demanding thorough analysis
- `medium`: balance accuracy and speed
- `low`: efficient reasoning optimizing for speed and cost
- `none`: disable thinking

---

## MTP Speculative Decoding

MTP heads are **baked into the GGUF** — no separate draft model needed. Chain math:

```
P(full chain accepted) = P(per token)^n_max
```

At ~52% per-token acceptance at deep context (>15k tokens):
- `n-max = 3`: 0.52³ ≈ 14% → 86% of the time you fall back to baseline
- `n-max = 2`: 0.52² ≈ 27% → steadier performance

We use `--spec-draft-n-max 2` with `--spec-draft-p-min 0.8` (conservative, protects reasoning quality).

**Expected performance on RTX 5090** (from Qwen3.6-27B MTP benchmarks — Qwen3.8 should be comparable):

| Context Depth | Generation (t/s) | Acceptance Rate |
|---|---|---|
| Short (<8K tokens) | ~90-95 t/s | ~79% |
| Deep (>15K tokens) | ~85-90 t/s | ~60-80% |

---

## Blackwell Kernel Notes

The container uses `ghcr.io/ggml-org/llama.cpp:server-cuda13` but overrides `LD_LIBRARY_PATH` to `/usr/local/cuda-12.8/lib64`. The pure CUDA 13 runtime has known bugs where it fails to offload layers to the GPU and silently falls back to the CPU. CUDA 12.8 contains mature, fully optimized **MMQ (Multi-Matrix Quantization)** kernels for Blackwell SM120. Verify in logs:

```
BLACKWELL_NATIVE_FP4 = 1
USE_GRAPHS = 1
```

---

## Troubleshooting

### First Run: Large Download
The 17.9 GB GGUF is downloaded **externally** into `unsloth/models/` by `00_d_pre_download_model.sh` **before** the container starts. llama.cpp does NOT download at runtime — `docker-compose.yml` mounts `./models` read-only and serves it via `-m`. Verify the file exists before `01_up.sh`:
```bash
ls -lh unsloth/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
```

### MTP not active
Check logs for `draft acceptance rate`. If `--spec-type draft-mtp` errors with "unknown speculative type", the image lacks MTP support — pull a newer `server-cuda13` tag.

### Vision
For text/coding use, no `mmproj` needed. To enable vision later, download `mmproj-F16.gguf` from the same repo and add `--mmproj`.

### Context Capacity Warning
```
n_ctx_seq (262144) == n_ctx_train (262144) -- full model capacity utilized
```
No warning expected since we use the native 256K context.

---

## References

- [Unsloth Qwen3.8 docs](https://unsloth.ai/docs/models/qwen3.8)
- [HF model card](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)
- [Qwen3.8 blog](https://qwen.ai/blog?id=qwen3.8)
