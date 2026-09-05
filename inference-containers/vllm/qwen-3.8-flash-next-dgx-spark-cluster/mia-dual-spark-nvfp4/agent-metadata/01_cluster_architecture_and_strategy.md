# Dual DGX Spark Architecture & Strategy: Qwen 3.8 Flash Next (NVFP4)

## 1. Overview & Credit

This implementation ports the multi-node dual-Spark recipe from **Mia AI Lab** ([`MiaAI-Lab/Qwen3.8-Flash-Next-Dual-DGX-Sparks`](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Dual-DGX-Sparks)) into the standard `DockerBuildFiles` multi-container cluster framework.

Credits:
- **Mia AI Lab** for discovering the memory bounds, the MXFP8 fallback, the `FP8_BLOCK_SCALES` MoE routing fix for MTP, QSA FP8 KV cache patching, and checkpoint config aliasing for MTP layer indexing.
- Upstream base: `vllm/vllm-openai:qwen38-flash-next`.

---

## 2. Hardware Environment & Sizing

- **Cluster Nodes**:
  - `spark01` (Head Node): 1x GB10 (128 GiB unified LPDDR5X, 121.7 GiB usable).
  - `spark02` (Worker Node): 1x GB10 (128 GiB unified LPDDR5X, 121.7 GiB usable).
  - Total Unified Memory: 256 GiB (243.4 GiB usable).
- **Interconnect**:
  - High-Speed Fabric: Dual Mellanox ConnectX-7 RoCE / InfiniBand (`rocep1s0f0`, `roceP2p1s0f0`).
  - Inter-node Link 1: `10.0.1.1/24` (`spark01`) $\leftrightarrow$ `10.0.1.2/24` (`spark02`) on interface `enp1s0f0np0`.
  - Inter-node Link 2: `10.0.2.1/24` (`spark01`) $\leftrightarrow$ `10.0.2.2/24` (`spark02`) on interface `enP2p1s0f0np0`.
  - Management / LAN: `192.168.1.55` (`spark01`) $\leftrightarrow$ `192.168.1.56` (`spark02`) on interface `enP7s7`.
- **Memory Allocation**:
  - `GPU_MEMORY_UTILIZATION=0.835` allocates ~32.02 GiB KV cache pool per node.
  - With `KV_CACHE_DTYPE=fp8`: allocates ~3,652,200 cache tokens (~13.9× context headroom at 262K native context).

---

## 3. Distributed Serving & Model Topology

- **Model ID**: `nvidia/Qwen3.8-Flash-Next-NVFP4` or `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4`.
- **Parallelism Scheme**:
  - Tensor Parallelism: `TP=2` (`--tensor-parallel-size 2`).
  - Expert Parallelism: `EP=true` (`--enable-expert-parallel --all2all-backend allgather_reducescatter`).
  - Multi-Token Prediction (MTP): `MTP=3` (`--speculative-config '{"method":"mtp","num_speculative_tokens":3}'`).
  - Vision Encoder: `--mm-encoder-tp-mode data` (replicates vision MLP across GPUs; required because intermediate size 4304 is not divisible by 16 when sharded at TP=2).
  - CUDA Graph Decoding: `--compilation-config '{"mode":0,"cudagraph_mode":"FULL_DECODE_ONLY"}'`.
- **Process Roles**:
  - **Head Node (`spark01`)**:
    - Distributed rank: `--node-rank 0`
    - API Server: Binds `0.0.0.0:8000` (and reverse-proxied / Open WebUI compatible).
    - Ray / PyTorch c10d Master: Binds `--master-addr 10.0.1.1 --master-port 25000`.
  - **Worker Node (`spark02`)**:
    - Distributed rank: `--node-rank 1`
    - Headless Worker: Runs `--headless` and connects to master at `10.0.1.1:25000`.

---

## 4. Orchestration: Mia's `start.sh` vs DockerBuildFiles Pattern

### Why we adapt Mia's script into Docker Compose
1. **No Passwordless SSH Dependency**:
   - Mia's upstream `start.sh` attempts to `ssh` / `scp` files directly from head to worker into `/tmp` and launch ad-hoc `docker run` containers.
   - In our environment, passwordless SSH between spark01 and spark02 is not enabled.
   - Instead, both spark01 and spark02 have local checkouts of `DockerBuildFiles` and their own Antigravity assistant sessions.
2. **Declarative & Lifecycle Management**:
   - DeepSeek v4 cluster (`deepseek-v4-flash-dgx-spark-cluster/variant03-dspark-nvfp4-0731`) established our multi-node standard:
     - `head/docker-compose.yml` on `spark01`.
     - `worker/docker-compose.yml` on `spark02`.
     - Standardized lifecycle scripts (`01_up.sh`, `02_down.sh`, `03_enter_container.sh`, `05_a_follow_logs.sh`, `05_b_dump_logs.sh`) sourcing `commonScripts/lib.sh`.
3. **Consistency across Nodes**:
   - Patch generation is self-contained in `00_a_prepare_patches.sh`.
   - Running `00_a_prepare_patches.sh` on each node generates the exact required overlay files locally from the container image.

---

## 5. Overlay Patches Required at Runtime

The Docker container `vllm/vllm-openai:qwen38-flash-next` requires overlay bind-mounts:

1. **`ple_layer.py`**:
   - Target: `/usr/local/lib/python3.12/dist-packages/vllm/models/qwen3_8_flash_next/nvidia/ple_layer.py`
   - Purpose: Dispatches between NVFP4 packed PLE tables (90 bytes/row) and FP8 tables (160 bytes/row) based on `text_config.ple_embedding_dtype`.
2. **`modelopt.py`**:
   - Target: `/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/modelopt.py`
   - Purpose: Provides fallback routing for MXFP8 shapes that FlashInfer `mm_mxfp8` cannot handle, and adds the missing `FP8_BLOCK_SCALES` routed-expert MoE branch needed by MTP.
3. **`qsa.py`**:
   - Target: `/usr/local/lib/python3.12/dist-packages/vllm/models/qwen3_8_flash_next/nvidia/ops/qsa.py`
   - Purpose: Enables FP8 KV cache support in QSA sparse attention kernels without kernel assert aborts.
4. **`patch_checkpoint_config.py`**:
   - Target: Mounts patched `config.json` and `hf_quant_config.json` over snapshot dir.
   - Purpose: Fixes the MTP layer naming mismatch where vLLM expects `mtp.layers.48.*` for absolute layer indexing while checkpoint only contains `mtp.layers.0.*`.
5. **RoCE / InfiniBand Fabric Configuration**:
   - Host network mode (`network_mode: "host"`), privileged, IPC host.
   - Pass-through devices: `/dev/infiniband:/dev/infiniband`.
   - Envs: `NCCL_NET=IB`, `NCCL_IB_HCA=rocep1s0f0,roceP2p1s0f0`, GID indices (`2,2` on spark01, `4,4` on spark02), socket ifnames.
