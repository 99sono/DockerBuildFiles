# Debug Proxy – HTTP Traffic Dumper

## Purpose
Debug OpenCode ↔ vLLM tool_call parsing issues by capturing complete HTTP request/response bodies flowing through the nginx reverse proxy.

This is a **temporary debugging tool** that runs alongside the production nginx proxy. It uses OpenResty (nginx + Lua) to buffer and dump raw JSON/XML bodies to local log files.

## Key Differences from Production

| Aspect | Production | Debug Variant |
|--------|-----------|---------------|
| Image | `nginx:latest` | `openresty/openresty:alpine` |
| Buffering | OFF (streaming) | ON (full capture) |
| Protocol | HTTPS (443) | HTTP (8888) |
| Body logging | None | Full request/response bodies |
| Container | `nginx-proxy` | `nginx-proxy-debug` |
| Streaming | Responses stream token-by-token | Responses buffered; UI appears to "hang" until response complete |

## Quick Start

```bash
# 1. Start the debug proxy
./01_up.sh

# 2. Point OpenCode to http://<spark-host>:8888

# 3. Watch logs in real-time (use separate terminals)
./04_follow_requests.sh    # Terminal 1: request bodies
./05_follow_responses.sh   # Terminal 2: response bodies

# 4. Trigger the bug in OpenCode

# 5. Stop when done
./02_down.sh
```

## Logs Location

All logs are mounted to a single directory on the host: `./logs/`

| Log Type | Path (container) | Path (host) |
|----------|-----------------|-------------|
| Standard access log | `/var/log/nginx/access.log` | `./logs/access.log` |
| Standard error log | `/var/log/nginx/error.log` | `./logs/error.log` |
| Captured requests | `/var/log/nginx/requests.log` | `./logs/requests.log` |
| Captured responses | `/var/log/nginx/responses.log` | `./logs/responses.log` |

## Log Format

### requests.log
```
2026-05-10 08:30:00 REQUEST
Method: POST
URI: /v1/chat/completions
Body:
{"model": "...", "messages": [...], "tools": [...]}
---
```

### responses.log
```
2026-05-10 08:30:01 RESPONSE
Status: 200
Body:
{"id": "chatcmpl-...", "object": "chat.completion", ...}
---
```

## ⚠️ Permissions & Pitfalls

### Log Directory Permissions

The Nginx worker processes in this container run as the user `nobody`. While the Nginx master process (running as `root`) can write to the standard `access.log` and `error.log`, the **Lua scripts** use standard file I/O which inherits the worker's permissions.

**Problem:** If the mounted `./logs` directory is owned by `root` or your host user, the Lua script will fail to create `requests.log` and `responses.log`.

**Solution:** Create the log files on the host first, then make them world-writable. Since `./logs` is a host-mounted volume (`./logs:/var/log/nginx`), the container's `nobody` user writes directly to the host filesystem. Run these commands on the **host** before starting the container:

```bash
mkdir -p logs && touch logs/requests.log logs/responses.log && chmod -R 777 logs
```

This ensures:
1. The files exist before the container starts (no file creation race conditions)
2. The `nobody` user inside the container can read and write to them
3. The host directory permissions match what the Lua scripts expect

> **Note:** In a hardened production environment, you would `chown` the directory to the specific UID of the Nginx worker instead of using `777`.


## 🔒 Security & Decommissioning

### ⚠️ SECURITY ALERT — Ephemeral Use Only

**This container is for short-term diagnostic use only.**

Because it logs raw request and response bodies, the `logs/` directory will contain:
- **Plaintext API keys** (from request headers)
- **Sensitive prompts and user data**
- **Model responses that may contain proprietary information**

Treat the `logs/` folder like **toxic waste**: useful for the job, but something you want to dispose of immediately after you're done.

### Decommissioning Protocol

As soon as your debugging session is over:

```bash
# 1. Stop the debug proxy
./02_down.sh

# 2. Remove captured log files (keeps the directory structure intact)
rm -f ./logs/requests.log ./logs/responses.log ./logs/access.log ./logs/error.log
```

Do **not** leave the `.log` files sitting on your disk after debugging — they contain sensitive data. The `./logs/` directory itself must remain intact (it is expected by docker-compose). Every minute the container runs, more sensitive data accumulates. Clean up promptly.

## Important Notes
- **HTTP only** – API key appears in logs; change it after debugging
- **No SSL** – certificates not needed
- **Runs alongside production** – both proxies can coexist on the same host
- **Restart after config changes** – `./02_down.sh && ./01_up.sh`
- **Logs are appended** – old logs persist; delete manually if needed

## Directory Structure

```
nginx-vllm-reverse-proxy-dgx-spark-data-dumper/
├── 00_env.sh                    # Environment variables
├── 00_env.sh.example            # Template
├── 01_up.sh                     # Start debug proxy
├── 02_down.sh                   # Stop debug proxy
├── 03_enter_container.sh        # Enter container shell
├── 04_follow_requests.sh        # Tail request logs
├── 05_follow_responses.sh       # Tail response logs
├── 06_a_follow_logs.sh          # Follow docker container logs
├── 06_b_dump_logs.sh            # Dump docker container logs to file
├── docker-compose.debug.yml     # OpenResty service
├── nginx.debug.conf             # Nginx config with Lua
├── README.md                    # This file
├── logs/                        # Captured bodies + nginx logs (gitignored)
│   ├── access.log
│   ├── error.log
│   ├── requests.log
│   ├── responses.log
│   └── docker_logs_dump.txt
└── .gitignore                   # Excludes logs/