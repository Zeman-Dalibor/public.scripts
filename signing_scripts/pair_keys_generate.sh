#!/bin/sh
set -eu

# generate-ed25519-key.sh
# Creates an Ed25519 private key and corresponding public key (PEM SubjectPublicKeyInfo)
# Outputs:
#   priv.pem - private key (PEM)
#   pub.pem  - public key (PEM)
#
# Usage:
#   ./generate-ed25519-key.sh [out-dir]
OUTDIR=${1:-.}

# ensure directory exists
mkdir -p "$OUTDIR"

PRIV="$OUTDIR/priv.pem"
PUB="$OUTDIR/pub.pem"

# prefer openssl; fail if not available
if ! command -v openssl >/dev/null 2>&1; then
  printf 'Error: openssl not found\n' >&2
  exit 1
fi

# generate private key (Ed25519) and public key
# OpenSSL 1.1.1+ / 3.x supports ed25519 via genpkey/pkey commands
openssl genpkey -algorithm ed25519 -out "$PRIV" || {
  printf 'Error: failed to generate private key\n' >&2
  rm -f "$PRIV"
  exit 2
}

# export public key in PEM SubjectPublicKeyInfo format
openssl pkey -in "$PRIV" -pubout -out "$PUB" || {
  printf 'Error: failed to write public key\n' >&2
  rm -f "$PRIV" "$PUB"
  exit 3
}

# set conservative permissions for private key
chmod 600 "$PRIV" || true

printf 'Private key: %s\nPublic key: %s\n' "$PRIV" "$PUB"
