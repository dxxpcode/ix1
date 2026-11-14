#!/usr/bin/env bash
# Start (or reuse) the local development container registry on :5000.
# QEMU guests reach it as 10.0.2.2:5000 (user-mode networking host address).
set -euo pipefail

# QEMU user-mode networking reaches the host as 10.0.2.2; give the host the
# same address on loopback so the registry (and image signatures made for
# 10.0.2.2:5000) is reachable under one name from both sides.
sudo ip addr add 10.0.2.2/32 dev lo 2>/dev/null || true

if podman ps --format '{{.Names}}' | grep -qx ix1-registry; then
    :
elif podman ps -a --format '{{.Names}}' | grep -qx ix1-registry; then
    podman start ix1-registry
else
    podman run -d --name ix1-registry -p 5000:5000 \
        docker.io/library/registry:2
fi

echo "Registry up: localhost:5000 (10.0.2.2:5000 from QEMU guests)"
