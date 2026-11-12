"""Convert the owner's background art to app-ready WebP (plan T37, SPEC §5.9).

    python tools/images/prepare_backgrounds.py

Inputs (not in git, see .gitignore): assets/images/*_bg_source.(png|jpg)
Outputs (in git): assets/images/menu_bg.webp, assets/images/splash_bg.webp
Width 1080 px (enough for phones at 3x on a 360 dp screen), quality 82.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

WIDTH = 1080
QUALITY = 82


def convert(src: Path, out: Path) -> None:
    im = Image.open(src).convert("RGB")
    h = round(im.height * WIDTH / im.width)
    im.resize((WIDTH, h), Image.LANCZOS).save(out, "WEBP", quality=QUALITY, method=6)
    print(f"{src.name} {im.size} -> {out.name} {(WIDTH, h)} {out.stat().st_size // 1024} KB")


def main() -> int:
    folder = Path("assets/images")
    found = 0
    for name in ("menu_bg", "splash_bg"):
        src = next(iter(sorted(folder.glob(f"{name}_source.*"))), None)
        if src is None:
            print(f"missing {name}_source.(png|jpg)")
            continue
        convert(src, folder / f"{name}.webp")
        found += 1
    return 0 if found == 2 else 1


if __name__ == "__main__":
    raise SystemExit(main())
