# e.g. output: ["vllm","serve"]
docker inspect vllm/vllm-openai:nightly --format '{{json .Config.Entrypoint}}'