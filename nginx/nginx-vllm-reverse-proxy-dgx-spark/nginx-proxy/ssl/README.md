# SSL Certificate Files

## Auto-generated directory

This directory contains SSL certificate files generated automatically
by `00_b_generate_self_signed_cert.sh`. These files are **gitignored**
and should never be committed.

### Files

| File | Description |
|------|-------------|
| `cert.pem` | Public certificate (server cert + CA cert for self-signed) |
| `private.key` | Private key — keep secure |
| `ca.crt` | Optional CA bundle (created as a convenience) |

### Regenerating certificates

If you need to regenerate the certificates:
1. Delete all files in this directory
2. Run `00_b_generate_self_signed_cert.sh`
3. Run `01_install_ca_cert.sh` to update Ubuntu's trust store
