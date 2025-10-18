#!/bin/bash

# Common environment setup for dev-image scripts
# This script sets up shared environment variables used across all scripts

set -e

# Function to source .env file properly
source_env_file() {
    if [ -f .env ]; then
        # Export only valid variable assignments (lines with = and not starting with #)
        export $(grep -v '^#' .env | grep '=' | xargs)
        echo "✅ Sourced environment variables from .env"
    else
        echo "⚠️  .env file not found"
        return 1
    fi
}

# Container name - can be overridden with CONTAINER_NAME environment variable
CONTAINER_NAME=${CONTAINER_NAME:-dev-environment}

# Export for use in other scripts
export CONTAINER_NAME

# Source .env file for all scripts that need it
source_env_file

echo "Environment setup complete:"
echo "  CONTAINER_NAME: ${CONTAINER_NAME}"
echo "  IMAGE_VERSION: ${IMAGE_VERSION:-1.0.0}"
echo "  SSH_HOST_PORT: ${SSH_HOST_PORT:-2222}"
