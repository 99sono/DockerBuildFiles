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
- Request bodies: `debug_logs/requests.log`
- Response bodies: `debug_logs/responses.log`

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
├── docker-compose.debug.yml     # OpenResty service
├── nginx.debug.conf             # Nginx config with Lua
├── README.md                    # This file
├── debug_logs/                  # Captured bodies (gitignored)
│   ├── requests.log
│   └── responses.log
└── .gitignore                   # Excludes debug_logs/