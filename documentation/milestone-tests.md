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

## M5 — Essential applications

Custom Settings app (`ix1-settings`, Qt6/QML) + integrated KDE apps and
Firefox, verified on a clean QEMU install of the rebuilt bootc image
(serial logs: `/tmp/ix1-m5-install3.log`, screenshots via QMP/GTK).

- [x] Clean install from ISO with M5 image (`registry:10.0.2.2:5000/ix1-os:dev`,
      digest `sha256:a4c63f52…`): `graphical.target`, SDDM greeter login,
      desktop renders.
- [x] `/home/ix1` exists on first boot (tmpfiles.d rule
      `usr/lib/tmpfiles.d/ix1-home.conf`; Anaconda's bootc kickstart payload
      does not create the user home directory).
- [x] Launcher lists Settings, Konsole, Dolphin, Kate, Plasma System Monitor,
      Firefox (`.desktop` entries discovered automatically).
- [x] Settings app opens from launcher; Appearance/Sound/Network pages render.
      Fixed during verification: missing `QtQuick.Controls` imports
      (`Slider is not a type`), missing `Q_INVOKABLE` on setters.
- [x] Theme switching is live and end-to-end: clicking "Porcelain" writes
      `~/.config/ix1/settings.conf`, the Settings window restyles itself and
      the shell (panel, dock, wallpaper) switches immediately via
      `QFileSystemWatcher`. Fixed during verification: the shell's watch was
      attached to `settings.conf` before the file existed (silently never
      fired); it now watches the config directory and re-arms the file watch.
- [x] Sound page binds to WirePlumber (`wpctl get/set-volume
      @DEFAULT_AUDIO_SINK@`); shows 0% on QEMU (no audio device).
- [x] Network page binds to NetworkManager (`nmcli` radio/Wi-Fi list/connect);
      shows toggle on + "No networks found" on QEMU (no Wi-Fi hardware).
- [x] Konsole: typed `echo M5KONSOLE_OK` in the guest, output returned —
      proves keyboard input reaches regular xdg-toplevel windows.
- [x] Firefox, Kate, Plasma System Monitor windows render (screenshots).
      Dolphin process runs with active KIO workers; its window was stacked
      behind Kate during capture.
- [ ] Theme persistence across logout/login (config read at shell startup) —
      not explicitly re-tested this round.
- [ ] Sound volume change with real audio hardware; Wi-Fi connect with real
      hardware — QEMU has neither.
- [ ] Physical-machine test (none available in this environment).

## UI polish pass (post-M5, pre-M6)

Goal: close the fidelity gap between the approved Graphite/Porcelain concept
images and the M4/M5 shell (frosted glass, real wallpaper art, custom IX1 app
icons, redesigned launcher/dock).

- [x] Aurora wallpaper artwork regenerated for both themes (dark charcoal with
      blue/teal waves; light off-white with pale blue/lavender waves).
- [x] Custom IX1 line-icon set (9 glyphs x dark/light variants) mapped from
      desktop-file/app names; replaces letter placeholders in launcher and dock.
- [x] Frosted-glass chrome: panel, dock, launcher card, quick-settings card and
      notification cards use translucent `Theme.glass` over the wallpaper.
- [x] Launcher redesigned: centered glass card, search field, 4-column icon
      grid with labels; backdrop dim + click/Escape to close.
- [x] Dock redesigned: floating pill with glass material, custom icons.
- [x] Quick Settings close bug found and fixed: the overlay window was only
      336px wide at the top-right, so clicks outside it never reached the shell
      and the tray toggle was covered; it is now a full-screen transparent
      overlay whose backdrop click closes the panel (Escape also works).
- [x] Verified on a clean QEMU install (ISO -> SDDM login -> desktop):
      aurora wallpaper both themes, glass panel/dock, launcher icon grid,
      quick-settings open/close via backdrop click (pixel-diff checked),
      Porcelain live theme switch via `settings.conf`.
- [ ] Frosted-glass blur is approximated with translucency (layer-shell-qt
      exposes no backdrop-blur property); true background blur not implemented.
- [ ] No physical-machine test (none available in this environment).

### Icon redesign (squircle tiles)

- [x] Custom IX1 squircle-tile icon set: 9 app icons, each a rounded-squircle
      tile with a per-app gradient and a white duotone line glyph (64x64 SVG).
      Replaces the earlier monochrome line-icon set.
- [x] Wired into `AppIcon.qml` (launcher + dock); icon sizes increased
      (dock 44px, launcher 52px) for the tile style.
- [x] Verified on a clean QEMU install in both themes: dock and launcher show
      the colorful tiles; launcher grid labels intact.
- [x] 4K verification: QEMU `virtio-gpu-pci` with EDID 3840x2160, KWin mode
      3840x2160@50 scale 2, QMP screendumps at native 3840x2160 — desktop,
      launcher and quick settings captured in Graphite and Porcelain.
      Note: `-device virtio-vga` plus the EDID device produced TWO GPUs and a
      split desktop; `-vga none -device virtio-gpu-pci,edid=on,xres=3840,yres=2160`
      gives a single 4K output.

## M6–M9
See product spec §10 acceptance statements; tests live under `tests/`.
