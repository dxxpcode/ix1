#!/usr/bin/env bash
# Build the ix1 Anaconda installer container image.
# Requires localhost/ix1-os:dev (run scripts/build-image.sh first).
# Override IX1_INSTALL_IMAGE to change what Anaconda installs
# (e.g. a real registry ref for releases). IX1_TARGET_IMAGE overrides the
# image ref installed systems track for updates; it defaults to
# IX1_INSTALL_IMAGE with the transport prefix stripped (--target-imgref
# must be a plain ref; a registry: prefix breaks `bootc upgrade`).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="localhost/ix1-installer:dev"

INSTALL_IMG="${IX1_INSTALL_IMAGE:-registry:10.0.2.2:5000/ix1-os:dev}"
TARGET_IMG="${IX1_TARGET_IMAGE:-${INSTALL_IMG#registry:}}"
TARGET_IMG="${TARGET_IMG#docker://}"

podman build \
  --build-arg "IX1_OS_IMAGE=${IX1_OS_IMAGE:-localhost/ix1-os:dev}" \
  --build-arg "IX1_INSTALL_IMAGE=${INSTALL_IMG}" \
  --build-arg "IX1_TARGET_IMAGE=${TARGET_IMG}" \
  --file "$REPO_ROOT/distribution/installer/Containerfile" \
  --tag "$IMAGE" \
  "$REPO_ROOT"

echo "Built $IMAGE"
