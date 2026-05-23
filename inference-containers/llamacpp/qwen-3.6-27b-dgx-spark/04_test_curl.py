#!/usr/bin/env python3
# =============================================================================
# 04_test_curl.py
# =============================================================================
# Test the llama.cpp Qwen 3.6-27B MTP server on port 8081.
#
# Model: unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL
# =============================================================================

import sys
from pathlib import Path
from openai import OpenAI

# Load API key from .env
from dotenv import load_dotenv
load_dotenv()

TEST_PROMPT_FILE = Path("test/test_file_01_prompt.md")
OUTPUT_FILE = Path("test/test_output_01.md")
import os
URL = os.environ.get("INFERENCE_SERVER_URL", "https://localhost/v1")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "qwen3.6-27b")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")

# Parameters matching docker-compose.yml
TEMPERATURE = 1.0
TOP_P = 0.95
MAX_NEW_TOKENS = 2048

if not TEST_PROMPT_FILE.exists():
    print(f"Creating default prompt file...")
    TEST_PROMPT_FILE.parent.mkdir(parents=True, exist_ok=True)
    TEST_PROMPT_FILE.write_text(
        "Write a Python function that takes a string, "
        "reverses it, and removes all vowels."
    )

prompt = TEST_PROMPT_FILE.read_text()

client = OpenAI(base_url=URL, api_key=API_KEY)

try:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=TEMPERATURE,
        top_p=TOP_P,
        max_tokens=MAX_NEW_TOKENS,
    )
    content = response.choices[0].message.content

    # llama.cpp with MTP may return empty content but populate reasoning_content
    if not content:
        reasoning = getattr(response.choices[0].message, "reasoning_content", None) or ""
        if reasoning:
            print("⚠️  'content' is empty, falling back to 'reasoning_content'")
            content = reasoning

    if content:
        OUTPUT_FILE.write_text(content)
        print(f"✅ Success! (temperature={TEMPERATURE}, top_p={TOP_P}, max_tokens={MAX_NEW_TOKENS})")
        print(f"Output saved to: {OUTPUT_FILE}")
        print(f"\nPreview:\n{content[:500]}")
    else:
        print("⚠️  Response content is empty.")
        print("   Raw response:")
        print(f"   {response.model_dump_json(indent=2)}")

    # Print token usage
    usage = response.usage
    print(f"\n── Token Usage ──")
    print(f"  Prompt tokens: {usage.prompt_tokens}")
    print(f"  Completion tokens: {usage.completion_tokens}")
    print(f"  Total tokens: {usage.total_tokens}")
except Exception as e:
    print(f"❌ Error: {e}")
