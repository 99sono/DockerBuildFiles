#!/bin/bash

# Script to add PATH export to ~/.bashrc in the dev container
# This ensures /home/developer/.local/bin is in PATH for all new shells

set -e

# Load common environment
source ./00_setup_env.sh || {
    echo "❌ Could not load environment setup. Make sure 00_setup_env.sh exists."
    exit 1
}

echo "=== Adding PATH export to ~/.bashrc in ${CONTAINER_NAME} ==="

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '${CONTAINER_NAME}' is not running."
    echo ""
    echo "To start the container, run:"
    echo "  ./02_start_dev.sh"
    exit 1
fi

echo "Adding PATH export to ~/.bashrc..."
docker exec --user root "${CONTAINER_NAME}" bash -c "
    echo 'Adding PATH export to ~/.bashrc...' &&
    echo 'export PATH=\"/home/developer/.local/bin:\$PATH\"' >> /home/developer/.bashrc &&
    echo 'PATH export added successfully!'
"

echo "✅ PATH export added to ~/.bashrc successfully!"
echo "The ~/.bashrc file now includes: export PATH=\"/home/developer/.local/bin:\$PATH\""
echo "This will ensure /home/developer/.local/bin is in PATH for all new shell sessions."
