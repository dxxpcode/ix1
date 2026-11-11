#!/usr/bin/env bash
# Build a bootable qcow2 disk image from the locally built ix1 image
# using bootc-image-builder (runs containerized; requires podman).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="localhost/ix1-os:dev"
OUT="$REPO_ROOT/output"
BIB="quay.io/centos-bootc/bootc-image-builder:latest"

mkdir -p "$OUT"

sudo podman run --rm \
  --privileged \
  --security-opt label=type:unconfined_t \
  -v "$OUT:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage:Z \
  -v "$REPO_ROOT/distribution/image/manifest.toml:/manifest.toml:ro" \
  "$BIB" \
  --type qcow2 \
  --rootfs ext4 \
  --local \
  --config /manifest.toml \
  "$IMAGE"

echo "Disk image written under $OUT"
ls -lh "$OUT"
