# ix1 Milestone Acceptance Tests

Each milestone lists the test that must pass before it is "done".
Results are recorded in the PR/commit that claims completion.

## M0
- [ ] Architecture, plan, risks, and this test list exist in `documentation/`.
- [ ] Brand assets stored under `brand/` and referenced by branding docs.

## M1 — OS foundation
- [ ] `./scripts/build-image.sh` builds `localhost/ix1-os:dev`.
- [ ] Image passes `bootc container lint` during build.
- [ ] `podman image inspect` shows correct labels (title=ix1).

## M2 — Bootable system
- [ ] qcow2 disk image produced (via bootc-image-builder or equivalent).
- [ ] QEMU boots to systemd multi-user/graphical target on UEFI.
- [ ] `systemctl is-system-running` reaches `running` or `degraded` (documented).
- [ ] NetworkManager can obtain connectivity in QEMU user-mode net.
- [ ] SELinux status `enforcing` (or documented deviation).
- [ ] Serial log captured as evidence in `tests/boot/`.

## M3 — Installation (planned)
- [ ] Bootable installer ISO produced.
- [ ] Install to empty virtual disk completes unattended.
- [ ] Reboot into installed system; user account works.
- [ ] LUKS2 encryption path verified.

## M4 — Desktop environment (planned)
- [ ] Wayland session starts under KWin.
- [ ] Shell shows desktop, dock, launcher, panel, quick settings, notifications, lock screen.
- [ ] All shell components respond to input on QEMU and one physical machine.

## M5–M9
See product spec §10 acceptance statements; tests live under `tests/`.
