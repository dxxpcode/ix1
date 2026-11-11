#!/usr/bin/env bash
# Build the ix1 installer ISO (Anaconda) from the installer container image
# using osbuild image-builder (generic-iso).
#
# image-builder runs in rootful podman, but scripts/build-installer-image.sh
# builds rootless — so the image is exported and loaded into rootful storage
# first, otherwise a stale copy from an earlier build gets baked into the ISO.
#
# IX1_INSTALLER_IMAGE defaults to the locally built installer image.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IX1_INSTALLER_IMAGE:-localhost/ix1-installer:dev}"
OUT="$REPO_ROOT/output"
CLI="ghcr.io/osbuild/image-builder-cli:latest"

mkdir -p "$OUT"

# Sync the image into rootful storage for image-builder.
podman save "$IMAGE" | sudo podman load

# image-builder expects rootful storage; use sudo podman like build-disk-image.sh.
exec sudo podman run --rm \
  --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage:Z \
  -v "$OUT:/output" \
  "$CLI" build \
  --bootc-ref "$IMAGE" \
  --bootc-default-fs ext4 \
  --output-dir /output \
  generic-iso
