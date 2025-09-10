# Simplified Docker Compose template for the final assembled development image (Layer 04)
#
# Purpose:
# - Illustrative template showing how to run the dev environment image built by this stack.
# - Focuses solely on launching the dev environment container, without extra services.
#
# How to use:
# - Replace the 'image' value with your assembled image tag (typically from Layer 04).
# - Provide API keys via environment variables if you plan to use coding agents that require them.
# - This template is minimal by design and intended as a starting point.

version: "3.9"

services:
  dev:
    # Replace this with your final assembled image reference (built from Layer 04).
    # Example after building layer 04:
    #   development-level04-project-stubs:1.0.0
    image: development-level04-project-stubs:${IMAGE_VERSION:-1.0.0}

    container_name: dev-environment
    # Map SSH for remote access to the container if needed (inherited entrypoint runs sshd)
    ports:
      - "2222:22"

    # Persist a workspace directory if you want source code to live on the host
    # volumes:
    #   - ./workspace:/home/developer/workspace

    # Agentic coding environment variables (optional).
    # These support tools like qwen-code (OpenAI-compatible) and Gemini CLI.
    # Recommended: create a local .env file next to this docker-compose.yml with your real values.
    # Only commit .env.example (placeholders). Never commit your .env to version control.
    # Docker Compose will automatically read .env in this directory and substitute into the values below.
    environment:
      # OpenAI-compatible variables used by qwen-code and similar tools
      OPENAI_API_KEY: ${OPENAI_API_KEY:-}
      OPENAI_BASE_URL: ${OPENAI_BASE_URL:-}
      OPENAI_MODEL: ${OPENAI_MODEL:-}
      # Other agent-specific keys (optional). Keep empty unless you use them.
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY:-}
      GEMINI_API_KEY: ${GEMINI_API_KEY:-}

    # Keep the container running using the inherited entrypoint from the image.
    # You can override command if you need a different behavior:
    # command: ["sleep", "infinity"]
