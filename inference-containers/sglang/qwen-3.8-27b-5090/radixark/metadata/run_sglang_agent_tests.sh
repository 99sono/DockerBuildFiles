#!/bin/bash
# Run the SGLang "agent" test suite against the running server.
# Each test_NN_* folder contains challenge.md; the model's answer is written
# to answer.md in the same folder.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$ROOT_DIR" || exit 1
source ../../../commonScripts/lib.sh
load_env
# Ensure the host-side conda env is active so the openai client is importable.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testSGLangQwen

if [ -z "$INFERENCE_SERVER_URL" ]; then
    echo "INFERENCE_SERVER_URL not set in .env" >&2
    exit 1
fi

TESTS_DIR="$SCRIPT_DIR/sglang_agent_tests_2026_08_17"
API_KEY="${INFERENCE_API_KEY:-dummy-key}"
MODEL="${INFERENCE_MODEL_ALIAS:-qwen3.8-27b-nvfp4}"
TEMP="${INFERENCE_TEMP:-0.2}"
MAX_TOKENS="${INFERENCE_MAX_TOKENS:-12000}"

echo "Server: $INFERENCE_SERVER_URL  model: $MODEL  temp: $TEMP  max_tokens: $MAX_TOKENS"
echo "Tests dir: $TESTS_DIR"
echo

for dir in "$TESTS_DIR"/test_*; do
    name="$(basename "$dir")"
    challenge="$dir/challenge.md"
    answer="$dir/answer.md"
    if [ ! -f "$challenge" ]; then
        echo "[$name] SKIP - no challenge.md"
        continue
    fi
    echo "[$name] sending challenge ($(wc -c < "$challenge") bytes) ..."
    python3 - "$challenge" "$answer" "$MODEL" "$API_KEY" "$INFERENCE_SERVER_URL" "$TEMP" "$MAX_TOKENS" <<'PYEOF'
import os, sys, time
from pathlib import Path
from openai import OpenAI

challenge, answer, model, api_key, url, temp, max_tokens = sys.argv[1:]
client = OpenAI(base_url=url, api_key=api_key)
prompt = Path(challenge).read_text()
t0 = time.time()
resp = client.chat.completions.create(
    model=model,
    messages=[{"role": "user", "content": prompt}],
    temperature=float(temp),
    top_p=0.95,
    max_tokens=int(max_tokens),
)
dt = time.time() - t0
content = resp.choices[0].message.content or ""
Path(answer).write_text(content)
u = resp.usage
print(f"[{Path(challenge).parent.name}] done in {dt:.1f}s | prompt={u.prompt_tokens} out={u.completion_tokens} -> {answer}")
PYEOF
    rc=$?
    [ $rc -ne 0 ] && echo "[$name] ERROR rc=$rc"
    echo
done