# installer

The ix1 installer image is a bootable bootc ISO. On boot it drops straight
into `ix1-installer` — a fullscreen Qt6/QML app (`desktop/ix1-installer`)
styled after the ix1 landing page: pure-black zinc canvas, Geist type, three
steps (destination → account → deploy).

`anaconda` remains installed in the image for its dracut module and ISO
plumbing, but its UI is replaced on tty1: the
`anaconda-shell@tty1.service.d/ix1-installer.conf` drop-in runs
`/usr/bin/ix1-installer-run`, which launches the QML app on eglfs
(KMS/DRM, software rendering — no compositor, no display manager).

Install flow:

- **Destination** — disks are enumerated with `lsblk`; the booted/live disk
  is excluded. A LUKS toggle switches to the encrypted path.
- **Account** — full name, username, password (strength meter), plus a LUKS
  passphrase when encryption is on.
- **Deploy** — unencrypted installs run
  `bootc install to-disk <dev> --source-imgref X --target-imgref Y --wipe`;
  encrypted installs partition the disk (ESP + LUKS), then run
  `bootc install to-filesystem` with `rd.luks.name` kargs and write
  `crypttab` into each deployment. The user account is provisioned into the
  first deployment root via `useradd -R`/`chpasswd -R` (bootc creates no
  users). `reboot` finishes.

The source/target image references come from `/etc/ix1-install.conf`
(written at image build time from `IX1_INSTALL_IMAGE`/`IX1_TARGET_IMAGE`),
overridable with `IX1_INSTALL_SOURCE`/`IX1_INSTALL_TARGET`.

Verification knobs: `IX1_STEP=<0..2>` opens on a given step,
`IX1_DEMO=1` seeds fake disk rows, `IX1_SCREENSHOT=<path>` writes a PNG and
quits — together they render every screen headlessly
(`-platform offscreen`).
