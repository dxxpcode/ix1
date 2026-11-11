#!/usr/bin/env bash
# Build the ix1 Anaconda installer container image.
# Requires localhost/ix1-os:dev (run scripts/build-image.sh first).
# Override IX1_INSTALL_IMAGE to change what Anaconda installs
# (e.g. a real registry ref for releases).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="localhost/ix1-installer:dev"

podman build \
  --build-arg "IX1_OS_IMAGE=${IX1_OS_IMAGE:-localhost/ix1-os:dev}" \
  --build-arg "IX1_INSTALL_IMAGE=${IX1_INSTALL_IMAGE:-registry:10.0.2.2:5000/ix1-os:dev}" \
  --file "$REPO_ROOT/distribution/installer/Containerfile" \
  --tag "$IMAGE" \
  "$REPO_ROOT"

echo "Built $IMAGE"
