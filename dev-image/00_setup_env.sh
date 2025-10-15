#!/bin/bash

# Common environment setup for dev-image scripts
# This script sets up shared environment variables used across all scripts

set -e

# Container name - can be overridden with CONTAINER_NAME environment variable
CONTAINER_NAME=${CONTAINER_NAME:-dev-environment}

# Export for use in other scripts
export CONTAINER_NAME

echo "Environment setup complete:"
echo "  CONTAINER_NAME: ${CONTAINER_NAME}"
