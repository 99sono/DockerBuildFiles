# Mistral Small 4 119B NVFP4 — DGX Spark (GB10)

Mistral Small 4 (119B MoE, 6.5B active) — NVFP4 compressed-tensors variant running on a single DGX Spark (128 GB UMA).

**Model:** https://huggingface.co/mistralai/Mistral-Small-4-119B-2603-NVFP4  
**EAGLE3 draft:** https://huggingface.co/mistralai/Mistral-Small-4-119B-2603-eagle

## References

### vLLM Official Recipe
https://recipes.vllm.ai/mistralai/Mistral-Small-4-119B-2603 — the "ideal" config targeting multi-node clusters with NVLink and abundant VRAM. Not directly applicable to DGX Spark.

### NVIDIA Forum Working Config (2026-03-17)
https://forums.developer.nvidia.com/t/running-mistral-small-4-119b-nvfp4-on-nvidia-dgx-spark-gb10/363863

The first confirmed working configuration on DGX Spark. Uses `avarok/dgx-vllm-nvfp4-kernel:v23` base image. Key findings:
- **MLA (head_size=320) rejected on SM 12.1a** by all backends (TRITON_MLA, FLASH_ATTN_MLA, FLASHINFER_MLA). Must disable with `VLLM_MLA_DISABLE=1`.
- **CUTLASS NVFP4 MoE kernel unstable** on DGX Spark. Use MARLIN backend instead (`VLLM_NVFP4_GEMM_BACKEND=marlin`).
- Context capped at **40K** due to larger KV cache with standard attention.
- ~27 tok/s sustained, ~99 GB RAM after startup.

## Config History

### Original (MLA + CUTLASS, froze)
| Setting | Value |
|---|---|
| `--attention-backend` | `TRITON_MLA` |
| MoE backend | FlashInferCutlass (auto) |
| `--max-model-len` | 262144 |
| `--gpu-memory-utilization` | 0.80 |
| `--tokenizer-mode` | auto (HF default) |

Result: model loaded (66 GB), torch.compile finished, system froze immediately after — likely during CUDA graph capture or KV cache init. Repeated twice, both required hard power-off.

### Current (NVIDIA workaround + our image)
| Setting | Value |
|---|---|
| `VLLM_MLA_DISABLE` | `1` |
| `VLLM_NVFP4_GEMM_BACKEND` | `marlin` |
| `VLLM_USE_FLASHINFER_MOE_FP4` | `0` |
| `VLLM_TEST_FORCE_FP8_MARLIN` | `1` |
| `--tokenizer-mode` | `mistral` |
| `--config-format` | `mistral` |
| `--load-format` | `mistral` |
| `--enforce-eager` | enabled (skip CUDA graphs) |
| `--max-model-len` | 262144 (kept — suspect is not the culprit) |
| `--gpu-memory-utilization` | 0.80 |
| Base image | `aidendle94/sparkrun-vllm-ds4-gb10:production-ready` |

**Deviation from NVIDIA post:** Same env-var workarounds, same mistral-native tokenizer/config/load flags, but using the DeepSeek vLLM image (v0.21.1rc1) instead of avarok's. Kept 262K context (NVIDIA caps at 40K) — KV cache with standard attention at 262K is ~34 GB (fp8), which combined with 66 GB model leaves ~28 GB for OS. Marginal but worth testing.

## Scripts

| Script | Purpose |
|---|---|
| `00_a_pull_vllm_image.sh` | Pull the vLLM Docker image |
| `00_b_pre_download_model.sh` | Pre-download model from HF |
| `01_up.sh` | Start the container |
| `02_down.sh` | Stop and remove the container |
| `03_enter_container.sh` | Open a bash shell inside the running container |
| `05_a_follow_logs.sh` | Follow container logs (`tail -f`) |
| `05_b_dump_logs.sh` | Dump full log to file |

## Usage

```bash
# Start
./01_up.sh

# Follow logs
./05_a_follow_logs.sh

# Test
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${INFERENCE_API_KEY}" \
  -d '{"model":"mistral-small4-119b","messages":[{"role":"user","content":"Hello"}],"max_tokens":50}'

# Stop
./02_down.sh
```

## EAGLE3 Speculative Decoding

Uncomment the `--speculative-config` section in `docker-compose.yml` to enable. Adds ~13 GB VRAM usage for the draft head. Likely incompatible with 262K context at current memory budget.

## Notes

- **MLA is disabled.** Standard attention at 262K uses far more KV cache memory than MLA would. If the server starts, expect RAM usage near 100 GB.
- **CUTLASS vs MARLIN:** Both are NVFP4 GEMM backends. MARLIN is more mature on SM 12.1a; CUTLASS is bleeding-edge and crashes on Spark.
- If the system freezes again, reduce `--max-model-len` to 40000 (NVIDIA's proven limit) or lower `--gpu-memory-utilization` to 0.75.
