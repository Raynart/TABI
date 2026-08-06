#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Generate the smaller hero-image variants used by srcset.

Source images are ~1670px wide but card grids display them at roughly 400-850 CSS
px, so every card was downloading about four times the pixels it needed. This
writes an 800px-wide sibling for each image, which generate-pages.ps1 picks up
automatically via Get-ImageSrcset.

Idempotent: existing, up-to-date variants are skipped.

    python scripts/make-image-variants.py

Requires Pillow with WebP support.
"""
import glob
import os
import sys

from PIL import Image

TARGET_W = 800
QUALITY = 82
SUFFIX = '-%d.webp' % TARGET_W


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pattern = os.path.join(root, 'assets', 'images', '*.webp')

    made = skipped = 0
    orig_bytes = variant_bytes = 0

    for src in sorted(glob.glob(pattern)):
        if src.endswith(SUFFIX):
            continue
        dst = src[:-len('.webp')] + SUFFIX
        orig_bytes += os.path.getsize(src)

        if os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
            variant_bytes += os.path.getsize(dst)
            skipped += 1
            continue

        with Image.open(src) as im:
            if im.width <= TARGET_W:
                skipped += 1
                continue
            height = round(im.height * TARGET_W / im.width)
            resized = im.convert('RGB').resize((TARGET_W, height), Image.LANCZOS)
            resized.save(dst, 'WEBP', quality=QUALITY, method=6)

        variant_bytes += os.path.getsize(dst)
        made += 1

    print('variants written: %d, up to date: %d' % (made, skipped))
    if orig_bytes:
        print('originals %.1f MB -> %dw set %.1f MB (%.0f%%)'
              % (orig_bytes / 1e6, TARGET_W, variant_bytes / 1e6,
                 100 * variant_bytes / orig_bytes))
    return 0


if __name__ == '__main__':
    sys.exit(main())
