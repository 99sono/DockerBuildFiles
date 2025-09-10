# Docker Compose Template — Dev Environment (Illustrative)

Purpose
This template demonstrates how one might run the final assembled development image produced by this layered build (typically from Layer 04). It is intentionally minimal and focused on the dev environment only, removing unrelated services (e.g., Redis, Postgres).

What this template is (and is not)
- It is a starting point for consuming the final image outside of this repository’s build workflow.
- It is not a full-stack application compose file.
- It does not start additional services by default; add those only if your project needs them.

Image to run
Replace the image reference with the tag you build in your environment. By default the template references the Layer 04 image name and an overridable version:
```
services:
  dev:
    image: development-level04-project-stubs:${IMAGE_VERSION:-1.0.0}
```
You can change IMAGE_VERSION by exporting it in your shell or using an .env file next to docker-compose.yml:
```
IMAGE_VERSION=1.0.0
```

Agentic coding environment variables
Some coding agents (e.g., qwen-code and OpenAI-compatible tools) require runtime environment variables. This template passes them via docker-compose variable substitution. Recommended workflow:
- Copy .env.example to .env in the same directory as this docker-compose.yml
- Fill your real values in .env (do NOT commit .env; only commit .env.example)
- docker compose will automatically substitute these into the service environment

Compose snippet (already present in docker-compose.yml):
```
environment:
  # OpenAI-compatible variables used by qwen-code and similar tools
  OPENAI_API_KEY: ${OPENAI_API_KEY:-}
  OPENAI_BASE_URL: ${OPENAI_BASE_URL:-}
  OPENAI_MODEL: ${OPENAI_MODEL:-}
  # Other agent-specific keys (optional)
  OPENROUTER_API_KEY: ${OPENROUTER_API_KEY:-}
  GEMINI_API_KEY: ${GEMINI_API_KEY:-}
```

Provider examples for your .env (do not commit secrets)
A) OpenRouter (validated)
```
OPENAI_API_KEY=your_openrouter_key
OPENAI_BASE_URL=https://openrouter.ai/api/v1
OPENAI_MODEL=qwen/qwen3-coder:free
```

B) OpenAI (generic)
```
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini
```

C) DashScope (Qwen)
```
OPENAI_API_KEY=your_dashscope_key
OPENAI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
OPENAI_MODEL=qwen2.5-coder-32b-instruct
```

Notes
- qwen-code honors OPENAI_API_KEY, OPENAI_BASE_URL, and OPENAI_MODEL.
- GEMINI_API_KEY is used by the Google Gemini CLI for API calls.
- Do not hardcode real keys in docker-compose.yml or this README. Use your local .env.

How to use this template
1) Ensure you have built the images via the layered pipeline (01 → 02 → 03 → 04).
2) Update the image field in docker-compose.yml to match your built image/tag.
3) Create a local .env (copy from .env.example) next to docker-compose.yml and set your values (do NOT commit .env).
4) Start the dev container:
   ```
   docker compose up -d
   ```
5) Enter the container (if needed):
   ```
   docker exec -it dev-environment bash
   ```

Ports
The template maps SSH port 22 in the container to 2222 on the host:
```
ports:
  - "2222:22"
```
This matches the stack’s inherited entrypoint behavior (sshd from the base layers). Adjust as needed.

Volumes (optional)
If you want your source code to live on the host and be available in the container, uncomment and modify:
```
# volumes:
#   - ./workspace:/home/developer/workspace
```

Notes on layered structure
- Layer 01: Base software (sshd, base OS setup)
- Layer 02: Dev environments (Java, Node.js + npm, Miniforge/Python, build tools)
- Layer 03: Coding agents (Gemini CLI integrated first; Qwen Code added thereafter)
- Layer 04: Project stubs (final assembly image; recommended for use in this template)

Troubleshooting
- If the container starts but you cannot exec:
  - Check `docker ps` for container status.
  - Review logs: `docker logs dev-environment`
- If coding agents fail to run due to missing keys:
  - Confirm the environment variables are correctly passed (docker compose config).
  - Verify the agent CLI’s own documentation for additional setup needs.

Documentation references
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Qwen Code: https://github.com/QwenLM/qwen-code

Security considerations
- Do not commit actual API keys to version control.
- Only commit .env.example (placeholders). Keep your real .env local and gitignored.
- Avoid embedding real keys in docker-compose.yml or README.
- If you publish this directory, ensure .env is excluded.
