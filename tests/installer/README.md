# Installer tests (M3)

Unattended QEMU validation of the ix1 Anaconda installer ISO.

## Prerequisites

- podman, qemu-system-x86_64, OVMF firmware, xorriso
- A local registry serving `ix1-os` (the image Anaconda installs):

  ```sh
  sudo podman run -d --name ix1-registry -p 5000:5000 docker.io/library/registry:2
  podman tag localhost/ix1-os:dev localhost:5000/ix1-os:dev
  podman push --tls-verify=false localhost:5000/ix1-os:dev
  ```

  The guest reaches the host's registry at `10.0.2.2:5000` (QEMU user-mode
  networking). `distribution/installer/files/containers/registries.conf.d/ix1-local.conf`
  marks that registry as insecure HTTP inside the installer image.

- A kickstart HTTP server (the guest fetches `inst.ks` over HTTP):

  ```sh
  cd tests/installer && python3 -m http.server 8000
  ```

## Building the ISO

```sh
./scripts/build-image.sh            # localhost/ix1-os:dev (Fedora 44 bootc base)
./scripts/build-installer-image.sh  # localhost/ix1-installer:dev
./scripts/build-installer-iso.sh    # output/*-generic-iso-x86_64.iso
```

## Running the unattended install

```sh
KS_URL=http://10.0.2.2:8000/ks-qemu.cfg \
TARGET_DISK=$PWD/output/installer-target.qcow2 \
BOOT_TIMEOUT=3000 \
./scripts/boot-installer-iso.sh output/<iso-name>.iso /tmp/ix1-installer-serial.log
```

Kickstarts:

- `ks-qemu.cfg` — plain autopart install.
- `ks-qemu-luks.cfg` — LUKS2-encrypted autopart (`--passphrase=ix1test`).

Both create user `ix1` (password `ix1`, wheel group) and install
`registry:10.0.2.2:5000/ix1-os:dev`. The `registry:` transport prefix is
required — `bootc install` rejects bare `host:port/...` refs.

## Booting the installed system

```sh
BOOT_TIMEOUT=600 ./scripts/boot-qemu.sh output/installer-target.qcow2 /tmp/ix1-installed.log
```

For LUKS2, boot with a serial socket and enter the passphrase when
systemd-cryptsetup prompts:

```sh
qemu-system-x86_64 ... -serial unix:/tmp/ix1-serial.sock,server=on,wait=off
# then connect to the socket and send the passphrase at the prompt
```

## Verified (2026-11, Fedora 44 base)

- Plain install: Anaconda bootc payload deploys the image, installs the
  bootloader, reboots; installed system reaches multi-user.target with
  SELinux `Enforcing`, hostname `ix1`, NetworkManager up; user `ix1` logs in.
- Graphical installer: Anaconda GUI (language selection) renders under
  QEMU/GTK.
- LUKS2: see milestone-tests.md M3 checklist.
