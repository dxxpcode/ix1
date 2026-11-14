#!/usr/bin/env bash
# Build the ix1 installer ISO (Anaconda) from the installer container image
# using osbuild image-builder (generic-iso).
#
# image-builder runs in rootful podman, but its embedded podman cannot read the
# host's rootful storage database (podman version skew renames the DB away, so
# the image loaded via `podman save | sudo podman load` becomes invisible).
# Instead the installer image is pushed to the local dev registry and
# image-builder pulls it from there with --bootc-pull-container.
#
# IX1_INSTALLER_IMAGE defaults to the locally built installer image.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IX1_INSTALLER_IMAGE:-localhost/ix1-installer:dev}"
REGISTRY="${IX1_REGISTRY:-localhost:5000}"
OUT="$REPO_ROOT/output"
CLI="${IX1_IMAGE_BUILDER_CLI:-ghcr.io/osbuild/image-builder-cli:latest}"

mkdir -p "$OUT"

# Publish the installer image for image-builder to pull.
podman push --tls-verify=false "$IMAGE" "$REGISTRY/ix1-installer:dev"

# --network host so the container can reach the dev registry on localhost;
# registries.conf.d marks it insecure (plain HTTP) for the pull. The conf
# is generated here so the script works on a host with no prior
# /etc/containers provisioning.
REGCONF="$(mktemp)"
cat > "$REGCONF" <<'EOF'
[[registry]]
location = "localhost:5000"
insecure = true

[[registry]]
location = "10.0.2.2:5000"
insecure = true
EOF

status=0
sudo podman run --rm \
  --privileged \
  --security-opt label=type:unconfined_t \
  --network host \
  -v "$REGCONF:/etc/containers/registries.conf.d/ix1-dev.conf:Z" \
  -v "$OUT:/output" \
  "$CLI" build \
  --bootc-ref "$REGISTRY/ix1-installer:dev" \
  --bootc-pull-container \
  --bootc-default-fs ext4 \
  --output-dir /output \
  generic-iso || status=$?
rm -f "$REGCONF"
exit $status
