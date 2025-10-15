#!/bin/bash

# Script to install ping utilities in the dev container
# This is useful for testing network connectivity between containers

set -e

# Load common environment
source ./00_setup_env.sh || {
    echo "❌ Could not load environment setup. Make sure 00_setup_env.sh exists."
    exit 1
}

echo "=== Installing ping utilities in ${CONTAINER_NAME} ==="

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '${CONTAINER_NAME}' is not running."
    echo ""
    echo "To start the container, run:"
    echo "  ./02_start_dev.sh"
    exit 1
fi

echo "Installing iputils-ping package..."
docker exec --user root "${CONTAINER_NAME}" bash -c "
    echo 'Updating package lists...' &&
    apt update &&
    echo 'Installing iputils-ping...' &&
    apt install -y iputils-ping &&
    echo 'Installation complete!'
"

echo "✅ Ping utilities installed successfully!"
echo "You can now use 'ping' commands inside the container to test connectivity."
