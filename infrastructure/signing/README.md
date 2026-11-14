# ix1 image signing

Every ix1 OS image pushed to the update registry carries a sigstore
(cosign) signature. Installed systems verify it on every pull — the
Anaconda installer pull and `bootc upgrade` alike — through the
containers policy baked into the image:

- `distribution/bootc/files/etc/containers/policy.json` requires
  `sigstoreSigned` (matching repository identity) for the update
  registry prefixes. All other images keep the default accept policy.
- `distribution/bootc/files/etc/pki/containers/ix1.pub` is the public
  verification key, committed so it is part of every image.

## Key management

The private key never enters the repository. It lives on the signing
machine under `~/.local/share/ix1/signing/`:

| file      | contents                              | committed |
|-----------|---------------------------------------|-----------|
| ix1.key   | cosign private key (encrypted)        | never     |
| ix1.pass  | passphrase for the private key        | never     |
| ix1.pub   | public verification key               | yes       |

Generate or reuse it with:

```sh
./scripts/generate-signing-keys.sh
```

Rotating the keypair invalidates all existing signatures: rebuild the
image, re-push, and re-sign before rolling it out.

## Sign + push

```sh
./scripts/start-registry.sh          # dev registry on localhost:5000
./scripts/build-image.sh             # bakes policy.json + ix1.pub in
./scripts/push-image.sh              # podman push + cosign sign
```

Verify a signature manually:

```sh
cosign verify --key ~/.local/share/ix1/signing/ix1.pub \
    --allow-http-registry --allow-insecure-registry \
    localhost:5000/ix1-os:dev
```

`push-image.sh` pushes with plain `podman push` — never `sudo podman
push`. Rootful storage keeps a stale `localhost/ix1-os:dev` tag and
would silently ship an old OS.
