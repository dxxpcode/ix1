# ix1

ix1 is an independent, free, Fedora-based desktop operating system for x86-64.
It uses a custom Qt 6 / QML desktop shell over KWin (Wayland), image-based
atomic updates via Fedora bootc, Flatpak for third-party applications, and
SELinux enforcing by default.

This repository is the monorepo for the whole system: distribution, desktop
shell, first-party applications, system integration, infrastructure, and tests.

## Status

Early development. See `documentation/` for the product spec summary,
architecture, risks, and milestone acceptance criteria.

| Milestone | Status |
|-----------|--------|
| M0 Spec & technical plan | in progress |
| M1 OS foundation (bootc image) | in progress |
| M2 Bootable system in QEMU | in progress |
| M3 Installer | not started |
| M4 Desktop environment | not started |
| M5+ Apps, updates, distribution | not started |

## Repository layout

```
distribution/   bootc image, packages, branding, installer, release
desktop/        shell, dock, launcher, panel, settings, design system
applications/   first-party apps (file manager, software center, ...)
system/         boot, services, networking, storage, security, updates
platform/       portals, permissions, application integration
infrastructure/ registry, signing, CI, website
tests/          boot, installer, desktop, applications, security, hardware, updates
documentation/  specs, plans, ADRs
scripts/        build and test helpers
```

## Quick start

```bash
./scripts/build-image.sh     # build the bootc container image
```

Boot testing in QEMU: see `tests/boot/README.md` once M2 lands.
