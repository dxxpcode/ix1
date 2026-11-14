# ix1 Updates and Recovery

Tested on a QEMU clean install of the signed ix1 image (M7).

## Updating the OS

```sh
sudo bootc upgrade        # fetch, verify signature, stage
sudo systemctl reboot     # boot into the new deployment
```

Or graphically: Settings → Updates → Download Update → Restart.

Every pull of the ix1 image — the Anaconda install and every upgrade —
requires a valid sigstore signature made with the ix1 key
(`/etc/containers/policy.json` + `/etc/pki/containers/ix1.pub`). An
image with no signature or a bad signature is rejected:

```
ERROR Upgrading: ... A signature was required, but no signature exists
```

Operating-system updates are shown separately from Flatpak application
updates; apps update through the Software Center.

## Deployment retention

bootc keeps the previous deployment after every upgrade. `bootc
status` shows `booted` (running), `staged` (pending reboot), and
`rollback` (previous) deployments.

## Recovering a previous deployment

Two tested procedures — use whichever is reachable:

1. **In-system rollback** (system still boots):
   ```sh
   sudo bootc rollback
   sudo systemctl reboot
   ```
   The previous deployment becomes the boot default. Verified in QEMU:
   `bootc rollback` on the updated system, reboot, `bootc status`
   shows the old image booted again.

2. **Boot-menu fallback** (new deployment fails to boot): power on and
   press a key during the GRUB menu timeout to list boot entries, then
   select the older `ostree` entry. The previous deployment boots
   normally. After recovering, run `sudo bootc rollback` once so the
   good deployment stays the default.

There is **no automatic health-based rollback** in the MVP: boot
success is not health-checked, so a deployment that reaches GRUB but
fails later needs the manual procedures above.

## Failure scenarios verified

| scenario | result |
|----------|--------|
| Update image pushed without a signature | `bootc upgrade` rejects it; running system unaffected |
| Signed update staged and rebooted | new image boots; previous deployment retained |
| `bootc rollback` + reboot | previous deployment booted again |

Evidence: `tests/updates/evidence/`.
