# Simple script to make two sequential API calls to the VLLM server

# First curl: Retrieve a brief explanation of transformers
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-cascade-2-nvfp4",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain transformers."}
    ]
  }'

# Second curl: Retrieve an explanation that also covers attention mechanisms
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-cascade-2-nvfp4",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain transformers and attention."}
    ]
  }'