#!/bin/bash
echo "Pulling latest vLLM images via Docker Compose..."
docker compose -f docker-compose.yml pull
docker compose -f docker-compose-turboquant.yml pull
echo "Success: Images pulled."
