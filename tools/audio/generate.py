"""Generate every Portal Cards sound from config.toml (SPEC §4.11, D5).

Usage (from the repo root):
    python tools/audio/generate.py            # write WAVs + CREDITS.md, print a table
    python tools/audio/generate.py --check    # also verify determinism, loops, peaks, size
    python tools/audio/generate.py --only coin hit

Dev-only tool: it never ships with the app; only its WAV output does.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import sys
import tomllib
import zlib
from pathlib import Path

import numpy as np
import scipy
from scipy.io import wavfile

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import music  # noqa: E402
import sfx  # noqa: E402
import synth  # noqa: E402

ROOT = HERE.parent.parent
CONFIG = HERE / "config.toml"

# What each file should sound like (for the listening review).
TARGETS = {
    "portal_charge": "Rising hiss + whooping FM tone, builds tension (shake / button).",
    "portal_open": "Downward zap + sub boom + sparkle tail (portal bursts open).",
    "card_flip": "Two quick paper-like swishes.",
    "rare_reveal": "Bright 4-note bell arpeggio (rare/epic flip).",
    "legendary_reveal": "Choir-like chord swell with shimmer (legendary flip).",
    "hit": "Short punchy thump + snap.",
    "crit_hit": "Hit + metallic ring.",
    "super_effective": "Three rising zaps, slight echo.",
    "faint": "Descending wobbly tone, fades out.",
    "victory": "Short major brass fanfare (original motif).",
    "defeat": "Slow minor descending brass, muffled.",
    "button_tap": "Tiny soft blip.",
    "coin": "Two-tone bright ping.",
    "genius_crit": "Rick's DAHI! crit: hit + rising synth + bright major stab.",
    "meeseeks_poof": "Soft cartoon smoke puff with a small pop.",
    "battle_loop": "136 BPM synthwave/chiptune arena loop, 16 bars, seamless.",
    "menu_loop": "90 BPM space mood, theremin-like gliding lead, 16 bars, seamless.",
    "legendary_sting": "4 s fanfare + swelling chord + shimmer (legendary music cue).",
}


def _rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(x ** 2)) + 1e-9)


def rng_for(seed: int, name: str) -> np.random.Generator:
    return np.random.default_rng([seed, zlib.crc32(name.encode())])


def render(cfg: dict, name: str) -> tuple[np.ndarray, int, bool]:
    """Returns (float samples, sample rate, is_loop)."""
    seed = int(cfg["seed"])
    if name in sfx.RECIPES:
        sr = int(cfg["rates"]["sfx"])
        x = sfx.RECIPES[name](cfg["sfx"][name], sr, rng_for(seed, name))
        return synth.normalize(x, cfg["levels"]["sfx_peak_db"]), sr, False
    sr = int(cfg["rates"]["music"])
    params = cfg["music"][name]
    x = music.PIECES[name](params, sr, rng_for(seed, name))
    levels = cfg["levels"]
    x = x * (10 ** (levels["music_rms_db"] / 20) / _rms(x))
    if np.max(np.abs(x)) > 10 ** (levels["music_peak_db"] / 20):
        x = synth.normalize(x, levels["music_peak_db"])
    return x, sr, bool(params.get("loop"))


def wav_bytes(x: np.ndarray, sr: int) -> bytes:
    buf = io.BytesIO()
    wavfile.write(buf, sr, synth.to_int16(x))
    return buf.getvalue()


def loop_join_ok(x: np.ndarray, sr: int) -> tuple[bool, str]:
    """Seamless loop check.

    1. The jump from the last to the first sample looks like any other step.
    2. The level change across the join matches the level change across the
       same musical point inside the loop (the middle bar line: 16 bars, so
       bar 9 starts at the half). A downbeat after a quiet last 16th is
       normal music; a mismatch with the inside of the loop is a seam.
    """
    steps = np.abs(np.diff(x))
    typical = float(np.percentile(steps, 99.9))
    jump = float(abs(x[0] - x[-1]))
    k = synth.samples(0.05, sr)
    join = _rms(x[:k]) / _rms(x[-k:])
    mid = x.size // 2
    inside = _rms(x[mid:mid + k]) / _rms(x[mid - k:mid])
    rel = join / inside
    ok = jump <= typical and 0.5 <= rel <= 2.0
    return ok, (f"jump {jump:.4f} (99.9% step {typical:.4f}), "
                f"level change at join {join:.2f} vs inside {inside:.2f}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--only", nargs="*")
    args = ap.parse_args()

    cfg = tomllib.loads(CONFIG.read_text(encoding="utf-8"))
    names = list(sfx.RECIPES) + list(music.PIECES)
    if args.only:
        names = [n for n in names if n in args.only]

    out_dirs = {"sfx": ROOT / cfg["output"]["sfx_dir"], "music": ROOT / cfg["output"]["music_dir"]}
    for d in out_dirs.values():
        d.mkdir(parents=True, exist_ok=True)

    failures: list[str] = []
    rows = []
    total = 0
    for name in names:
        x, sr, is_loop = render(cfg, name)
        data = wav_bytes(x, sr)
        kind = "sfx" if name in sfx.RECIPES else "music"
        path = out_dirs[kind] / f"{name}.wav"
        path.write_bytes(data)
        total += len(data)
        digest = hashlib.sha256(data).hexdigest()
        peak_db = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
        rows.append((name, kind, x.size / sr, len(data), sr, digest[:12], peak_db))

        if args.check:
            again = wav_bytes(render(cfg, name)[0], sr)
            if hashlib.sha256(again).hexdigest() != digest:
                failures.append(f"{name}: not deterministic")
            if peak_db > -0.99:
                failures.append(f"{name}: peak {peak_db:.2f} dBFS > -1 dBFS")
            if is_loop:
                ok, info = loop_join_ok(x, sr)
                print(f"  loop {name}: {'OK' if ok else 'FAIL'} ({info})")
                if not ok:
                    failures.append(f"{name}: loop join ({info})")

    print(f"\n{'name':18} {'kind':6} {'sec':>6} {'KB':>7} {'Hz':>6} {'peak':>6}  sha256")
    for name, kind, sec, size, sr, digest, peak in rows:
        print(f"{name:18} {kind:6} {sec:6.2f} {size / 1024:7.0f} {sr:6d} {peak:6.1f}  {digest}")
    mb = total / 1024 / 1024
    print(f"\ntotal {mb:.2f} MB (limit {cfg['output']['max_total_mb']} MB)")
    if mb > cfg["output"]["max_total_mb"]:
        failures.append(f"total {mb:.2f} MB over the limit")

    if not args.only:
        write_credits(cfg, rows)

    if failures:
        print("\nCHECK FAILED:\n  " + "\n  ".join(failures))
        return 1
    if args.check:
        print("\nchecks passed: deterministic, peaks <= -1 dBFS, loops seamless, size ok")
    return 0


def write_credits(cfg: dict, rows: list) -> None:
    lines = [
        "# Audio credits",
        "",
        "All sound effects and music in this folder are **procedurally generated by "
        "tools/audio** (Portal Cards, non-commercial fan project). No samples, stock "
        "libraries or recordings are used; melodies are original.",
        "",
        f"- Generator version: {cfg['version']}",
        f"- Seed: {cfg['seed']}",
        f"- numpy {np.__version__}, scipy {scipy.__version__}",
        "- Regenerate: `python tools/audio/generate.py` (edit `tools/audio/config.toml`)",
        "",
        "| File | Seconds | Sample rate | SHA-256 (first 12) |",
        "|---|---|---|---|",
    ]
    for name, kind, sec, size, sr, digest, _ in rows:
        lines.append(f"| {kind}/{name}.wav | {sec:.2f} | {sr} | `{digest}` |")
    (ROOT / cfg["output"]["credits"]).write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
