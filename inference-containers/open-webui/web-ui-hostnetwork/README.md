# Open WebUI — Host Network Mode (for DeepSeek-V4-Flash cluster)

This variant uses bridge networking but points directly at the DeepSeek
head node's management IP (`192.168.1.55:8000`). It is designed for the
DeepSeek-V4-Flash dual-Spark cluster, where the head container uses
`network_mode: host` (required for RoCE/RDMA) and therefore isn't reachable
via Docker DNS as `inference-server`.

## When to use this

Use this when the inference server uses `network_mode: host` instead of
bridge networking. This happens when the server needs direct access to
physical devices (InfiniBand/RoCE for multi-node GPU communication).

The web-UI container itself uses standard bridge networking — only the
API endpoint changes from the Docker DNS name to the head node's static IP.

## When to use the devnetwork version instead

Use `../web-ui-devnetwork/` when the inference server uses Docker bridge
networking (the standard setup for single-node vLLM or llama.cpp containers).
That version resolves the server via Docker DNS as `inference-server` on the
`development-network` bridge.

## Quick reference

| Aspect | devnetwork | hostnetwork |
|--------|-----------|-------------|
| Network mode | Bridge (`development-network`) | Bridge (`development-network`) |
| API URL | `http://inference-server:8000/v1` | `http://192.168.1.55:8000/v1` |
| Port | `11435:8080` | `11436:8080` |
| Use case | Bridge-net inference servers | Host-net inference clusters (DeepSeek) |
| Run on | Any node with dev-network | Any node that can reach spark01 |

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

Once running, open `http://spark01:11436` in your browser.
