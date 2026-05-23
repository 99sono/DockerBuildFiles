#!/bin/bash
echo "Gracefully stopping PrismaQuant server..."
docker compose -f docker-compose02.yml down
echo "Container stopped."
