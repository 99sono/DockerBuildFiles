
# Web request to ollama
curl http://localhost:11434/api/generate -d '{
    "model": "gemma3:4b",
    "prompt": "Hi there.",
    "options": {
        "num_ctx": 8192
    }
}'
