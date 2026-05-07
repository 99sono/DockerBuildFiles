#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="${SCRIPT_DIR}/nginx-proxy/ssl/cert.pem"

if [[ ! -f "$CERT_FILE" ]]; then
    echo "ERROR: ${CERT_FILE} not found."
    echo "Run 00_b_generate_self_signed_cert.sh first."
    exit 1
fi

echo "Installing certificate into Ubuntu CA trust store ..."
sudo cp "$CERT_FILE" /usr/local/share/ca-certificates/vllm-selfsigned.crt
sudo update-ca-certificates

echo ""
echo "Done. Ubuntu and browsers will now trust this certificate."
