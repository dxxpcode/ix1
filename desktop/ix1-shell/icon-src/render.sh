#!/bin/bash
# Render icon-src/*.svg to qml/assets/icons/*.png (2x via headless Chrome, then
# downsampled to 256px with Pillow).
set -e
cd "$(dirname "$0")"
out=../qml/assets/icons
tmp=$(mktemp -d)
for f in *.svg; do
    n=$(basename "$f" .svg)
    google-chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
        --window-size=256,256 --default-background-color=00000000 \
        --screenshot="$tmp/$n.png" "file://$PWD/$f" >/dev/null 2>&1
done
python3 - "$tmp" "$out" <<'PY'
import glob, os, sys
from PIL import Image
src, dst = sys.argv[1:]
for f in glob.glob(f"{src}/*.png"):
    Image.open(f).resize((256, 256), Image.LANCZOS).save(f"{dst}/{os.path.basename(f)}", optimize=True)
PY
rm -rf "$tmp"
