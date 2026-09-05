# Implementation Plan: Qwen 3.8 Flash Next Dual-Spark (Mia NVFP4)

## Phase 1: Directory Scaffolding & Shared Assets
- [x] Create directory structure under `inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/`:
  - `agent-metadata/`
  - `files/`
  - `head/`
  - `worker/`
- [x] Document architecture and networking contracts in `agent-metadata/01_*.md` and `02_*.md`.

## Phase 2: Patch Pipeline & Overlay Tooling
- Populate `files/` with the python patchers from Mia's recipe:
  - `patch_checkpoint_config.py`: Adds MTP absolute-index layer aliases (`mtp.layers.48.*`).
  - `patch_ple_layer.py`: Patches `ple_layer.py` for mixed NVFP4/FP8 PLE dispatch.
  - `patch_modelopt_mxfp8.py`: MXFP8 fallback to BF16 kernel.
  - `patch_modelopt_fp8_block_moe.py`: Adds `FP8_BLOCK_SCALES` MoE expert routing for MTP.
  - `patch_qsa_fp8_kv.py`: Enables FP8 KV cache in QSA sparse attention.
  - `detect_ple_dtype.py`: Auto-detects PLE embedding dtype from checkpoint config.
- Create `00_a_prepare_patches.sh`:
  - Checks if `vllm/vllm-openai:qwen38-flash-next` is available.
  - Extracts baseline unpatched python files directly from the Docker container if needed.
  - Executes the patch generation scripts to produce `ple_layer_patched.py`, `modelopt_patched.py`, and `qsa_patched.py`.
  - Runs `patch_checkpoint_config.py` on the cached model snapshot to generate `config_patched.json`.

## Phase 3: Head Node Setup (`head/`)
- `docker-compose.yml`:
  - Service: `qwen38-flash-next-head`
  - Host network, IPC host, IB devices `/dev/infiniband:/dev/infiniband`
  - Node rank 0, master addr `10.0.1.1`, master port `25000`
  - Port 8000 exposed
  - TP=2, EP=true, MTP=3, GMU=0.835, KV cache=fp8
  - Overlay volume bind-mounts
- `.env.example` with full configuration comments
- Standard lifecycle scripts:
  - `01_up.sh`
  - `02_down.sh`
  - `03_enter_container.sh`
  - `04_check_nccl.sh`
  - `05_a_follow_logs.sh`
  - `05_b_dump_logs.sh`

## Phase 4: Worker Node Setup (`worker/`)
- `docker-compose.yml`:
  - Service: `qwen38-flash-next-worker`
  - Host network, IPC host, IB devices
  - Node rank 1, `--headless`
  - Master addr `10.0.1.1`, master port `25000`
  - Same model args and overlay volume bind-mounts
- `.env.example`
- Standard lifecycle scripts:
  - `01_up.sh`
  - `02_down.sh`
  - `03_enter_container.sh`
  - `05_a_follow_logs.sh`
  - `05_b_dump_logs.sh`

## Phase 5: Verification Client & Documentation
- `04_test_vllm_curl.py`: Tests `/health`, `/v1/models`, reasoning chat completion, and tool-calling.
- `README.md`: High-level explanation, hardware credit to Mia AI Lab, launch instructions for `spark01` and `spark02`.

## Phase 6: Validation & Verification
- Run `docker compose -f head/docker-compose.yml config` to ensure syntax validity.
- Run `docker compose -f worker/docker-compose.yml config` to ensure syntax validity.
- Commit all changes cleanly to git.
