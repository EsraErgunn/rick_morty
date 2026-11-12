"""Sound-effect recipes. Each takes (params, sr, rng) and returns a float array."""

from __future__ import annotations

from typing import Callable

import numpy as np

import synth as s

Recipe = Callable[[dict, int, np.random.Generator], np.ndarray]


def portal_charge(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    swell = s.ramp(0.0, 1.0, n) ** 1.6
    hiss = s.sweep(s.noise(n, rng), s.ramp(p["noise_from"], p["noise_to"], n, "exp"),
                   sr, kind="band", width=0.5)
    vib = 1.0 + 0.04 * s.sine(s.ramp(5.0, 14.0, n), n, sr)
    whoop_f = s.ramp(p["whoop_from"], p["whoop_to"], n, "exp") * vib
    whoop = s.fm(whoop_f, 2.0, s.ramp(0.5, 3.0, n), n, sr)
    sparkle = np.zeros(n)
    for i in range(10):
        at = int(n * (0.35 + 0.6 * i / 10))
        f = 2200.0 + 3000.0 * rng.random()
        k = s.samples(0.05, sr)
        s.place(sparkle, s.sine(f, k, sr) * s.decay(k, sr, 0.015), at, 0.25)
    out = (0.9 * hiss + 0.45 * whoop) * swell + sparkle * swell
    return s.fade(s.reverb(out, sr, 0.5, 0.2), sr, 0.01, 0.03)


def portal_open(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    nz = s.samples(p["zap_time"], sr)
    zap = s.saw(s.ramp(p["zap_from"], p["zap_to"], nz, "exp"), nz, sr)
    zap = s.sweep(zap, s.ramp(9000.0, 400.0, nz, "exp"), sr) * s.decay(nz, sr, 0.18)
    boom_n = s.samples(0.9, sr)
    boom = s.sine(s.ramp(p["boom_from"], p["boom_to"], boom_n, "exp"), boom_n, sr)
    boom *= s.decay(boom_n, sr, 0.35)
    burst_n = s.samples(0.4, sr)
    burst = s.highpass(s.noise(burst_n, rng), 1500.0, sr) * s.decay(burst_n, sr, 0.09)
    out = np.zeros(n)
    s.place(out, zap, 0, 0.8)
    s.place(out, s.drive(boom, 2.0), 0, 0.9)
    s.place(out, burst, 0, 0.7)
    for _ in range(int(p["sparkles"])):
        at = s.samples(0.15 + 1.0 * rng.random(), sr)
        k = s.samples(0.12, sr)
        f = 2500.0 + 4000.0 * rng.random()
        s.place(out, s.sine(f, k, sr) * s.decay(k, sr, 0.04), at, 0.18)
    return s.fade(s.reverb(out, sr, 0.9, 0.3), sr, 0.002, 0.08)


def card_flip(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = np.zeros(n)
    for at, gain, f in ((0.0, 1.0, 1.0), (0.09, 0.7, 1.25)):
        k = s.samples(0.09, sr)
        swish = s.bandpass(s.noise(k, rng), p["low"] * f, p["high"], sr)
        env = np.sin(np.linspace(0.0, np.pi, k)) ** 2
        s.place(out, swish * env, s.samples(at, sr), gain)
    return s.fade(out, sr)


def rare_reveal(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = np.zeros(n)
    for i, note in enumerate(p["notes"]):
        k = s.samples(0.8, sr)
        bell = s.fm(s.hz(note), 3.5, s.ramp(2.5, 0.2, k), k, sr) * s.decay(k, sr, 0.28)
        s.place(out, bell, s.samples(i * p["step"], sr), 0.5)
    return s.fade(s.reverb(out, sr, 0.8, 0.3), sr, 0.002, 0.1)


def legendary_reveal(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    voices = np.zeros(n)
    for note in p["chord"]:
        f = s.hz(note)
        for detune in (-0.006, 0.0, 0.007):
            voices += s.saw(f * (1 + detune), n, sr, phase0=rng.random())
    choir = s.formants(voices / 6.0, sr, [700.0, 1220.0, 2600.0], [1.0, 0.6, 0.25])
    env = s.adsr(n, sr, p["swell"], 0.3, 0.8, 0.9)
    shimmer = np.zeros(n)
    for f in (2637.0, 3136.0, 3951.0):
        shimmer += s.sine(f, n, sr) * (0.5 + 0.5 * s.sine(6.0 + f / 1000, n, sr))
    shimmer *= s.adsr(n, sr, 0.6, 0.4, 0.6, 1.0) * 0.06
    out = s.drive(choir * env * 2.2, 1.3) + shimmer
    return s.fade(s.reverb(out, sr, 1.0, 0.35), sr, 0.01, 0.2)


def _hit_core(sr: int, rng: np.random.Generator, n: int, thump_from: float,
              thump_to: float) -> np.ndarray:
    kn = s.samples(0.28, sr)
    thump = s.sine(s.ramp(thump_from, thump_to, kn, "exp"), kn, sr) * s.decay(kn, sr, 0.08)
    sn = s.samples(0.12, sr)
    snap = s.lowpass(s.noise(sn, rng), 2400.0, sr) * s.decay(sn, sr, 0.025)
    out = np.zeros(n)
    s.place(out, thump, 0, 1.0)
    s.place(out, snap, 0, 1.4)
    return s.drive(out, 2.2)


def hit(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    return s.fade(_hit_core(sr, rng, n, p["thump_from"], p["thump_to"]), sr)


def _ring(sr: int, n: int, base: float) -> np.ndarray:
    ring = np.zeros(n)
    for ratio, gain in ((1.0, 1.0), (2.76, 0.6), (5.40, 0.35), (8.93, 0.2)):
        ring += gain * s.sine(base * ratio, n, sr) * s.decay(n, sr, 0.22 / ratio ** 0.3)
    return ring


def crit_hit(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = _hit_core(sr, rng, n, 230.0, 45.0) + 0.3 * _ring(sr, n, p["ring"])
    return s.fade(s.reverb(out, sr, 0.6, 0.18), sr)


def super_effective(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = np.zeros(n)
    for i, note in enumerate(p["notes"]):
        k = s.samples(p["step"] * 1.4, sr)
        f = s.hz(note) * s.ramp(0.92, 1.04, k)
        zap = s.square(f, k, sr, duty=0.3) * s.decay(k, sr, 0.08)
        s.place(out, s.lowpass(zap, 5000.0, sr), s.samples(i * p["step"], sr), 0.45)
    return s.fade(s.echo(out, sr, 0.09, 0.3, 0.25), sr)


def faint(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    wob = 1.0 + 0.06 * s.sine(p["wobble"], n, sr)
    f = s.ramp(p["from"], p["to"], n, "exp") * wob
    tone = 0.6 * s.triangle(f, n, sr) + 0.4 * s.lowpass(s.saw(f, n, sr), 1800.0, sr)
    return s.fade(tone * s.adsr(n, sr, 0.01, 0.2, 0.7, 0.45), sr)


def _brass(note: str, seconds: float, sr: int, rng: np.random.Generator) -> np.ndarray:
    k = s.samples(seconds, sr)
    f = s.hz(note)
    v = s.saw(f, k, sr, rng.random()) + s.saw(f * 1.004, k, sr, rng.random())
    v = s.sweep(v, s.ramp(800.0, 3800.0, k, "exp") ** 1.0, sr)
    return v * s.adsr(k, sr, 0.03, 0.15, 0.7, min(0.2, seconds * 0.4)) * 0.5


def _score(p: dict, sr: int, rng: np.random.Generator, n: int) -> np.ndarray:
    beat = 60.0 / p["tempo"]
    out = np.zeros(n)
    for note, start, length in p["notes"]:
        s.place(out, _brass(note, length * beat, sr, rng), s.samples(start * beat, sr), 0.5)
    return out


def victory(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    return s.fade(s.reverb(_score(p, sr, rng, n), sr, 0.8, 0.25), sr, 0.003, 0.15)


def defeat(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    sad = _score(p, sr, rng, n)
    sad = s.lowpass(sad, 1500.0, sr) * (1.0 + 0.08 * s.sine(5.0, n, sr))
    return s.fade(s.reverb(sad, sr, 0.8, 0.25), sr, 0.003, 0.2)


def button_tap(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    blip = s.sine(s.ramp(p["freq"] * 1.15, p["freq"], n), n, sr) * s.decay(n, sr, 0.012)
    return s.fade(blip, sr, 0.001, 0.005)


def coin(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = np.zeros(n)
    for i, note in enumerate((p["first"], p["second"])):
        k = s.samples(0.28 if i else 0.09, sr)
        tone = s.square(s.hz(note), k, sr, duty=0.25)
        s.place(out, s.lowpass(tone, 7000.0, sr) * s.decay(k, sr, 0.08 if i else 0.05),
                s.samples(i * p["gap"], sr), 0.35)
    return s.fade(out, sr)


def genius_crit(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = _hit_core(sr, rng, n, 240.0, 45.0) * 0.8 + 0.2 * _ring(sr, n, p["ring"])
    at = s.samples(0.06, sr)
    k = s.samples(0.25, sr)
    rise = s.square(s.ramp(400.0, 1600.0, k, "exp"), k, sr, duty=0.4) * s.ramp(0.0, 1.0, k)
    s.place(out, s.lowpass(rise, 4500.0, sr), at, 0.18)
    stab_at = at + k
    for note in p["stab"]:
        sk = s.samples(0.5, sr)
        tone = s.fm(s.hz(note), 2.0, s.ramp(1.5, 0.1, sk), sk, sr) * s.decay(sk, sr, 0.18)
        s.place(out, tone, stab_at, 0.22)
    return s.fade(s.reverb(out, sr, 0.7, 0.25), sr, 0.002, 0.08)


def meeseeks_poof(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    pk = s.samples(0.05, sr)
    pop = s.sine(s.ramp(p["pop_from"], p["pop_to"], pk, "exp"), pk, sr) * s.decay(pk, sr, 0.015)
    puff = s.sweep(s.noise(n, rng), s.ramp(2600.0, 500.0, n, "exp"), sr)
    puff *= s.adsr(n, sr, 0.012, 0.12, 0.35, 0.25)
    out = puff * 1.4
    s.place(out, pop, 0, 0.8)
    return s.fade(s.reverb(out, sr, 0.5, 0.2), sr, 0.002, 0.05)


RECIPES: dict[str, Recipe] = {
    "portal_charge": portal_charge,
    "portal_open": portal_open,
    "card_flip": card_flip,
    "rare_reveal": rare_reveal,
    "legendary_reveal": legendary_reveal,
    "hit": hit,
    "crit_hit": crit_hit,
    "super_effective": super_effective,
    "faint": faint,
    "victory": victory,
    "defeat": defeat,
    "button_tap": button_tap,
    "coin": coin,
    "genius_crit": genius_crit,
    "meeseeks_poof": meeseeks_poof,
}
