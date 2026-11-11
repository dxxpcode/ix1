# ix1 Architecture

## Stack

| Layer | Choice |
|-------|--------|
| Base OS | Fedora 43 (`quay.io/fedora/fedora-bootc:43`) |
| Delivery | bootc OCI container image, atomic image updates |
| Init | systemd |
| Boot | UEFI (GRUB2 via bootc) |
| Display | Wayland |
| Compositor / WM | KWin |
| Shell | Custom Qt 6 / QML desktop shell |
| Graphics | Mesa (+ kernel drivers, nouveau, qxl for VMs) |
| Audio | PipeWire + WirePlumber (+ pipewire-pulse) |
| Network | NetworkManager (+ applet) |
| Bluetooth | BlueZ (later phase) |
| Apps | Flatpak + xdg-desktop-portal |
| MAC | SELinux (enforcing) |
| Encryption | LUKS2 (installer phase) |
| Firmware updates | fwupd (where supported) |
| Signing | cosign (image + checksum signing) |
| Testing | QEMU + libvirt for VM validation |

## System boundaries

- **distribution/** owns the bootc Containerfile, image definition,
  branding, release assets, and installer integration.
- **desktop/** owns the custom shell (Qt6/QML), dock, launcher, panel,
  notifications, settings UI, lock screen, and the shared design system.
- **applications/** owns first-party apps.
- **system/** owns OS-level glue: services, networking config, storage,
  security hardening, update integration.
- **platform/** owns portals/permissions integration.
- **infrastructure/** owns registry, signing, CI, website.

## Image pipeline

```
Containerfile -> podman build -> container image (OCI)
              -> bootc-image-builder -> qcow2/raw/ISO install media
              -> signed + checksummed -> release
```

Updates: systems deployed from the image pull newer signed container
images and stage deployments via `bootc upgrade`; the previous deployment
remains bootable for recovery.

## Deliberate non-goals for MVP

Custom kernel, custom Wayland compositor, custom graphics drivers,
Windows compatibility layer, ARM, cloud accounts, custom browser engine.
See the product spec §11.
