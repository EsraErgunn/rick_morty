"""Generate Android and iOS launcher icons from one 1024 px PNG (plan T37).

Dev-only tool (Pillow). No Flutter package is needed.

Usage (from the repo root, once assets/icon/app_icon.png exists):
    python tools/icon/generate_icons.py
    python tools/icon/generate_icons.py --root <copy of the repo>   # try it out

Inputs:
    assets/icon/app_icon.png             1024x1024, required (full icon)
    assets/icon/app_icon_foreground.png  optional: Android adaptive foreground
                                         (subject inside the middle 66 %)
Outputs:
    android/app/src/main/res/mipmap-*/ic_launcher.png
    android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (+ adaptive xml)
    ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (sizes from Contents.json)
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

VOID = (0x15, 0x11, 0x2B)  # AppColors.voidBase: icon background

ANDROID_LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ANDROID_ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#15112B</color>
</resources>
"""


def flatten(img: Image.Image) -> Image.Image:
    """iOS icons must not have alpha: put the icon on the void color."""
    base = Image.new("RGB", img.size, VOID)
    base.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
    return base


# Adaptive icons are masked (often a circle with 66 % of the size visible):
# shrink the subject so the card's corners stay inside that safe zone.
FOREGROUND_SCALE = 0.8


def shrink(img: Image.Image, scale: float) -> Image.Image:
    small = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
    canvas.paste(small, ((img.width - small.width) // 2, (img.height - small.height) // 2), small)
    return canvas


def square(img: Image.Image) -> Image.Image:
    side = min(img.size)
    left = (img.width - side) // 2
    top = (img.height - side) // 2
    return img.crop((left, top, left + side, top + side))


def key_background(img: Image.Image, tolerance: int = 10) -> Image.Image:
    """Transparent where the pixel is close to the corner (background) color;
    soft edge over [tolerance, 2 x tolerance]."""
    rgba = img.convert("RGBA")
    bg = rgba.getpixel((4, 4))[:3]
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            d = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
            if d < tolerance:
                px[x, y] = (r, g, b, 0)
            elif d < 2 * tolerance:
                px[x, y] = (r, g, b, a * (d - tolerance) // tolerance)
    return rgba


def resized(img: Image.Image, px: int) -> Image.Image:
    return img.resize((px, px), Image.LANCZOS)


def android(root: Path, icon: Image.Image, fg: Image.Image | None) -> list[Path]:
    res = root / "android/app/src/main/res"
    written = []
    for density, px in ANDROID_LEGACY.items():
        out = res / f"mipmap-{density}" / "ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        resized(icon, px).save(out)
        written.append(out)
    if fg is not None:
        for density, px in ANDROID_ADAPTIVE.items():
            out = res / f"mipmap-{density}" / "ic_launcher_foreground.png"
            resized(fg, px).save(out)
            written.append(out)
        anydpi = res / "mipmap-anydpi-v26"
        anydpi.mkdir(parents=True, exist_ok=True)
        (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML, encoding="utf-8", newline="\n")
        values = res / "values"
        values.mkdir(parents=True, exist_ok=True)
        (values / "ic_launcher_background.xml").write_text(COLORS_XML, encoding="utf-8", newline="\n")
        written += [anydpi / "ic_launcher.xml", values / "ic_launcher_background.xml"]
    return written


def ios(root: Path, icon: Image.Image) -> list[Path]:
    folder = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((folder / "Contents.json").read_text(encoding="utf-8"))
    flat = flatten(icon)
    written = []
    for entry in contents["images"]:
        name = entry.get("filename")
        if not name:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        out = folder / name
        resized(flat, round(points * scale)).save(out)
        written.append(out)
    return written


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="repo root (default: current dir)")
    args = ap.parse_args()
    root = Path(args.root)

    src = root / "assets/icon/app_icon.png"
    source = next(iter(sorted((root / "assets/icon").glob("icon_source.*"))), None)
    if src.exists():
        icon = Image.open(src).convert("RGBA")
        fg_path = root / "assets/icon/app_icon_foreground.png"
        fg = Image.open(fg_path).convert("RGBA") if fg_path.exists() else None
    elif source is not None:
        # Owner art on a dark background: square crop, 1024 px, and an
        # adaptive foreground with that background keyed out.
        icon = square(Image.open(source).convert("RGBA")).resize((1024, 1024), Image.LANCZOS)
        fg = shrink(key_background(icon), FOREGROUND_SCALE)
    else:
        print(f"waiting for {src} or icon_source.* (asset pending, plan T37)")
        return 1
    if icon.size != (1024, 1024):
        print(f"app_icon.png must be 1024x1024, got {icon.size}")
        return 1

    written = android(root, icon, fg) + ios(root, icon)
    print(f"wrote {len(written)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
