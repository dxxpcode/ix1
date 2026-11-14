#!/usr/bin/env bash
# Publish an ix1 release to GitHub Releases.
#
#   ./scripts/publish-release.sh <version> <release-dir>
#
#   ./scripts/publish-release.sh 0.8.0 output/release-v0.8.0
#
# <release-dir> must contain:
#   ix1-<version>-x86_64.iso           the installer ISO
#   ix1-<version>-x86_64.iso.sha256    `sha256sum` output for the ISO
#   ix1-<version>-x86_64.iso.sig       cosign sign-blob signature
#   ix1.pub                            the cosign public key
#
# GitHub caps release assets at 2 GB, so the ISO is split into
# .partNN files (reassemble: `cat <iso>.part* > <iso>`).
#
# Requires `gh` authenticated with contents:write on the repo
# (Devin's app token cannot create releases — run locally).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:?usage: $0 <version> <release-dir>}"
DIR="${2:?usage: $0 <version> <release-dir>}"
REPO="dxxpcode/ix1"
TAG="v${VERSION}"
ISO="ix1-${VERSION}-x86_64.iso"

cd "$DIR"
for f in "$ISO" "$ISO.sha256" "$ISO.sig" ix1.pub; do
  [ -f "$f" ] || { echo "missing $f" >&2; exit 1; }
done

# Split the ISO into <2GB parts for the asset limit. Existing parts are
# reused only when they reassemble to exactly the ISO's size — parts left
# incomplete by an interrupted split must never be published.
ISO_SIZE="$(stat -c%s "$ISO")"
if ! ls "${ISO}".part* >/dev/null 2>&1 || \
   [ "$(cat "${ISO}".part* | wc -c)" != "$ISO_SIZE" ]; then
  rm -f "${ISO}".part*
  split -b 1900m -d "$ISO" "$ISO.part"
fi
ASSETS=( "${ISO}".part* "$ISO.sha256" "$ISO.sig" ix1.pub )
printf 'assets: %s\n' "${ASSETS[@]}"

# Tag at the release commit if it doesn't exist yet.
if ! git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  git -C "$REPO_ROOT" tag -a "$TAG" -m "ix1 ${VERSION} release"
fi
git -C "$REPO_ROOT" push origin "$TAG"

gh release create "$TAG" --repo "$REPO" --title "ix1 ${VERSION}" \
  --notes-file - "${ASSETS[@]}" <<NOTES
See the release notes on the ix1 website and \`documentation/\`.
Assemble the ISO: \`cat ${ISO}.part* > ${ISO}\`, then verify
\`sha256sum -c ${ISO}.sha256\` and
\`cosign verify-blob --key ix1.pub --signature ${ISO}.sig ${ISO}\`.
NOTES
