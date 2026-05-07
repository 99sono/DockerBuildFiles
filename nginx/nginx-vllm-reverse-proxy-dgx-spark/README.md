# NGINX Reverse Proxy for vLLM HTTPS (DGX Spark)

## Status: ⚠️ Unverified — Reference Guide

This folder contains the complete configuration for running an nginx reverse proxy with a self-signed SSL certificate, providing HTTPS access to a vLLM instance running on the shared Docker network.

## Requirements

- **Architecture:** ARM64 (DGX Spark / Grace Blackwell)
- **Docker:** With Docker Compose v2.x+
- **Network:** vLLM container must already be running on the `development-network`
- **CA Trust:** Self-signed certificate must be installed in Ubuntu's CA trust store

## Quick Start

```bash
# 1. Copy env template and set your DGX IP
cp .env.example .env
# Edit .env — replace [DGX_IP] with your DGX Spark's actual static IP (e.g. 192.168.1.50)

# 2. Generate self-signed certificate
./00_b_generate_self_signed_cert.sh

# 3. Install certificate in Ubuntu trust store
./01_install_ca_cert.sh

# 4. Pull nginx image
./00_a_pull_nginx_image.sh

# 5. Start the reverse proxy
./01_up.sh

# 6. Test the API
python 04_test_curl.py

# 7. Stop the reverse proxy
./02_down.sh
```

## Key Configuration (docker-compose.yml)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `image` | `nginx:1.30-alpine` | Lightweight nginx container |
| `ports` | `80:80, 443:443` | HTTP and HTTPS exposure |
| `platform` | `linux/arm64/v8` | ARM64 for DGX Spark |
| `network` | `development-network` (external) | Shared with existing vLLM container |

### nginx.conf

| Setting | Value | Purpose |
|---------|-------|---------|
| `client_max_body_size` | `64m` | Allow large prompt uploads |
| `proxy_read_timeout` | `300s` | vLLM long-running requests |
| `proxy_buffering` | `off` | Streaming passthrough |
| `ssl_protocols` | `TLSv1.2 TLSv1.3` | Secure TLS versions |

### Route Restrictions

| Route | Action | Description |
|-------|--------|-------------|
| `/v1/...` | Proxy to vLLM | OpenAI-compatible API |
| `/models` | Proxy to vLLM | Model listing |
| `/health` | Proxy to vLLM | Health check |
| `/invocations` | **403 Forbidden** | Blocked (CVE-2026-22778) |
| `/*` | **404 Not found** | Everything else denied |

### Security Features

- **Route restriction:** Only `/v1/*`, `/models`, `/health` routes are accessible; all others return 404.
- **CVE-2026-22778 mitigation:** `/invocations` is explicitly blocked with a 403 Forbidden response.
- **TLS hardening:** Only TLSv1.2 and TLSv1.3 allowed; weak ciphers excluded.
- **Self-signed certificate:** Certificate SAN includes `localhost`, `127.0.0.1`, and the DGX IP address from `.env`.

## nginx Alpine File Structure

This project uses the `nginx:1.30-alpine` image. Below is the default directory layout of an nginx Alpine container — useful for context when using `docker exec` or troubleshooting container issues.

```
/etc/nginx/              # Configuration root
├── nginx.conf           # Main configuration file (mounted from project root)
├── mime.types           # MIME type mappings
├── conf.d/
│   └── *.conf           # Server configs (not used here, nginx.conf is self-contained)
├── sites-enabled/       # Included sites (not used here)
├── snippets/            # Reusable config fragments (not used here)
/var/log/nginx/          # Access and error logs (redirected to STDOUT/STDERR)
/var/cache/nginx/        # Cached proxy data (disabled; proxy_cache off)
/etc/ssl/                # System certificate store (used for SSL certificate files)
```

### What You Mount

This project mounts only three things:

| Mount point | Source (project) | Purpose |
|-------------|-----------------|---------|
| `/etc/nginx/nginx.conf` | `nginx.conf` | Main nginx configuration — TLS, routing, proxy settings |
| `/etc/nginx/ssl/cert.pem` | `nginx-proxy/ssl/cert.pem` | SSL public certificate |
| `/etc/nginx/ssl/private.key` | `nginx-proxy/ssl/private.key` | SSL private key |

All other nginx paths (`/var/log/`, `/var/cache/`, etc.) use the Alpine defaults. This container uses only `nginx.conf` as its sole configuration file — no `conf.d/`, `sites-enabled/`, or `snippets/` are needed.

### Common Paths When Inside the Container

| Path | What You'll Find |
|------|-----------------|
| `/etc/nginx/nginx.conf` | Only file you'll edit — server config + all directives |
| `/var/log/nginx/access.log` | HTTP access log (redirected to STDOUT by default) |
| `/var/log/nginx/error.log` | Error log (redirected to STDERR by default) |
| `/usr/share/nginx/html/` | Default nginx landing page content directory |

## Directory Structure

```
nginx-vllm-reverse-proxy-dgx-spark/
├── .env.example              # Template (not committed to git)
├── .gitignore                # Excludes sensitive files
├── 00_a_pull_nginx_image.sh  # Pull nginx image
├── 00_b_generate_self_signed_cert.sh  # Generate SSL certificate
├── 01_install_ca_cert.sh     # Install CA cert in Ubuntu trust store
├── 01_up.sh                  # Start the reverse proxy
├── 02_down.sh                # Stop the reverse proxy
├── 03_enter_container.sh     # Enter the nginx container
├── 04_test_curl.py           # Test HTTPS endpoints
├── 05_docker_logs.sh         # View container logs
├── docker-compose.yml        # nginx service only (no vLLM)
├── nginx.conf                # nginx reverse proxy configuration
└── nginx-proxy/
    └── ssl/                  # Generated SSL certificate files (git-ignored)
```

## Workflow

This guide adds an nginx reverse-proxy layer on top of your **existing bare vLLM container**. Your DGX Spark already runs vLLM directly on port 8000 (HTTP). The docker-compose.yml below replaces that direct port exposure — the nginx proxy now handles all external HTTPS traffic and forwards internal HTTP requests to the vLLM container on the shared Docker network.

## API Endpoint

```
https://<DGX_IP>/v1/chat/completions
https://<DGX_IP>/v1/models
https://<DGX_IP>/health
```

## .env Configuration

The `.env` file must be created from `.env.example` before running any scripts:

```bash
# Your DGX Spark's actual static IP address (REQUIRED)
DGX_IP=192.168.1.50

# vLLM API key for authentication
VLLM_API_KEY=dummy-key
```

> ⚠️ The certificate generation script (`00_b_generate_self_signed_cert.sh`) will **refuse to run** if `DGX_IP` is still set to the placeholder value `[DGX_IP]`. You must replace it with your real DGX IP address before proceeding.

## Key Differences from Bare vLLM

| Aspect | Bare vLLM | With nginx reverse proxy |
|--------|-----------|-------------------------|
| Port | `8000` (HTTP) | `443` (HTTPS), `80` redirects to HTTPS |
| Certificate | None | Self-signed (generated per machine) |
| Client trust | Always needs curl `-k` | Trusts after CA install (`update-ca-certificates`) |
| Streaming | Works | Works (`proxy_buffering off`) |
| URL | `http://localhost:8000` | `https://<DGX_IP>` |
| Route access | All routes open | Restricted to `/v1/`, `/models`, `/health` |

## File Descriptions

| File | Purpose |
|------|---------|
| `docker-compose.yml` | nginx service only — shares the external `development-network` with existing vLLM |
| `nginx.conf` | nginx configuration with TLS, route restrictions, and proxy settings |
| `00_b_generate_self_signed_cert.sh` | Generates self-signed certificate with DGX IP in SAN |
| `01_install_ca_cert.sh` | Installs certificate in Ubuntu's system trust store |
| `01_up.sh` | Starts the nginx reverse proxy container |
| `02_down.sh` | Stops all containers managed by compose |
| `03_enter_container.sh` | Opens shell in the nginx container |
| `04_test_curl.py` | Tests all HTTPS endpoints (models, health, chat) |
| `05_docker_logs.sh` | Follows container logs in real-time |
| `nginx-proxy/ssl/` | Generated SSL files (git-ignored) |
| `metadata/` | Configuration dumps and logs |
| `test/` | Test configurations |

## Optional: Real Certificate

Replace the self-signed cert with a Let's Encrypt certificate using the nginx-proxy docker image `nginx/nginx:latest` + [`nginx-letsencrypt`](https://github.com/directust/nginx-letsencrypt) or [`linuxserver/swag`](https://github.com/linuxserver/docker-swag). The `nginx.conf` structure remains nearly identical — just mount the certificate files instead of generating them locally.
