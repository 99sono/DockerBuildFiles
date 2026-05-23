#!/usr/bin/env python3
"""
04_c_test_python_client.py - Full chat test via OpenAI Python client
Reads ATLAS_API_KEY and ATLAS_MODEL from .env in script directory.
"""

import os
from pathlib import Path
from openai import OpenAI

# =============================================================================
# Load .env from script directory (same pattern as 00_env.sh.example)
# =============================================================================
SCRIPT_DIR = Path(__file__).parent.resolve()
ENV_FILE = SCRIPT_DIR / ".env"

if ENV_FILE.exists():
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())

ATLAS_API_KEY = os.environ.get("ATLAS_API_KEY", "dummy-key")
MODEL = os.environ.get("ATLAS_MODEL_NAME", "qwen3.6-27b")

# =============================================================================
# CONFIGURATION
# =============================================================================
TEST_PROMPT_FILE = SCRIPT_DIR / "test" / "test_file_01_prompt.md"
OUTPUT_FILE = SCRIPT_DIR / "test" / "test_output_01.md"
URL = "http://localhost:8000/v1"

# =============================================================================
# VALIDATION
# =============================================================================
if not TEST_PROMPT_FILE.exists():
    print(f"Prompt file not found: {TEST_PROMPT_FILE}")
    print("   Creating a default prompt file for you...")
    TEST_PROMPT_FILE.parent.mkdir(parents=True, exist_ok=True)
    TEST_PROMPT_FILE.write_text(
        "Hello! Can you briefly explain the advantages of the Qwen3.6-27B dense FP8 model and its MTP speculative decoding?",
        encoding="utf-8",
    )

prompt = TEST_PROMPT_FILE.read_text(encoding="utf-8")

print(f"Sending request to Atlas server via OpenAI Python client")
print(f"   URL         : {URL}")
print(f"   Model       : {MODEL}")
print(f"   API Key     : {ATLAS_API_KEY[:4]}...{ATLAS_API_KEY[-4:]}")
print(f"   Prompt file : {TEST_PROMPT_FILE}")
print(f"   Output file : {OUTPUT_FILE}")
print("-" * 60)

# =============================================================================
# CLIENT SETUP
# =============================================================================
client = OpenAI(
    base_url=URL,
    api_key=ATLAS_API_KEY,
)

# =============================================================================
# SEND REQUEST
# =============================================================================
try:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )

    content = response.choices[0].message.content

    OUTPUT_FILE.write_text(content, encoding="utf-8")

    print(f"Success! Response saved to {OUTPUT_FILE}")
    print()
    print("Preview of response:")
    print("-" * 60)
    print(content[:600] + ("..." if len(content) > 600 else ""))
    print("-" * 60)

except Exception as e:
    print(f"Error: {e}")
    if hasattr(e, "response") and e.response is not None:
        print("Raw error response:", e.response.text)
