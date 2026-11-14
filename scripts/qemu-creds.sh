#!/usr/bin/env bash
# Inject dev credentials into a built ix1 qcow2 so local QEMU verification
# can SSH in and log in at the greeter.
#
# bootc-image-builder does not apply manifest user `password`/`key` to
# bootc disks — the `ix1` account ships locked. This script mounts the
# root partition via qemu-nbd, writes the password hash + authorized_keys
# into the ostree deployment and stateroot home, and restores the SELinux
# labels the guest expects (shadow_t / ssh_home_t).
#
# Usage: scripts/qemu-creds.sh [output/qcow2/disk.qcow2]
# Requires: qemu-nbd, the nbd kernel module, sudo. Run with the VM stopped.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK="${1:-$REPO_ROOT/output/qcow2/disk.qcow2}"
NBD="${NBD:-/dev/nbd0}"
MNT="$(mktemp -d)"
HASH="${IX1_HASH:-\$6\$N2XZc0mIBsArNlXz\$t0teDYxBKul2FN74WdT1CsGBZp0waJlado4ComI2xU/iKPjOD2O2u4nwHzMIr1D8n8RjcWyPAUGLB0myJ8nh10}" # openssl passwd -6 ix1
KEY="${IX1_KEY:-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+qxJmk47YuYuESo2ItmvIJdHH/T6WawmOuKxGDe87i dev-qemu}"

CONNECTED=0
cleanup() {
  sudo umount "$MNT" 2>/dev/null || true
  if [[ $CONNECTED -eq 1 ]]; then
    sudo qemu-nbd --disconnect "$NBD" 2>/dev/null || true
  fi
  rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

sudo modprobe nbd max_part=8
NBD_SYSFS="/sys/block/$(basename "$NBD")/pid"
if [[ -s "$NBD_SYSFS" ]]; then
  echo "$NBD is already connected (pid $(cat "$NBD_SYSFS")) — refusing to use a device in use" >&2
  exit 1
fi
sudo qemu-nbd --connect="$NBD" "$DISK"
CONNECTED=1
sleep 2
sudo mount "${NBD}p4" "$MNT"

DEP="$(echo "$MNT"/ostree/deploy/default/deploy/*.0)"
HOME_DIR="$MNT/ostree/deploy/default/var/home/ix1"

sudo sed -i "s|^ix1:!:|ix1:${HASH}:|" "$DEP/etc/shadow"
sudo mkdir -p "$HOME_DIR/.ssh"
echo "$KEY" | sudo tee "$HOME_DIR/.ssh/authorized_keys" >/dev/null
sudo chown -R 1000:1000 "$HOME_DIR/.ssh"
sudo chmod 700 "$HOME_DIR/.ssh"
sudo chmod 600 "$HOME_DIR/.ssh/authorized_keys"

# New/rewritten files have no SELinux label; set the contexts sshd expects.
sudo python3 - "$DEP/etc/shadow" "$HOME_DIR/.ssh" "$HOME_DIR/.ssh/authorized_keys" <<'EOF'
import os, sys
os.setxattr(sys.argv[1], 'security.selinux', b'system_u:object_r:shadow_t:s0')
os.setxattr(sys.argv[2], 'security.selinux', b'system_u:object_r:ssh_home_t:s0')
os.setxattr(sys.argv[3], 'security.selinux', b'system_u:object_r:ssh_home_t:s0')
EOF

echo "Credentials injected into $DISK (ix1/ix1 + dev SSH key)"
