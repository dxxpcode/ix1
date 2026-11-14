# ix1 system updates (M7)

ix1 uses Fedora bootc atomic image updates. Operating-system updates
are a new deployment of the whole OS image; application updates are
Flatpak updates. The two are independent — see Settings → Updates and
the Software Center respectively.

## How an update flows

1. A new image is built, signed with the ix1 sigstore key, and pushed
   to the update registry (`scripts/push-image.sh`).
2. `bootc upgrade` fetches the new image. The containers policy
   (`/etc/containers/policy.json`) requires a valid ix1 signature for
   the update registry — an unsigned or wrongly-signed image is
   rejected before anything is staged.
3. The image is staged as a new bootloader entry. The running system
   is untouched until reboot.
4. On reboot the new deployment boots. The previous deployment stays
   installed as the rollback target.

## Manual commands

```sh
bootc upgrade --check    # check for a newer image, stage nothing
bootc upgrade            # download, verify signature, stage
bootc status             # booted / staged / rollback deployments
bootc rollback           # make the previous deployment default again
```

The Settings "Updates" page wraps these via `/usr/libexec/ix1-update`
through pkexec; active wheel users are authorized by
`/etc/polkit-1/rules.d/50-ix1-updates.rules`.

## Recovery

See `documentation/updates-and-recovery.md`. Summary: if a new
deployment fails, pick the previous entry in the GRUB menu or run
`bootc rollback`. There is no automatic health-based rollback in the
MVP.
