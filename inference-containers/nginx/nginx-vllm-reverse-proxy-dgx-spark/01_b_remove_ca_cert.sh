#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_NAME="vllm-selfsigned.crt"

echo "Removing certificate from Ubuntu CA trust store ..."
sudo rm -f /usr/local/share/ca-certificates/$CERT_NAME
sudo update-ca-certificates --fresh

echo ""
echo "Done. Certificate has been removed from the trust store."
echo "Restart your browser for changes to take effect."