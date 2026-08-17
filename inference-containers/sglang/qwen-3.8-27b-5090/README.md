# Qwen3.8-27B NVFP4 Server on RTX 5090 (SGLang)

> RadixArk NVFP4 W4A4 checkpoint • FlashInfer attention • Blackwell SM 12.0 • in-checkpoint MTP

**Target Hardware:** RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)
**Model:** `RadixArk/Qwen3.8-27B-NVFP4` (~16.5 GB, NVFP4 W4A4 + FP8 projections)
**Engine:** SGLang (`lmsysorg/sglang:qwen38-27b`)
**Server Port:** `8000`

---

## Why NVFP4?

NVFP4 (W4A4) uses the RTX 5090's **FP4 tensor cores** — the quantization the
cookbook recommends for 32 GB Blackwell cards. FP8 weights (~28.5 GB) barely fit
a 32 GB card; NVFP4 weights (~16.5 GB) leave room for the KV/state pool and hit
the Blackwell FP4 peak throughput.

## Quick Start

```bash
# 1. Create conda env (only once) + install host-side tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 2. Pre-download the NVFP4 checkpoint into ./radixark/models/ (~16.5 GB)
#    Download is EXTERNAL — SGLang never downloads; it serves the local dir via --model-path.
cd radixark && ./00_d_pre_download_model.sh

# 3. Pull the SGLang image + start the server
./00_a_pull_image.sh   # run from project root (or from radixark/)
cd radixark && ./01_up.sh

# 4. Test the server
cd .. && ./04_test_curl.sh
```

### Scripts

```
qwen-3.8-27b-5090/
├── 00_a_pull_image.sh              # Pull lmsysorg/sglang:qwen38-27b image
├── 00_b_create_conda_env.sh        # Create testSGLangQwen conda env
├── 00_c_install_packages.sh        # Install huggingface-hub, openai, python-dotenv
├── 04_test_curl.sh                 # Test API call on port 8000
├── .env.example                    # Environment template (copy to .env)
├── README.md
├── test/                           # Test prompts
└── radixark/
    ├── 00_d_pre_download_model.sh  # Pre-download NVFP4 weights (skip if cached)
    ├── 00_e_force_download_model.sh# Force re-download (corrupt/update)
    ├── 01_up.sh                    # Start server (docker compose up -d)
    ├── 02_down.sh                  # Stop server
    ├── 03_enter_container.sh       # Bash into running container
    ├── 05_a_follow_logs.sh         # Live tail of logs
    ├── 05_b_dump_logs.sh           # Dump full logs to metadata/ (masked)
    ├── 06_dump_help.sh             # Dump server version/help
    ├── docker-compose.yml          # SGLang NVFP4 config
    └── metadata/                   # Benchmark logs, analysis reports
```

---

## Configuration Highlights

The compose file ships the **validated RTX 5090 recipe** from the SGLang cookbook
(low-latency single-request tier):

| Setting | Value | Why |
|---|---|---|
| `--kv-cache-dtype` | `fp8_e4m3` | NVFP4 checkpoint declares `kv_cache_quant_algo: FP8` |
| `--mem-fraction-static` | `0.9` | 90% of 32 GB VRAM for weights + KV/state pool |
| `--attention-backend` | `flashinfer` | SM120/SM121 Blackwell-optimized (trtllm_mha is SM100-only) |
| `--max-running-requests` | `1` | Validated single-stream envelope |
| `--cuda-graph-max-bs` | `1` | Match the single-request batch size |
| `--mamba-full-memory-ratio` | `4.59` | Hybrid GDN state pool sizing (see below) |
| `--mamba-radix-cache-strategy` | `extra_buffer` | 5 state slots/request (default guidance) |
| `--mamba-ssm-dtype` | `float32` | Checkpoint-declared GDN state precision |
| `--reasoning-parser` | `qwen3` | Structured reasoning for agent harnesses |
| `--tool-call-parser` | `qwen3_coder` | Decodes the model's `<tool_call>` blocks |

### Hybrid GDN memory (important for 32 GB)

Qwen3.8-27B is a hybrid Gated DeltaNet model: 48 linear-attention layers + 16
full-attention layers. The **GDN state pool** (not the KV cache) is what runs out
first on 32 GB cards, so:

- `--mamba-full-memory-ratio` divides post-weight memory between the GDN state
  pool and the paged KV pool. Default 0.9 over-provisions and silently clamps
  concurrency — 4.59 is the balanced value for this single-request tier.
- `--mamba-ssm-dtype`: one state slot is **153.9 MB at fp32** vs **78.4 MB at
  bf16**. We ship fp32 (checkpoint-declared); switch to `bfloat16` to hand more
  memory to KV if you need longer contexts.
- To serve more than 1 concurrent request, raise `--max-running-requests` and
  `--cuda-graph-max-bs` together and re-derive `--mamba-full-memory-ratio` with
  the [SGLang Mamba ratio calculator](https://lmsysorg.mintlify.app/cookbook/autoregressive/Qwen/Qwen3.8-27B#mamba-ratio-calculator).

---

## Performance

Expected decode throughput on RTX 5090 (NVFP4): **~150 tok/s/user** with EAGLE
speculative decoding; higher still for short-context single streams. Measured
numbers from this project's log dumps are tracked in `radixark/metadata/`.

### MTP / Speculative Decoding (optional)

The checkpoint ships an in-checkpoint MTP head (usable on the 5090 only over
NVFP4 weights). To enable EAGLE, add to the compose command:

```yaml
- "--speculative-algorithm"
- "EAGLE"
- "--speculative-num-steps"
- "3"
- "--speculative-eagle-topk"
- "1"
- "--speculative-num-draft-tokens"
- "4"
- "--enable-linear-replayssm-spec"
```

On fp32 state this needs `--mem-fraction-static 0.94` (0.92 for bf16). EAGLE is
disabled by default in this project (matches the validated low-latency recipe).

---

## Troubleshooting

### First Run: Large Download
The ~16.5 GB NVFP4 checkpoint is downloaded **externally** into
`radixark/models/` by `00_d_pre_download_model.sh` **before** the container
starts. SGLang does NOT download at runtime — `docker-compose.yml` mounts
`./models` read-only and serves it via `--model-path /models`. Verify the files
exist before `01_up.sh`:
```bash
ls -lh radixark/models/
```

### MTP errors / OOM
If enabling speculative decoding, ensure `--mem-fraction-static` matches the
dtype (0.94 fp32 / 0.92 bf16) and that `--cuda-graph-max-bs`/`--max-running-requests`
are both 1.

### Port conflict
Container uses port 8000 internally; change `INFERENCE_SERVER_PORT` in `.env` if
another server is already on 8000.

---

## References

- [SGLang cookbook: Qwen3.8-27B](https://lmsysorg.mintlify.app/cookbook/autoregressive/Qwen/Qwen3.8-27B)
- [HF model card](https://huggingface.co/RadixArk/Qwen3.8-27B-NVFP4)
