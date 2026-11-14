# ix1 Technical Plan (M0–M2 done here; M3+ outlined)

## M0 — Product & technical specification

- Product: free Fedora-based desktop OS, x86-64, consumer audience.
- Foundation: Fedora bootc, Wayland/KWin, Qt6/QML shell, Flatpak apps,
  SELinux enforcing, LUKS2 optional, signed image updates.
- Repo: monorepo layout per spec §9.
- Brand: ix1 "X" mark — two official assets in `brand/` (light/dark).

## M1 — OS foundation

- `distribution/bootc/Containerfile` on `quay.io/fedora/fedora-bootc:44`.
- Packages: NetworkManager, PipeWire/WirePlumber, Mesa + video drivers,
  Flatpak + xdg-desktop-portal, SELinux, openssh, fonts.
- `scripts/build-image.sh` builds `localhost/ix1-os:dev` with podman.
- Branding: hostname `ix1`, OCI labels, logo assets.
- Acceptance: image builds reproducibly and passes `bootc container lint`.

## M2 — Bootable system

- Convert image to a qcow2 disk image via `bootc-image-builder`
  (containerized manifest build), or — if image-builder is impractical —
  run `bootc install to-disk` inside a privileged QEMU VM booted from the
  image itself.
- Validate in QEMU: UEFI boot, kernel, systemd default target, network
  (user-mode or bridged), Mesa/virtio-gpu or qxl graphics, SELinux status.
- Acceptance: boots reliably to a login/desktop-ready state in QEMU;
  documented test transcript.

## M3 — Installation (next phase)

- Preferred: Anaconda-based bootable ISO composed by
  `bootc-image-builder`/`osbuild-composer` supporting disk selection,
  LUKS2, user creation. Must validate the bootc install path on QEMU
  first; fallback is a live ISO + `bootc install to-disk` helper.

## M4 — Desktop environment (next phase)

- KWin session + custom Qt6/QML shell implementing spec §4.3 components.
- Design system from `brand/` marks; light/dark themes.

## M5 — Essential applications

- `ix1-settings` (Qt6/QML) + KDE apps and Firefox; live Graphite/Porcelain
  theme switching via `~/.config/ix1/settings.conf`.

## M6 — App ecosystem

- Flatpak + Flathub user remote in the session; `ix1-software-center`
  (Qt6/QML): discover, details/permissions, install/open/remove/update.

## M7 — Updates and recovery

- Sigstore (cosign) image signing; containers `policy.json` requires the
  ix1 signature for the update registry on installs and `bootc upgrade`.
- `bootc upgrade` staging, previous-deployment retention, `bootc rollback`
  and GRUB fallback documented in `documentation/updates-and-recovery.md`.
- Settings "Updates" page (OS vs Flatpak updates) via pkexec helper.

## M8+ — QA, distribution.

## Known limitations (current phase)

- Dev-only update registry (plain HTTP on localhost/QEMU); production
  needs TLS + release channel refs.
- No automatic health-based rollback (manual rollback/GRUB only).
- No Secure Boot signing, no hardware matrix yet.
