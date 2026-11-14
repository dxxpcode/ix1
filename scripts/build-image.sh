#!/usr/bin/env bash
# Build the ix1 bootc container image locally with podman.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="localhost/ix1-os:dev"

podman build \
  --build-arg "IX1_RELEASE=${IX1_RELEASE:-dev}" \
  --file "$REPO_ROOT/distribution/bootc/Containerfile" \
  --tag "$IMAGE" \
  "$REPO_ROOT"

echo "Built $IMAGE"
