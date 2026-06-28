# NGINX Reverse Proxy with Dual Routing: Inference + Open WebUI

This nginx reverse proxy provides HTTPS termination and request routing for two upstream services running on the `development-network` Docker network:

- **`/inference/`** → Inference server (llamacpp, vLLM, etc.) at port 8000
- **`/`** → Open WebUI at port 8080 (WebSocket support for streaming)

No docker-compose changes needed — both upstream hostnames (`inference-server`, `web-ui-server`) resolve via Docker DNS when the respective containers join `development-network`.

## Key Features

1. Self-signed certificate (clients must install it explicitly)
2. Streaming support (`proxy_buffering off`)
3. Blocks the vulnerable `/invocations` endpoint (CVE-2026-22778 mitigation)
4. Dual routing: `/inference/` → inference API, `/` → Open WebUI
5. WebSocket upgrade support for real-time chat

## Reference

This setup follows the install guide:
[HTTPS via Nginx Reverse Proxy with vLLM](https://github.com/99sono/install_guides/blob/main/nvidia_dgx_spark_vllm/HTTPS-via-nginx-reverse-proxy-with-vLLM.md)

## Prerequisites

1. An inference container (llamacpp, vLLM, etc.) on `development-network` with `hostname: inference-server`, without publishing its port to the host.
2. An Open WebUI container on `development-network` with `hostname: web-ui-server`.
3. Docker and Docker Compose installed on the same host.
4. The DGX Spark hostname: `spark01`

## Quick Start

```bash
# 1. Generate self-signed certificate
./00_b_generate_self_signed_cert.sh

# 2. Install certificate in Ubuntu trust store
./01_a_install_ca_cert.sh

# 3. Pull nginx image
./00_a_pull_nginx_image.sh

# 4. Start the reverse proxy
./01_up.sh

# 5. Test the API
bash 04_test_curl.sh

# 6. Stop the reverse proxy
./02_down.sh
```

## API Endpoint

```
https://spark01/inference/v1/chat/completions
https://spark01/inference/v1/models
https://spark01/                        → Open WebUI
```

## Docker Compose Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `image` | `nginx:latest` | Latest nginx container |
| `ports` | `80:80, 443:443` | HTTP and HTTPS exposure |
| `network` | `development-network` (external) | Shared with inference + webui containers |

## nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    # Disable request/response buffering for streaming
    proxy_buffering off;
    proxy_request_buffering off;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate     /etc/nginx/ssl/nginx-selfsigned.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_connect_timeout 60s;

        # Block vulnerable /invocations endpoint
        location = /invocations {
            return 403;
        }

        # Route /inference/ to inference server (llamacpp, vllm, etc.)
        # Strips "/inference" prefix, so /inference/v1/chat/completions becomes /v1/chat/completions
        location /inference/ {
            client_max_body_size 100M;

            rewrite ^/inference(/.*)$ $1 break;

            proxy_pass http://inference-server:8000;
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Default route: Open WebUI at root (no subpath, avoids redirect issues)
        location / {
            client_max_body_size 100M;

            proxy_pass http://web-ui-server:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket support for real-time chat streaming
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
        }
    }
}
```

### Key Configuration Points

| Setting | Value | Purpose |
|---------|-------|---------|
| `/inference/` | `rewrite` + `proxy_pass inference-server:8000` | Strips prefix, forwards to inference API |
| `/` | `proxy_pass web-ui-server:8080` | Open WebUI as root application |
| `proxy_set_header Host` (`/inference/`) | `$proxy_host` | Forwards upstream container name |
| `proxy_set_header Host` (`/`) | `$host` | Preserves original Host header for webui |
| `proxy_buffering` | `off` | Streaming passthrough for token-by-token output |
| `/invocations` | `return 403` | Blocks vulnerable endpoint |
| WebSocket upgrade | `map` + `proxy_set_header Upgrade` | Real-time chat streaming |

## Logging Scripts

| Script | Purpose |
|--------|---------|
| `05_a_follow_logs.sh` | Follow container logs in real-time (like `tail -f`) |
| `05_b_dump_logs.sh` | Dump container logs to a local file for analysis |

## Maintenance Scripts

| Script | Purpose |
|--------|---------|
| `06_a_nginx_reload_config.sh` | Gracefully reload nginx config in-place without container restart |
| `06_b_nginx_verify_config.sh` | Validate nginx.conf syntax before applying changes |

## File Descriptions

| File | Purpose |
|------|---------|
| `docker-compose.yml` | nginx service — shares the external `development-network` with inference + webui |
| `nginx.conf` | nginx configuration with TLS, dual routing, streaming, and WebSocket support |
| `00_b_generate_self_signed_cert.sh` | Generates self-signed certificate with CN=spark01 |
| `01_a_install_ca_cert.sh` | Installs certificate in Ubuntu's system trust store |
| `01_b_remove_ca_cert.sh` | Removes certificate from Ubuntu's system trust store |
| `01_c_verify_ca_cert.sh` | Verifies if certificate is installed in Ubuntu's trust store |
| `01_up.sh` | Starts the nginx reverse proxy container |
| `02_down.sh` | Stops all containers managed by compose |
| `03_enter_container.sh` | Opens shell in the nginx container |
| `04_test_curl.sh` | Tests all HTTPS endpoints |
| `05_a_follow_logs.sh` | Follows container logs in real-time |
| `05_b_dump_logs.sh` | Dumps container logs to local file |
| `06_a_nginx_reload_config.sh` | Reloads nginx configuration without restart |
| `06_b_nginx_verify_config.sh` | Validates nginx configuration syntax |
| `nginx-proxy/ssl/` | Generated SSL files (git-ignored) |

## Client-Side Certificate Installation

Every client that needs to access the inference API via HTTPS must trust the self-signed certificate.

### On Linux (Ubuntu/Debian)

```bash
sudo cp nginx-proxy/ssl/nginx-selfsigned.crt /usr/local/share/ca-certificates/nginx.crt
sudo update-ca-certificates
```

### On macOS

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain nginx-selfsigned.crt
```

### On Windows

1. Double-click the `.crt` file
2. Click **Install Certificate**
3. Choose **Local Machine** → Place all certificates in the following store → **Trusted Root Certification Authorities**
4. Click **Finish**

### Python / requests / OpenAI SDK

Python's `certifi` bundle — used by both `requests` and the OpenAI SDK (via `httpx`) — does **not** read from Ubuntu's system CA store. Even after running `update-ca-certificates`, Python will still reject the self-signed cert with:

```
SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate
```

There are two ways to fix this.

**Option A: Point to the system CA bundle (recommended)**

For `requests`:

```python
import requests, os

os.environ["REQUESTS_CA_BUNDLE"] = "/etc/ssl/certs/ca-certificates.crt"

response = requests.post(
    "https://spark01/inference/v1/chat/completions",
    headers={"Authorization": "Bearer your-api-key"},
    json={"model": "gemma-4-12b", "messages": [{"role": "user", "content": "Hello"}]},
)
```

For the OpenAI SDK (which uses `httpx`, not `requests`):

```python
import httpx, os

ca_bundle = "/etc/ssl/certs/ca-certificates.crt"

client = openai.OpenAI(
    base_url="https://spark01/inference/v1",
    api_key="your-api-key",
    http_client=httpx.Client(trust_env=True, verify=ca_bundle),
)
```

**Option B: Point directly to the cert file**

```python
import requests

response = requests.post(
    "https://spark01/inference/v1/chat/completions",
    headers={"Authorization": "Bearer your-api-key"},
    json={"model": "gemma-4-12b", "messages": [{"role": "user", "content": "Hello"}]},
    verify="./nginx-proxy/ssl/nginx-selfsigned.crt"
)
```

**Note:** The `04_test_curl.sh` scripts in each inference container already handle this automatically via `test_client.py`. If HTTPS fails, check that: (1) the nginx proxy is running, and (2) the self-signed cert was installed with `./01_a_install_ca_cert.sh`.

## Directory Structure

```
nginx-vllm-reverse-proxy-dgx-spark/
├── .gitignore                # Excludes sensitive files
├── 00_a_pull_nginx_image.sh  # Pull nginx image
├── 00_b_generate_self_signed_cert.sh  # Generate SSL certificate
├── 01_a_install_ca_cert.sh     # Install CA cert in Ubuntu trust store
├── 01_b_remove_ca_cert.sh     # Remove CA cert from Ubuntu trust store
├── 01_c_verify_ca_cert.sh     # Verify CA cert installation status
├── 01_up.sh                  # Start the reverse proxy
├── 02_down.sh                # Stop the reverse proxy
├── 03_enter_container.sh     # Enter the nginx container
├── 04_test_curl.sh           # Test HTTPS endpoints
├── 05_a_follow_logs.sh       # Follow container logs in real-time
├── 05_b_dump_logs.sh         # Dump container logs to file
├── 06_a_nginx_reload_config.sh  # Reload nginx config in-place
├── 06_b_nginx_verify_config.sh  # Validate nginx config syntax
├── docker-compose.yml        # nginx service configuration
├── nginx.conf                # nginx reverse proxy configuration
├── logs/                     # nginx log files (mounted from container)
├── nginx-proxy/
│   └── ssl/                  # Generated SSL files (git-ignored)
│       ├── nginx-selfsigned.crt
│       └── nginx-selfsigned.key
├── metadata/                 # Debug information and logs
└── test/                     # Test configurations
```

## Common Issues

### nginx-proxy exits immediately with code 1

**Symptom:** Running `./01_up.sh` shows the container starts and then exits instantly.

```
[+] up 0/1
 ⠴ Container nginx-proxy Waiting          0.5s
container nginx-proxy exited (1)
```

**How to diagnose:** Check the container logs.

```bash
docker logs nginx-proxy
```

**Typical error:**

```
nginx: [emerg] host not found in upstream "inference-server" in /etc/nginx/nginx.conf:28
```

**Cause:** Nginx resolves the upstream hostname at **startup**, not at request time. If no container with `hostname: inference-server` exists on the `development-network` yet, nginx will fail to start and exit with code 1.

**Solution:** Start the inference server first, then start nginx.

```bash
# 1. Start the inference server (vLLM or llamacpp)
cd ~/dev/DockerBuildFiles/inference-containers/vllm/<your-model-folder>
docker compose up -d

# 2. Verify it's running and has the correct hostname
docker inspect --format '{{.Config.Hostname}}' <container-name>
# Should output: inference-server

# 3. Then start nginx
cd ~/dev/DockerBuildFiles/inference-containers/nginx/nginx-vllm-reverse-proxy-dgx-spark
./01_up.sh
```

Note: The same applies to `web-ui-server`. If Open WebUI is not running, the root `/` route will fail. Start both upstreams before nginx, or start nginx first and use `06_a_nginx_reload_config.sh` after bringing them up.

## Timeout Configuration

> **Important: this is the most common cause of "subagent died" or "connection reset by peer" errors during multi-agent orchestration.**

Nginx defaults to a 60-second `proxy_read_timeout`. Most LLM generation requests for multi-agent tasks take **several minutes**. If the timeout is not increased, nginx will silently kill active streams with:

```
upstream timed out (110: Connection timed out) while reading response header from upstream
```

You will see no 502 in the access log — just a sudden disconnect while the inference server is still generating. The agent will receive a `connection reset` and abort mid-stream.

### Symptoms

- Inference server logs show requests dropping mid-generation
- nginx `error.log` shows `upstream timed out (110: Connection timed out)`
- Agent output files are empty or truncated
- Multi-agent tasks fail — one agent completes, others die

### Required `proxy_read_timeout`

These settings are already present in `nginx.conf`:

```nginx
proxy_read_timeout 600s;   # 10 minutes — default 60s is too short for multi-agent
proxy_send_timeout 600s;
proxy_connect_timeout 60s;
```

### Debugging

```bash
# Check nginx error log for timed-out connections
tail -f logs/error.log | grep "upstream timed out"

# Check if inference server was still generating when connection dropped
# Compare timestamps: nginx error log vs inference server Engine request count
```

## Troubleshooting

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| 502 Bad Gateway on `/inference/` | Nginx cannot reach inference server | Check container is on `development-network` with `hostname: inference-server` |
| 502 Bad Gateway on `/` | Nginx cannot reach Open WebUI | Check container is on `development-network` with `hostname: web-ui-server` |
| SSL errors (client side) | Certificate not trusted | Install the self-signed cert on the client as shown above |
| Streaming hangs | Buffering re-enabled | Ensure `proxy_buffering off;` is present in the `http` block |
| Host header mismatch | Wrong `$proxy_host` vs `$host` | Use `$proxy_host` for inference, `$host` for webui (already correct in config) |