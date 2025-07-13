#!/bin/bash

# Get the directory where the script is located
SCRIPT_PATH="$(dirname "$(realpath "$0")")"

# Change the flag permissions of all scripts
chmod +x "$SCRIPT_PATH"/*.sh 2>/dev/null

# List the results
ls --color=always -la "$SCRIPT_PATH"/*.sh

# Check if any scripts failed to get executable permissions
if [ $? -ne 0 ]; then
    echo "Error: Failed to make all scripts executable" >&2
    exit 1
fi

echo "All scripts made executable successfully"
