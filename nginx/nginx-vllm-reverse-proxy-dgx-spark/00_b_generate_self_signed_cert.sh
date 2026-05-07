#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source .env if it exists (skip if not - user may have removed it)
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
fi

# Validate DGX_IP was replaced (not dummy placeholder)
if [[ -z "${DGX_IP:-}" || "$DGX_IP" == "[DGX_IP]" ]]; then
    echo "ERROR: DGX_IP is not set or still contains the placeholder value [DGX_IP]."
    echo "Open your .env file and set DGX_IP to your DGX Spark's actual static IP."
    echo "Then re-run this script."
    exit 1
fi

CERT_FILE="nginx-proxy/ssl/cert.pem"

if [[ ! -f "$CERT_FILE" ]]; then
    echo "ERROR: Certificate file not found at ${CERT_FILE}."
    echo "Run 00_b_generate_self_signed_cert.sh first."
    exit 1
fi

echo "Generating self-signed certificate for DGX_IP=${DGX_IP} ..."
mkdir -p nginx-proxy/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${CERT_FILE}" \
  -out "${CERT_FILE%.pem}.crt" \
  -subj "/C=US/ST=California/L=Santa Clara/O=NVIDIA Spark/CN=localhost" \
  -addext "subjectAltName = DNS:localhost, IP:127.0.0.1, IP:${DGX_IP}"

echo ""
echo "Certificate generated successfully:"
echo "  ${CERT_FILE}         (public certificate)"
echo "  ${CERT_FILE%.pem}.crt (certificate + key in one file)"
echo ""
echo "Next steps:"
echo "  1. Run: 01_install_ca_cert.sh  (to install in Ubuntu trust store)"
echo "  2. Run: 01_up.sh                (to start the reverse proxy)"
