#!/usr/bin/env bash
# Boot the ix1 installer ISO in QEMU (UEFI, direct kernel boot of the ISO's
# pxeboot kernel/initrd so kernel args can be passed on the command line).
#
# Usage:
#   ./scripts/boot-installer-iso.sh [path-to.iso] [serial-log]
#
# With KS_URL set (e.g. http://10.0.2.2:8000/ks-qemu.cfg served from tests/installer/)
# Anaconda runs unattended; otherwise it starts in text mode.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$REPO_ROOT/output/ix1-installer.iso}"
SERIAL_LOG="${2:-/tmp/ix1-installer-serial.log}"
KS_URL="${KS_URL:-}"

OVMF_CODE="${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}"
OVMF_VARS="/tmp/ix1-installer_VARS.fd"
PXEBOOT_DIR="$REPO_ROOT/output/pxeboot"

cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OVMF_VARS"

# Extract the kernel and initrd from the ISO once (ISO contract: images/pxeboot).
if [ ! -f "$PXEBOOT_DIR/vmlinuz" ] || [ ! -f "$PXEBOOT_DIR/initrd.img" ]; then
  mkdir -p "$PXEBOOT_DIR"
  xorriso -osirrox on -indev "$ISO" \
    -extract /images/pxeboot/vmlinuz "$PXEBOOT_DIR/vmlinuz" \
    -extract /images/pxeboot/initrd.img "$PXEBOOT_DIR/initrd.img" >/dev/null
fi

# Fresh target disk for the install (qcow2, grows on demand).
TARGET_DISK="${TARGET_DISK:-$REPO_ROOT/output/installer-target.qcow2}"
mkdir -p "$(dirname "$TARGET_DISK")"
if [ ! -f "$TARGET_DISK" ]; then
  qemu-img create -f qcow2 "$TARGET_DISK" 32G
fi

APPEND="root=live:CDLABEL=ix1-Installer rd.live.image enforcing=0 console=ttyS0 inst.text"
[ -n "$KS_URL" ] && APPEND="root=live:CDLABEL=ix1-Installer rd.live.image enforcing=0 console=ttyS0 inst.ks=$KS_URL inst.text"

timeout "${BOOT_TIMEOUT:-2400}" qemu-system-x86_64 \
  -machine q35,accel=kvm:tcg \
  -cpu host \
  -m 6144 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  -drive file="$TARGET_DISK",if=virtio,format=qcow2,discard=unmap \
  -cdrom "$ISO" \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
  -device virtio-vga \
  -display none \
  -kernel "$PXEBOOT_DIR/vmlinuz" \
  -initrd "$PXEBOOT_DIR/initrd.img" \
  -append "$APPEND" \
  -serial "file:$SERIAL_LOG" \
  -no-reboot

echo "Serial log: $SERIAL_LOG"
