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
    if not src.exists():
        print(f"waiting for {src} (asset pending, plan T37)")
        return 1
    icon = Image.open(src).convert("RGBA")
    if icon.size != (1024, 1024):
        print(f"app_icon.png must be 1024x1024, got {icon.size}")
        return 1
    fg_path = root / "assets/icon/app_icon_foreground.png"
    fg = Image.open(fg_path).convert("RGBA") if fg_path.exists() else None

    written = android(root, icon, fg) + ios(root, icon)
    print(f"wrote {len(written)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
