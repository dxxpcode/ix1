#!/usr/bin/env bash
# Push the locally built ix1 OS image to the dev registry and sign it with
# the ix1 sigstore key. The installed system's containers policy
# (/etc/containers/policy.json) requires a valid ix1 signature on every
# pull of the ix1 image — Anaconda installs and `bootc upgrade` alike.
#
# Key material stays outside the repo (see infrastructure/signing/README.md):
#   ~/.local/share/ix1/signing/ix1.key   private key (encrypted)
#   ~/.local/share/ix1/signing/ix1.pass  key passphrase
#   ~/.local/share/ix1/signing/ix1.pub   public key (committed into the image)
#
# Overrides: IX1_IMAGE, IX1_REGISTRY, IX1_SIGNING_KEY, IX1_SIGNING_PASSWORD.
# Use plain `podman push` — never `sudo podman push`: rootful storage holds
# a stale image tag and silently pushes the wrong OS.
set -euo pipefail

IMAGE="${IX1_IMAGE:-localhost/ix1-os:dev}"
REGISTRY="${IX1_REGISTRY:-localhost:5000}"
KEY="${IX1_SIGNING_KEY:-$HOME/.local/share/ix1/signing/ix1.key}"
PASS_FILE="$(dirname "$KEY")/ix1.pass"

if [ ! -f "$KEY" ]; then
    echo "missing signing key: $KEY — run scripts/generate-signing-keys.sh" >&2
    exit 1
fi
if [ -z "${IX1_SIGNING_PASSWORD:-}" ] && [ ! -f "$PASS_FILE" ]; then
    echo "missing key passphrase: set IX1_SIGNING_PASSWORD or create $PASS_FILE" >&2
    exit 1
fi

# Push under both names: localhost:5000 (host-side pulls) and
# 10.0.2.2:5000 (the ref QEMU guests install/upgrade from). Signatures are
# recorded per-repository-name, so both refs must be signed for the
# containers policy's matchRepository check to pass on each side.
# 10.0.2.2 is bound to loopback by scripts/start-registry.sh.
podman push --tls-verify=false "$IMAGE" "$REGISTRY/ix1-os:dev"
podman push --tls-verify=false "$IMAGE" 10.0.2.2:5000/ix1-os:dev

# Sign with cosign v2 (the `cosign2` binary): the installed system's
# containers-image verifier only reads `sha256-<digest>.sig` tag signatures,
# which cosign v3 no longer writes (it emits OCI 1.1 referrers instead).
COSIGN="${COSIGN_BIN:-cosign2}"
command -v "$COSIGN" >/dev/null || { echo "missing $COSIGN (cosign v2) on PATH" >&2; exit 1; }

export COSIGN_PASSWORD="${IX1_SIGNING_PASSWORD:-$(cat "$PASS_FILE")}"
"$COSIGN" sign --yes --key "$KEY" --tlog-upload=false \
    --allow-http-registry --allow-insecure-registry "$REGISTRY/ix1-os:dev"
"$COSIGN" sign --yes --key "$KEY" --tlog-upload=false \
    --allow-http-registry --allow-insecure-registry 10.0.2.2:5000/ix1-os:dev

echo "Pushed and signed $REGISTRY/ix1-os:dev and 10.0.2.2:5000/ix1-os:dev"
