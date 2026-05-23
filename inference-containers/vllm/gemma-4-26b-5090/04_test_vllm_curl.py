#!/usr/bin/env python3
# =============================================================================
# 04_test_vllm_curl.py
# =============================================================================
# Test the Gemma 4 5090 vLLM API endpoint with NVIDIA benchmark parameters.

import os
import sys
from pathlib import Path
from openai import OpenAI

# Load config from .env
from dotenv import load_dotenv
load_dotenv()

TEST_PROMPT_FILE = Path("test/test_file_01_prompt.md")
OUTPUT_FILE = Path("test/test_output_01.md")
URL = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "gemma-4-26b")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")

# NVIDIA benchmark parameters (from model card):
#   temperature=1.0, top_p=0.95, max_new_tokens=131072
TEMPERATURE = 1.0
TOP_P = 0.95
MAX_NEW_TOKENS = 131072

if not TEST_PROMPT_FILE.exists():
    print(f"Creating default prompt file...")
    TEST_PROMPT_FILE.parent.mkdir(parents=True, exist_ok=True)
    TEST_PROMPT_FILE.write_text("Hello Gemma 4! Write a short haiku about GPU memory.")

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
    OUTPUT_FILE.write_text(content)
    print(f"✅ Success! (temperature={TEMPERATURE}, top_p={TOP_P}, max_tokens={MAX_NEW_TOKENS})")
    print(f"Output saved to: {OUTPUT_FILE}")
    print(f"\nPreview:\n{content[:500]}")
except Exception as e:
    print(f"❌ Error: {e}")