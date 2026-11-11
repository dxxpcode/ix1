#!/usr/bin/env bash
# Boot the ix1 qcow2 image in QEMU with UEFI and capture serial output.
# Requires: qemu-system-x86, OVMF firmware (qemu-efi-aarch64/ovmf package).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK="${1:-$REPO_ROOT/output/disk.qcow2}"
SERIAL_LOG="${2:-/tmp/ix1-serial.log}"

OVMF_CODE="${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}"
OVMF_VARS="${OVMF_VARS:-/tmp/ix1_VARS.fd}"
[ -f "$OVMF_CODE" ] || OVMF_CODE=/usr/share/qemu/OVMF.fd

# Fresh vars copy so the VM can write EFI vars.
cp "${OVMF_VARS%.fd}_VARS.fd" "$OVMF_VARS" 2>/dev/null || cp "$OVMF_CODE" /tmp/ivars.fd && mv /tmp/ivars.fd "$OVMF_VARS" 2>/dev/null || true
cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OVMF_VARS" 2>/dev/null || true

timeout "${BOOT_TIMEOUT:-300}" qemu-system-x86_64 \
  -machine q35,accel=kvm:tcg \
  -cpu host \
  -m 4096 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  -drive file="$DISK",if=virtio,format=qcow2 \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
  -device virtio-vga \
  -display none \
  -serial "file:$SERIAL_LOG" \
  -no-reboot

echo "Serial log: $SERIAL_LOG"
