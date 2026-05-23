#!/bin/bash
echo "Pulling latest vLLM images via Docker Compose..."
docker compose -f docker-compose.yml pull
docker compose -f docker-compose02.yml pull
echo "Success: All images pulled."
