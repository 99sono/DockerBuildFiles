# NGINX Reverse Proxy for vLLM HTTPS (Self-Signed Certificate)

This guide sets up an Nginx reverse proxy to add HTTPS in front of an already running vLLM container. The proxy handles SSL termination, request buffering (disabled for streaming), and security hardening.

## Key Features

1. Self-signed certificate (clients must install it explicitly)
2. Streaming support (`proxy_buffering off`)
3. Blocks the vulnerable `/invocations` endpoint (CVE-2026-22778 mitigation)
4. HTTP → HTTPS redirect on port 80

## Reference

This setup follows the official install guide:
[HTTPS via Nginx Reverse Proxy with vLLM](https://github.com/99sono/install_guides/blob/main/nvidia_dgx_spark_vllm/HTTPS-via-nginx-reverse-proxy-with-vLLM.md)

## Prerequisites

1. A running vLLM container on the `development-network` Docker network, without publishing its port to the host.
2. Docker and Docker Compose installed on the same host.
3. The DGX Spark hostname: `dgx-8ddc`

## Quick Start

```bash
# 1. Generate self-signed certificate
./00_b_generate_self_signed_cert.sh

# 2. Install certificate in Ubuntu trust store
./01_install_ca_cert.sh

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
https://dgx-8ddc/v1/chat/completions
https://dgx-8ddc/v1/models
https://dgx-8ddc/health
```

## Expected Output

Here is an example of what `bash 04_test_curl.sh` outputs when running correctly:

```
Warning: 00_env.sh not found. Auto-copying from 00_env.sh.example ...
Testing nginx reverse proxy with vLLM ...

=== Test 1: GET /health (HTTPS with -k) ===

{"status":"ok"}

=== Test 2: GET /v1/models (HTTPS with -k) ===
{"object":"list","data":[{"id":"Qwen3.6-35B-A3B-NVFP4","object":"model","created":1778346339,"owned_by":"vllm","root":"RedHatAI/Qwen3.6-35B-A3B-NVFP4","parent":null,"max_model_len":262144,"permission":[{"id":"modelperm-a13d647e6540f345","object":"model_permission","created":1778346339,"allow_create_engine":false,"allow_sampling":true,"allow_logprobs":true,"allow_search_indices":false,"allow_view":true,"allow_fine_tuning":false,"organization":"*","group":null,"is_blocking":false}]}]}

=== Test 3: POST /v1/chat/completions ===
{"id":"chatcmpl-87d17189b9199620","object":"chat.completion","created":1778346339,"model":"Qwen3.6-35B-A3B-NVFP4","choices":[{"index":0,"message":{"role":"assistant","content":"Hello! I hope you're having a wonderful day.","refusal":null}}],"usage":{"prompt_tokens":16,"total_tokens":1050,"completion_tokens":1034}}

=== Test 4: GET /invocations (should return 403) ===
HTTP Status: 403

All tests complete.
```

**Notes:**
- Test 1 (`/health`) returns `{"status":"ok"}` with no body output when healthy.
- Test 2 (`/v1/models`) lists available models with metadata.
- Test 3 (`/v1/chat/completions`) sends a prompt and receives a completion.
- Test 4 (`/invocations`) should return HTTP 403 (Forbidden) as this endpoint is blocked for security.

## Docker Compose Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `image` | `nginx:latest` | Latest nginx container |
| `ports` | `80:80, 443:443` | HTTP and HTTPS exposure |
| `network` | `development-network` (external) | Shared with existing vLLM container |

## nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    # Disable request/response buffering for streaming
    proxy_buffering off;
    proxy_request_buffering off;

    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate     /etc/nginx/ssl/nginx-selfsigned.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;

        # Security hardening
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Block the vulnerable /invocations endpoint
        location = /invocations {
            return 403;
        }

        # Proxy everything else to vLLM
        location / {
            proxy_pass http://vllm:8000;
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### Key Configuration Points

| Setting | Value | Purpose |
|---------|-------|---------|
| `server_name` | `_` | Matches any incoming Host header |
| `proxy_set_header Host` | `$proxy_host` | Forwards the upstream container name |
| `proxy_buffering` | `off` | Streaming passthrough for token-by-token output |
| `/invocations` | `return 403` | Blocks vulnerable endpoint |

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
| `docker-compose.yml` | nginx service — shares the external `development-network` with existing vLLM |
| `nginx.conf` | nginx configuration with TLS, streaming support, and proxy settings |
| `00_b_generate_self_signed_cert.sh` | Generates self-signed certificate with CN=dgx-8ddc |
| `01_install_ca_cert.sh` | Installs certificate in Ubuntu's system trust store |
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

Every client that needs to access the vLLM API must trust the self-signed certificate.

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

### Python / requests

If you can't install system-wide, point to the cert file explicitly:

```python
import requests

response = requests.post(
    "https://dgx-8ddc/v1/completions",
    headers={"Authorization": "Bearer your-api-key"},
    json={"prompt": "Hello", "max_tokens": 10},
    verify="./nginx-proxy/ssl/nginx-selfsigned.crt"
)
```

## Directory Structure

```
nginx-vllm-reverse-proxy-dgx-spark/
├── .gitignore                # Excludes sensitive files
├── 00_a_pull_nginx_image.sh  # Pull nginx image
├── 00_b_generate_self_signed_cert.sh  # Generate SSL certificate
├── 01_install_ca_cert.sh     # Install CA cert in Ubuntu trust store
├── 01_up.sh                  # Start the reverse proxy
├── 02_down.sh                # Stop the reverse proxy
├── 03_enter_container.sh     # Enter the nginx container
├── 04_test_curl.sh           # Test HTTPS endpoints
├── 05_a_follow_logs.sh          # Follow container logs in real-time
├── 05_b_dump_logs.sh            # Dump container logs to file
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

## Troubleshooting

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| 502 Bad Gateway | Nginx cannot reach vLLM | Check that both containers are on the same Docker network and vLLM is running. |
| SSL errors (client side) | Certificate not trusted | Install the self-signed cert on the client as shown in Client-Side Certificate Installation. |
| Streaming hangs | Buffering re-enabled | Ensure `proxy_buffering off;` is present in the `http` block. |
| Host header mismatch | vLLM expects a specific host | Use `proxy_set_header Host $proxy_host;` (already in the config). |