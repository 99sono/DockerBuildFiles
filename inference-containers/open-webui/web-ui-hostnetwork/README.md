# Open WebUI — Host Network Mode (for DeepSeek-V4-Flash cluster)

This variant uses `network_mode: host` and connects to the inference API on
`localhost:8000`. It is specifically designed for the DeepSeek-V4-Flash dual-Spark
cluster, where the head container uses host networking (required for RoCE/RDMA).

## When to use this

Use this when running the web UI on the **same node as the head** of a
host-networked inference cluster (like `deepseek-v4-flash-dgx-spark-cluster`).
The container shares the host network stack, so it can reach the vLLM API at
`localhost:8000` directly.

## When to use the devnetwork version instead

Use `../web-ui-devnetwork/` when the inference server uses Docker bridge
networking (the standard setup for single-node vLLM or llama.cpp containers).
That version resolves the server via Docker DNS as `inference-server` on the
`development-network` bridge.

## Quick reference

| Aspect | devnetwork | hostnetwork |
|--------|-----------|-------------|
| Network mode | Bridge (`development-network`) | Host |
| API URL | `http://inference-server:8000/v1` | `http://localhost:8000/v1` |
| Port | `11435:8080` (remapped) | `8080` (native) |
| Use case | Single-node bridge-net servers | Multi-node host-net clusters (DeepSeek) |
| Run on | Any node with dev-network | Same node as the inference head |

## Usage

```bash
# Start
./01_up.sh

# Stop
./02_down.sh

# Logs
./03_logs.sh

# Test connection
./04_test_connection.sh
```

## Access

Once running, open `http://<host-ip>:8080` in your browser.
