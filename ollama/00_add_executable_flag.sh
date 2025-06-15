#!/bin/bash

# Get the directory where the script is located
SCRIPT_PATH="$(dirname "$(realpath "$0")")"

# Change the flag permissions of all scripts
chmod +x $SCRIPT_PATH/*.sh

# List the results
 ls --color=always -la $SCRIPT_PATH/*.sh 
