# vLLM Nightly — Qwen3.6-35B-A3B-NVFP4 (DGX Spark)

NVIDIA-recommended NVFP4 quantized MoE model running on DGX Spark via vLLM nightly build.

[Model card →](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4)

---

## Current Configuration

This setup follows NVIDIA's own recommendation from the HF model page:

```bash
export VLLM_USE_FLASHINFER_MOE_FP4=0
export VLLM_FP8_MOE_BACKEND=flashinfer_cutlass
export FLASHINFER_DISABLE_VERSION_CHECK=1
export CUTE_DSL_ARCH=sm_121a
```

Key command-line flags:

| Flag | Value | Reason |
|---|---|---|
| `--moe-backend` | `marlin` | FlashInfer FP4 path disabled for stability on GB10 (SM 121a) |
| `--attention-backend` | `flashinfer` | Attention backend — no issue here, FlashInfer works well for attention |
| `--kv-cache-dtype` | `fp8` | fp8 KV cache to save memory |
| `--max-model-len` | `262144` | Generous context window |
| `--gpu-memory-utilization` | `0.85` | Leaves room for KV cache (Spark has 128 GB UMA) |

---

## Known Trade-off: Marlin vs Native FP4

The DGX Spark (Blackwell GB10) *does* have native FP4 tensor cores, but we're using the **Marlin MoE backend**, which dequantizes NVFP4 weights to BF16 on-the-fly rather than feeding them directly into FP4 tensor cores. This is intentional — NVIDIA's own recommendation disables FlashInfer's FP4 path (`VLLM_USE_FLASHINFER_MOE_FP4=0`) for stability on this early GB10 silicon.

The vLLM log will warn:

```
Your GPU does not have native support for FP4 computation but FP4 quantization is being used.
Weight-only FP4 compression will be used leveraging the Marlin kernel.
```

This warning is misleading — the hardware *does* support FP4, but we're choosing correctness over raw speed until FlashInfer + GB10 is proven stable.

**If you want to experiment with native FP4 paths**, try swapping `--moe-backend` to `flashinfer_cutlass` or `flashinfer_trtllm`. Test with small workloads first — early GB10 + FlashInfer FP4 has shown instability.

---

## Scripts

| Script | Purpose |
|---|---|
| `00_a_pull_vllm_image.sh` | Pull latest vLLM nightly Docker image |
| `00_b_pre_download_model.sh` | Pre-download model from HF into page cache |
| `01_up_nvidia.sh` | Start the vLLM container |
| `02_down.sh` | Stop and remove the container |
| `03_enter_container.sh` | Open a bash shell inside the running container |
| `05_a_follow_logs.sh` | Follow container logs in real-time (`tail -f`) |
| `05_b_dump_logs.sh` | Dump full log to timestamped file (api_key masked as `dummy-key`) |
