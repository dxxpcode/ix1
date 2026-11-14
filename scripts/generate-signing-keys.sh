#!/usr/bin/env bash
# Generate the ix1 sigstore keypair used to sign OS images.
#
# The private key and passphrase stay on this machine under
# ~/.local/share/ix1/signing/ and are NEVER committed. The public key is
# copied into the bootc image context (distribution/bootc/files/etc/pki/
# containers/ix1.pub) so installed systems can verify image signatures via
# the containers policy. Regenerating the keypair invalidates signatures
# made with the old key — rebuild and re-sign all images if you rotate it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_DIR="${IX1_SIGNING_DIR:-$HOME/.local/share/ix1/signing}"
PUB_REPO="$REPO_ROOT/distribution/bootc/files/etc/pki/containers/ix1.pub"

mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/ix1.key" ]; then
    pass="$(head -c 24 /dev/urandom | base64 | tr -d '\n')"
    printf '%s' "$pass" > "$KEY_DIR/ix1.pass"
    chmod 600 "$KEY_DIR/ix1.pass"
    ( cd "$KEY_DIR" && COSIGN_PASSWORD="$pass" cosign generate-key-pair >/dev/null )
    mv "$KEY_DIR/cosign.key" "$KEY_DIR/ix1.key"
    mv "$KEY_DIR/cosign.pub" "$KEY_DIR/ix1.pub"
    echo "Generated signing keypair in $KEY_DIR"
else
    echo "Reusing existing signing keypair in $KEY_DIR"
fi

cp "$KEY_DIR/ix1.pub" "$PUB_REPO"
echo "Public key installed at ${PUB_REPO#"$REPO_ROOT"/}"
