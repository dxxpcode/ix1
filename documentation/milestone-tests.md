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

## M3 — Installation
- [x] Bootable installer ISO produced (`generic-iso` via osbuild image-builder).
- [x] Install to empty virtual disk completes unattended (Anaconda bootc payload).
- [x] Reboot into installed system; user account works (user `ix1`, wheel).
- [x] LUKS2 encryption path verified (autopart `--encrypted --luks-version=luks2`,
      passphrase unlock at boot, SELinux `Enforcing`).
- [x] Graphical installer UI verified (Anaconda language-selection screen in QEMU/GTK).
- Evidence: `tests/installer/evidence/` (serial logs).

Notes: the Anaconda `bootc` kickstart payload requires Fedora 44+; Fedora 43's
Anaconda falls back to a DNF package install (see `documentation/risks.md`).
Image refs need an explicit transport prefix (`registry:host:port/...`).

## M4 — Desktop environment (in progress)
- [x] Bootc image rebuilt with the fixed shell; pushed to the local registry.
- [x] Clean install via the Anaconda ISO to a fresh 32G disk (unattended kickstart):
      boots to `graphical.target`, SDDM active, SELinux `Enforcing`, user `ix1`.
- [x] Greeter login from the clean install reaches the ix1 desktop
      (wallpaper, panel, dock) — verified by QMP screendump.
- [x] Finding: Anaconda's bootc kickstart path does not create the user's home
      directory; the session then fails with exit code 3. Fixed in
      `tests/installer/ks-qemu.cfg` / `ks-qemu-luks.cfg` (`%post` creates
      `/home/ix1`). Interactive installs use Anaconda's standard user creation.
- [x] Wayland session starts under KWin (`kwin_wayland` + `ix1-shell`, SDDM login).
- [x] Desktop renders: wallpaper, top panel (brand, clock, tray), bottom dock (QEMU, 640x480).
- [x] Quick Settings opens from the tray and shows Wi-Fi/volume/brightness/power controls.
- [x] Power actions work (Power Off shuts the guest down cleanly).
- [x] Launcher opens from the panel brand click and lists desktop apps (QEMU).
- [x] Notifications display: `gdbus ... Notify` accepted by the shell's
      `org.freedesktop.Notifications` service and the card renders top-right (QEMU).
- [x] Lock screen renders (logo, clock, user, password field) and unlocks via PAM
      (`login` service) — Enter and Unlock button both work (QEMU).
- [ ] All shell components respond to input on one physical machine (QEMU done;
      no physical hardware available in this environment).
- Note: component interaction tests (launcher, notifications, lock, quick
  settings) were verified on an installed image with a bind-mounted shell
  binary; the clean-install re-verification above used the rebuilt image
  containing those fixes.

## M5–M9
See product spec §10 acceptance statements; tests live under `tests/`.
