#!/usr/bin/env bash
set -euo pipefail

# Usage: launcher.sh <full-script-URL> <pubkey-or-path>
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <full-script-URL> <pubkey-or-path>" >&2
  echo "pubkey-or-path: either path to PEM file or the PEM text (quoted)" >&2
  exit 1
fi

SCRIPT_URL="$1"
PUBKEY_INPUT="$2"

# temp workspace
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

BASENAME="$(basename "$SCRIPT_URL")"
SCRIPT_PATH="$TMPDIR/$BASENAME"
SIG_PATH="$SCRIPT_PATH.sig"
PUBKEY_PATH="$TMPDIR/pub.pem"

# Resolve public key: if input is an existing file, copy it; otherwise treat input as PEM text
if [ -f "$PUBKEY_INPUT" ]; then
  cp -- "$PUBKEY_INPUT" "$PUBKEY_PATH"
else
  # write the provided string as PEM; ensure newlines are preserved if user passed a quoted multi-line string
  printf '%s\n' "$PUBKEY_INPUT" > "$PUBKEY_PATH"
fi

# download script and signature (signature expected at SCRIPT_URL + ".sig")
curl -fsSLo "$SCRIPT_PATH" "$SCRIPT_URL"
curl -fsSLo "$SIG_PATH"    "${SCRIPT_URL}.sig"

# ensure openssl exists
if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl not found" >&2
  exit 10
fi

# verify public key can be parsed
if ! openssl pkey -pubin -in "$PUBKEY_PATH" -text >/dev/null 2>&1; then
  echo "Error: OpenSSL cannot parse the provided public key (expect SubjectPublicKeyInfo PEM for Ed25519)" >&2
  exit 11
fi

# verify detached Ed25519 signature
if openssl pkeyutl -verify -pubin -inkey "$PUBKEY_PATH" -in "$SCRIPT_PATH" -sigfile "$SIG_PATH"; then
  echo "Signature OK"
  chmod +x "$SCRIPT_PATH"
  exec bash "$SCRIPT_PATH"
else
  echo "Signature verification FAILED" >&2
  exit 2
fi
