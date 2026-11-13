"""Cut Rick out of his API avatar for the 2.5D featured card.

    python3.12 -m venv tools/images/.venv
    tools/images/.venv/bin/pip install "rembg[cpu]" pillow requests
    tools/images/.venv/bin/python tools/images/cutout.py

Input:   https://rickandmortyapi.com/api/character/avatar/1.jpeg (300x300)
Outputs (in git):
    assets/featured/1.webp     RGBA cut-out, cropped to the top of the
                               character (the card anchors the head there)
    assets/featured/1_bg.webp  the full avatar (background layer, offline)

rembg (u2net) loses Rick's light-blue hair against the light background,
so its mask is joined with a soft-edged oval around the head and hair.
The first run downloads the u2net model (~170 MB) to ~/.u2net.
"""

from __future__ import annotations

import io
import sys
from pathlib import Path

import requests
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from rembg import new_session, remove

CHARACTER_ID = 1
AVATAR_URL = "https://rickandmortyapi.com/api/character/avatar/{id}.jpeg"
OUT_DIR = Path("assets/featured")
MODEL = "u2net"
QUALITY = 90

# Head + hair oval in avatar pixels (300x300), and its edge softness.
HEAD_OVAL = (58, 18, 272, 262)
FEATHER = 9


def fetch(character_id: int) -> Image.Image:
    response = requests.get(AVATAR_URL.format(id=character_id), timeout=15)
    response.raise_for_status()
    return Image.open(io.BytesIO(response.content)).convert("RGB")


def oval_mask(size: tuple[int, int]) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).ellipse(HEAD_OVAL, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(FEATHER))


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    avatar = fetch(CHARACTER_ID)
    body = remove(
        avatar,
        session=new_session(MODEL),
        only_mask=True,
        post_process_mask=True,
    ).convert("L")
    alpha = ImageChops.lighter(body, oval_mask(avatar.size))

    cutout = avatar.convert("RGBA")
    cutout.putalpha(alpha)
    top = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()[1]
    cutout = cutout.crop((0, top, avatar.width, avatar.height))

    out = OUT_DIR / f"{CHARACTER_ID}.webp"
    cutout.save(out, "WEBP", quality=QUALITY, method=6)
    bg = OUT_DIR / f"{CHARACTER_ID}_bg.webp"
    avatar.save(bg, "WEBP", quality=QUALITY, method=6)
    for path in (out, bg):
        print(f"{path} {Image.open(path).size} {path.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
