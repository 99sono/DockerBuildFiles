 # NGINX Reverse Proxy for vLLM HTTPS — Host Network Backend

This variant proxies to a vLLM inference server running in **host network mode** (e.g. the DeepSeek V4 Flash cluster). The nginx container itself uses standard bridge networking on the `development-network`.

## Why This Exists

Standard inference containers (Qwen, Gemma, etc.) run on the `development-network` Docker bridge, and the original nginx proxy (`../nginx-vllm-reverse-proxy-dgx-spark/`) connects to them via `http://inference-server:8000` (Docker DNS).

Cluster models like `deepseek-v4-flash-dgx-spark-cluster` use `network_mode: "host"` for InfiniBand RDMA. Docker DNS cannot resolve host-mode containers, so this variant uses `extra_hosts` in docker-compose to map the hostname `inference-server` to the DGX Spark's management IP (set in `.env` as `DGX_IP`).

## How It Works

1. `.env` → `DGX_IP=192.168.1.55` (the DGX Spark's management IP)
2. `docker-compose.yml` → `extra_hosts: inference-server:${DGX_IP}` adds `/etc/hosts` entry in the nginx container
3. `nginx.conf` → `proxy_pass http://inference-server:8000` (same as the original proxy!)
4. HTTPS traffic flows: client → nginx:443 → inference-server:8000

## Setup

```bash
# 1. Copy environment files
cp .env.example .env
cp 00_env.sh.example 00_env.sh
# Edit .env -> set DGX_IP to your DGX Spark's IP (e.g. 192.168.1.55)

# 2. Copy certificates from the sibling proxy folder
./00_b_copy_certs_from_original.sh

# 3. Pull nginx image
./00_a_pull_nginx_image.sh

# 4. Start the reverse proxy
./01_up.sh

# 5. Test the API
bash 04_test_curl.sh

# 6. Stop the reverse proxy
./02_down.sh
```

## Key Differences from the Original Proxy

| Aspect | Original (`-dgx-spark`) | Hostmode Backend (`-dgx-spark-hostmode`) |
|--------|--------------------------|------------------------------------------|
| Proxy target | `inference-server` (Docker DNS) | `inference-server` (via `extra_hosts`) |
| Target resolution | Docker DNS on bridge network | `/etc/hosts` entry → `${DGX_IP}` |
| nginx.conf | `proxy_pass http://inference-server:8000` | **Identical** |
| Container name | `nginx-proxy` | `nginx-proxy-hostmode` |
| Project name | `vllm-https` | `vllm-https-hostmode` |

## Files

| File | Purpose |
|------|---------|
| `.env.example` | `DGX_IP` and `VLLM_API_KEY` for docker-compose |
| `00_env.sh.example` | Bash script env vars (copy to `00_env.sh`) |
| `docker-compose.yml` | nginx on development-network + extra_hosts |
| `nginx.conf` | TLS + proxy to `inference-server:8000` |
| `00_a_pull_nginx_image.sh` | Pull nginx:latest |
| `00_b_copy_certs_from_original.sh` | Copy SSL certs from sibling folder |
| `01_up.sh` | Start the proxy |
| `02_down.sh` | Stop the proxy |
| `03_enter_container.sh` | Shell into the nginx container |
| `04_test_curl.sh` | Test HTTPS endpoints |