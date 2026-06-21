# Open WebUI — Inference Server Companion

This directory contains two Open WebUI configurations, one for each
inference networking mode:

| Directory | Port | API URL | When to use |
|-----------|------|---------|-------------|
| `web-ui-devnetwork/` | **11435** | `http://inference-server:8000/v1` | Inference server uses Docker bridge networking (standard single-node vLLM/llama.cpp). Resolved via Docker DNS on `development-network`. |
| `web-ui-hostnetwork/` | **11435** | Configurable via `.env` (default `http://192.168.1.55:8000/v1`) | Inference server uses `network_mode: host` (multi-node cluster with RoCE/RDMA). Connects via static IP instead of Docker DNS. |

## Quick Start

```bash
# Standard bridge-net server (e.g. single-node vLLM)
cd web-ui-devnetwork
./01_up.sh
# -> http://spark01:11435

# Host-net cluster (e.g. DeepSeek-V4-Flash dual-Spark)
cd web-ui-hostnetwork
cp .env.example .env    # edit INFERENCE_SERVER_URL if needed
./01_up.sh
# -> http://spark01:11435
```

Only one should run at a time — they share port 11435. Tear down one before starting the other.
