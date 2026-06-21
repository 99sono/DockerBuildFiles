# NGINX Reverse Proxy for vLLM HTTPS — Host Network Mode

This variant runs nginx with `network_mode: "host"`, for use with **multi-node cluster models** that require host networking (e.g. DeepSeek V4 Flash).

## Why This Exists

Standard inference containers (Qwen, Gemma, etc.) run on the `development-network` Docker bridge network, and the original nginx proxy (`../nginx-vllm-reverse-proxy-dgx-spark/`) connects to them via `http://inference-server:8000` (Docker DNS).

Cluster models like `deepseek-v4-flash-dgx-spark-cluster` use `network_mode: "host"` for InfiniBand RDMA, so they cannot be reached via Docker DNS. Both the deepseek head container and this nginx proxy share the host network stack. The proxy target is `http://host.docker.internal:8000`.

## Certificates

This folder does **not** generate its own self-signed certificate. Instead, run:

```bash
./00_b_copy_certs_from_original.sh
```

This copies `nginx-selfsigned.crt` and `nginx-selfsigned.key` from the sibling `../nginx-vllm-reverse-proxy-dgx-spark/nginx-proxy/ssl/` folder.

## Quick Start

```bash
# 1. Copy environment configuration
cp 00_env.sh.example 00_env.sh

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

| Aspect | Original (`-dgx-spark`) | Hostmode (`-dgx-spark-hostmode`) |
|--------|--------------------------|----------------------------------|
| Network mode | `development-network` (bridge) | `network_mode: "host"` |
| Proxy target | `http://inference-server:8000` | `http://host.docker.internal:8000` |
| Port mapping | `80:80`, `443:443` | None (binds directly) |
| Container name | `nginx-proxy` | `nginx-proxy-hostmode` |
| Project name | `vllm-https` | `vllm-https-hostmode` |

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | nginx in host network mode |
| `nginx.conf` | TLS + proxy to `host.docker.internal:8000` |
| `00_a_pull_nginx_image.sh` | Pull nginx:latest |
| `00_b_copy_certs_from_original.sh` | Copy SSL certs from sibling folder |
| `01_up.sh` | Start the proxy |
| `02_down.sh` | Stop the proxy |
| `03_enter_container.sh` | Shell into the nginx container |
| `04_test_curl.sh` | Test HTTPS endpoints |