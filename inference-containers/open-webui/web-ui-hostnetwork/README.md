# Open WebUI — Host Network Mode (for host-net inference clusters)

Connects to an inference server that uses `network_mode: host` (required for
RoCE/RDMA multi-node GPU communication). Unlike the devnetwork variant, this
cannot rely on Docker DNS — it connects via a static IP configured in `.env`.

## When to use this

Use this when the inference server uses `network_mode: host` instead of
bridge networking. This is necessary for multi-node clusters that need
direct access to InfiniBand/RoCE hardware (like the DeepSeek-V4-Flash
dual-Spark cluster).

The web-UI container itself uses standard bridge networking — the only
difference from the devnetwork variant is the API endpoint URL.

## When to use the devnetwork version instead

Use `../web-ui-devnetwork/` when the inference server uses Docker bridge
networking (the standard single-node setup). That version resolves the
server via Docker DNS as `inference-server` on the `development-network`
bridge.

## Configuration

Edit `.env` (copy from `.env.example` first):

```bash
cp .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `INFERENCE_SERVER_URL` | `http://192.168.1.55:8000/v1` | The head node's API endpoint |
| `INFERENCE_API_KEY` | `dummy-key` | API key set on the vLLM server |
| `WEBUI_AUTH` | `false` | Enable Open WebUI login |

The default `INFERENCE_SERVER_URL` points to spark01's management IP (`192.168.1.55`).
Change it if your cluster head is at a different address.

## Quick reference

| Aspect | devnetwork | hostnetwork |
|--------|-----------|-------------|
| Network mode | Bridge (`development-network`) | Bridge (`development-network`) |
| API URL | `http://inference-server:8000/v1` (Docker DNS) | `http://192.168.1.55:8000/v1` (configurable) |
| Port | `11435:8080` | `11435:8080` |
| Use case | Bridge-net inference servers | Host-net clusters (DeepSeek) |
| Run on | Any node with `development-network` | Any node that can reach spark01 |

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

Open `http://spark01:11435` in your browser.
