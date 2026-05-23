#!/usr/bin/env python3
"""Consolidated OpenAI-compatible API test client."""
import os, sys
from pathlib import Path


def load_env(env_path):
    """Load KEY=VALUE pairs from .env file into os.environ."""
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, _, v = line.partition("=")
            os.environ.setdefault(k.strip(), v.strip())


def main():
    from openai import OpenAI

    # If the URL is HTTPS but no explicit CA bundle is set, try the system
    # CA store (Ubuntu/Debian). This picks up self-signed certs installed via
    # update-ca-certificates — which certifi doesn't do by default.
    if "REQUESTS_CA_BUNDLE" not in os.environ and "SSL_CERT_FILE" not in os.environ:
        sys_ca = "/etc/ssl/certs/ca-certificates.crt"
        if Path(sys_ca).exists():
            os.environ["REQUESTS_CA_BUNDLE"] = sys_ca

    script_dir = Path.cwd()
    load_env(script_dir / ".env")

    url = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
    model = os.environ.get("INFERENCE_MODEL_ALIAS", "qwen3.6-27b")
    api_key = os.environ.get("INFERENCE_API_KEY", "dummy-key")
    prompt_file = Path(os.environ.get("TEST_PROMPT_FILE", "test/test_file_01_prompt.md"))
    output_file = Path(os.environ.get("TEST_OUTPUT_FILE", "test/test_output_01.md"))
    temperature = float(os.environ.get("INFERENCE_TEMP", "1.0"))
    top_p = float(os.environ.get("INFERENCE_TOP_P", "0.95"))
    max_tokens = int(os.environ.get("INFERENCE_MAX_TOKENS", "20000"))

    if not prompt_file.exists():
        prompt_file.parent.mkdir(parents=True, exist_ok=True)
        prompt_file.write_text(os.environ.get(
            "DEFAULT_PROMPT",
            "Write a heartfelt haiku about a father who deeply loves his wife and little daughter. Let it overflow with warmth, tenderness, and quiet devotion."
        ))

    client = OpenAI(base_url=url, api_key=api_key)

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt_file.read_text()}],
            temperature=temperature,
            top_p=top_p,
            max_tokens=max_tokens,
        )
        content = response.choices[0].message.content

        # Fallback: llama.cpp MTP may put text in reasoning_content
        if not content:
            reasoning = getattr(response.choices[0].message, "reasoning_content", None) or ""
            if reasoning:
                print("⚠️  'content' empty, using 'reasoning_content'")
                content = reasoning

        if content:
            output_file.write_text(content)
            print(f"✅ Success (temp={temperature}, top_p={top_p}, max_tokens={max_tokens})")
            print(f"Saved to: {output_file}")
            print(f"\nPreview:\n{content[:500]}")
        else:
            print("⚠️  Response content is empty.")

        usage = response.usage
        print(f"\n── Token Usage ──")
        print(f"  Prompt tokens: {usage.prompt_tokens}")
        print(f"  Completion tokens: {usage.completion_tokens}")
        print(f"  Total tokens: {usage.total_tokens}")

    except Exception as e:
        import traceback
        print(f"❌ Error: {e}")
        if hasattr(e, "response") and e.response is not None:
            print("Raw error response:", e.response.text)
        else:
            # Connection-level failures don't have a .response — show diagnostics
            print(f"\n── Diagnostics ──")
            print(f"  URL:     {url}")
            print(f"  Model:   {model}")
            print(f"  API key: {'***' + api_key[-4:] if len(api_key) > 4 else '***'}")
            print()
            traceback.print_exc()


if __name__ == "__main__":
    main()
