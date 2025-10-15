#!/bin/bash

# Script to ensure the external 'development-network' Docker network exists
# This enables communication between independent docker-compose projects

set -e

# Network name used across all development-related docker-compose files
NETWORK_NAME="development-network"

echo "=== Checking/Creating Development Network ==="
echo "Network: ${NETWORK_NAME}"

# Check if network already exists
if docker network ls --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$"; then
    echo "✅ Network '${NETWORK_NAME}' already exists."
else
    echo "📡 Creating external network '${NETWORK_NAME}'..."
    docker network create "${NETWORK_NAME}"
    echo "✅ Network '${NETWORK_NAME}' created successfully."
fi

echo ""
echo "Purpose of this script:"
echo "- Enables cross-communication between independent docker-compose projects"
echo "- Allows containers like dev-environment to reach ollama on http://ollama:11434"
echo "- Required because docker-compose prefixes networks with project names (e.g., 'dev-image_${NETWORK_NAME}')"
echo "- Using 'external: true' in compose files bypasses this limitation"
echo "- Safe to run multiple times - creates network only once"
echo ""

echo "📋 Usage Pattern:"
echo "  - Run this script before starting any development containers"
echo "  - All docker-compose files reference: networks: development-network: {external: true}"
echo "  - Future service folders should follow the same pattern"
echo ""

echo "🔍 To verify network:"
echo "  docker network inspect ${NETWORK_NAME}"
echo "  docker network ls | grep ${NETWORK_NAME}"
