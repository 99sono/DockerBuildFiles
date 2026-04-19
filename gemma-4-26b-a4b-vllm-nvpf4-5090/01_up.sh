#!/bin/bash
echo "Starting Gemma-4 26B on RTX 5090..."
docker compose up -d
echo "------------------------------------------------"
echo "Server is initializing. Monitor progress with ./05_docker_logs.sh"
