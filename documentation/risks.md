# ix1 Risk Register

## High

1. **Installer architecture (M3).** Fedora bootc → user-friendly graphical
   ISO is the least-standard path. Options: Anaconda composer flow,
   `bootc-image-builder` ISO output, or live ISO + manual
   `bootc install`. Mitigation: validate on QEMU before committing; the
   spec explicitly says validate before choosing.
2. **bootc install/update path on real hardware.** Requires a reachable
   registry for updates; local/dev registry flow must be proven in M7.

## Medium

3. **NVIDIA proprietary drivers** — no packaged solution inside bootc;
   plan RPM Fusion + akmods or documented manual step; test hardware list
   must stay explicit.
4. **KWin + custom QML shell complexity** — KWin scripts/DBus APIs cover
   most shell needs; keep shell thin, reuse KDE components where license
   allows.
5. **SELinux enforcing + custom paths** — every custom file placement
   needs correct file contexts; build a `restorecon`/policy review step.

## Low

6. Registry bandwidth/size — Fedora base is ~2–4 GB layered; use
   registry mirrors/CDN where possible.
7. QEMU software rendering on CI — keep tests VM-only until hardware lab.

## Verified assumptions (2026-11)

- `quay.io/fedora/fedora-bootc` publishes tags for Fedora 41–46; using 43
  (current stable) for MVP stability.
- KVM is available on build VMs (`/dev/kvm` present).
