#!/bin/bash
# Start the development environment using docker-compose

set -e

# Setup environment (this will source .env properly and check for its existence)
./00_setup_env.sh

# Ensure shared development network exists
echo "🔗 Ensuring shared development network exists..."
./../commonScripts/create_development_network.sh

# Start services
echo "🚀 Starting containers..."
docker-compose up -d
