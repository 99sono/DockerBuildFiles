#!/usr/bin/env bash
set -euo pipefail

CERT_NAME="vllm-selfsigned.crt"
CERT_PATH="/usr/local/share/ca-certificates/$CERT_NAME"

echo "Checking if certificate is installed in Ubuntu CA trust store ..."
echo ""

if [[ -f "$CERT_PATH" ]]; then
    echo "✓ Certificate found: $CERT_PATH"
    echo ""
    echo "Certificate details:"
    openssl x509 -in "$CERT_PATH" -noout -subject -dates
    echo ""
    echo "The certificate is installed and active."
else
    echo "✗ Certificate NOT found: $CERT_PATH"
    echo ""
    echo "The certificate is not installed."
    echo "Run 01_a_install_ca_cert.sh to install it."
fi