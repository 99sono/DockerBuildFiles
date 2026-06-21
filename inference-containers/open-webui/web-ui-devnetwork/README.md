# Open WebUI — Development Network Mode

This variant uses the `development-network` Docker bridge and connects to the
inference API via Docker DNS as `http://inference-server:8000/v1`.

## When to use this

Use this when the inference server container is attached to the
`development-network` bridge (the standard setup for single-node vLLM or
llama.cpp containers). The server is reachable by its container hostname
(`inference-server`) on port 8000.

## When to use the hostnetwork version instead

Use `../web-ui-hostnetwork/` when the inference server uses `network_mode: host`
instead of bridge networking. This is necessary for multi-node clusters that
need RoCE/RDMA (like the DeepSeek-V4-Flash dual-Spark cluster). The hostnetwork
version connects via `http://localhost:8000/v1`.

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

Once running, open `http://localhost:11435` in your browser.
