#!/bin/sh
set -eu

# simple-sign-recursive.sh
# Recursively sign regular files under a directory with an Ed25519 private key (PEM).
# Writes <file>.sig for each file. Simpler, more portable (not NUL-safe).
#
# Usage:
#   ./simple-sign-recursive.sh [--force] <private-key-pem> <directory>

usage() {
  printf 'Usage: %s [--force] <private-key-pem> <directory>\n' "$0" >&2
  exit 1
}

FORCE=0
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
fi

if [ "$1" = "--force" ]; then
  FORCE=1
  shift
fi

PRIV_KEY=$1
DIR=$2

if [ ! -f "$PRIV_KEY" ]; then
  printf 'Error: private key not found: %s\n' "$PRIV_KEY" >&2
  exit 2
fi

if [ ! -d "$DIR" ]; then
  printf 'Error: directory not found: %s\n' "$DIR" >&2
  exit 3
fi

if ! command -v openssl >/dev/null 2>&1; then
  printf 'Error: openssl not found\n' >&2
  exit 4
fi

if ! openssl pkey -in "$PRIV_KEY" -text >/dev/null 2>&1; then
  printf 'Error: cannot parse private key (expect Ed25519 PEM private key)\n' >&2
  exit 5
fi

# Iterate files (simple, not NUL-safe)
find "$DIR" -type f ! -name '*.sig' | while IFS= read -r file; do
  sigfile="${file}.sig"

  if [ -e "$sigfile" ] && [ "$FORCE" -ne 1 ]; then
    printf 'Skipping (sig exists): %s\n' "$file"
    continue
  fi

  if openssl pkeyutl -sign -inkey "$PRIV_KEY" -in "$file" -rawin -out "$sigfile"; then
    printf 'Signed: %s -> %s\n' "$file" "$sigfile"
    chmod 644 "$sigfile" >/dev/null 2>&1 || true
  else
    printf 'Error signing: %s\n' "$file" >&2
    rm -f "$sigfile" >/dev/null 2>&1 || true
  fi
done
