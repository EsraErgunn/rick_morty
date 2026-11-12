"""DSP building blocks for Portal Cards sounds (numpy + scipy only).

Everything works on float64 mono arrays in [-1, 1]. No per-sample Python
loops: oscillators are vectorized, time-varying filters run block by block.
"""

from __future__ import annotations

import re

import numpy as np
from scipy import signal

NOTE_RE = re.compile(r"^([A-Ga-g])([#b]?)(-?\d)$")
_SEMITONE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


# --- pitch -------------------------------------------------------------------

def midi(note: str | int | float) -> float:
    """'A4' -> 69, 'C#5' -> 73; numbers pass through."""
    if isinstance(note, (int, float)):
        return float(note)
    m = NOTE_RE.match(note.strip())
    if not m:
        raise ValueError(f"bad note name: {note!r}")
    name, accidental, octave = m.groups()
    value = _SEMITONE[name.upper()] + (1 if accidental == "#" else -1 if accidental == "b" else 0)
    return float(value + (int(octave) + 1) * 12)


def hz(note: str | int | float) -> float:
    return 440.0 * 2.0 ** ((midi(note) - 69.0) / 12.0)


# --- time --------------------------------------------------------------------

def samples(seconds: float, sr: int) -> int:
    return max(1, int(round(seconds * sr)))


def ramp(start: float, end: float, n: int, curve: str = "lin") -> np.ndarray:
    """Values from start to end over n samples ('lin' or 'exp')."""
    if curve == "exp" and start > 0 and end > 0:
        return start * (end / start) ** np.linspace(0.0, 1.0, n)
    return np.linspace(start, end, n)


# --- oscillators -------------------------------------------------------------

def _phase(freq, n: int, sr: int, phase0: float = 0.0) -> tuple[np.ndarray, np.ndarray]:
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), (n,))
    dt = f / sr
    t = (phase0 + np.cumsum(dt) - dt[0]) % 1.0
    return t, dt


def _polyblep(t: np.ndarray, dt: np.ndarray) -> np.ndarray:
    out = np.zeros_like(t)
    dt = np.maximum(dt, 1e-9)
    lo = t < dt
    x = t[lo] / dt[lo]
    out[lo] = x + x - x * x - 1.0
    hi = t > 1.0 - dt
    x = (t[hi] - 1.0) / dt[hi]
    out[hi] = x * x + x + x + 1.0
    return out


def sine(freq, n: int, sr: int, phase0: float = 0.0) -> np.ndarray:
    t, _ = _phase(freq, n, sr, phase0)
    return np.sin(2.0 * np.pi * t)


def saw(freq, n: int, sr: int, phase0: float = 0.0) -> np.ndarray:
    """Band-limited sawtooth (polyBLEP)."""
    t, dt = _phase(freq, n, sr, phase0)
    return 2.0 * t - 1.0 - _polyblep(t, dt)


def square(freq, n: int, sr: int, duty: float = 0.5, phase0: float = 0.0) -> np.ndarray:
    """Band-limited pulse wave (polyBLEP)."""
    t, dt = _phase(freq, n, sr, phase0)
    out = np.where(t < duty, 1.0, -1.0)
    out += _polyblep(t, dt)
    out -= _polyblep((t + 1.0 - duty) % 1.0, dt)
    return out


def triangle(freq, n: int, sr: int) -> np.ndarray:
    t, _ = _phase(freq, n, sr)
    return 2.0 * np.abs(2.0 * t - 1.0) - 1.0


def fm(carrier, ratio: float, index, n: int, sr: int) -> np.ndarray:
    """Two-operator FM: sin(carrier + index * sin(ratio * carrier))."""
    c = np.broadcast_to(np.asarray(carrier, dtype=np.float64), (n,))
    mod = sine(c * ratio, n, sr)
    idx = np.broadcast_to(np.asarray(index, dtype=np.float64), (n,))
    t, _ = _phase(c, n, sr)
    return np.sin(2.0 * np.pi * t + idx * mod)


def noise(n: int, rng: np.random.Generator) -> np.ndarray:
    return rng.standard_normal(n) * 0.35


# --- envelopes ---------------------------------------------------------------

def adsr(n: int, sr: int, a: float, d: float, s: float, r: float, curve: float = 1.0) -> np.ndarray:
    """Attack/decay/sustain/release over n samples (release fits at the end)."""
    na, nd, nr = samples(a, sr), samples(d, sr), samples(r, sr)
    ns = max(0, n - na - nd - nr)
    env = np.concatenate([
        np.linspace(0.0, 1.0, na, endpoint=False),
        np.linspace(1.0, s, nd, endpoint=False),
        np.full(ns, s),
        np.linspace(s, 0.0, nr),
    ])
    env = np.pad(env, (0, max(0, n - env.size)))[:n]
    return env ** curve


def decay(n: int, sr: int, seconds: float, attack: float = 0.002) -> np.ndarray:
    """Fast attack, exponential decay (time constant `seconds`)."""
    t = np.arange(n) / sr
    env = np.exp(-t / max(seconds, 1e-4))
    na = samples(attack, sr)
    env[:na] *= np.linspace(0.0, 1.0, na)
    return env


def fade(x: np.ndarray, sr: int, fade_in: float = 0.003, fade_out: float = 0.01) -> np.ndarray:
    """Short fades so a one-shot never clicks at its edges."""
    y = x.copy()
    ni, no = min(samples(fade_in, sr), y.size), min(samples(fade_out, sr), y.size)
    y[:ni] *= np.linspace(0.0, 1.0, ni)
    y[y.size - no:] *= np.linspace(1.0, 0.0, no)
    return y


# --- filters -----------------------------------------------------------------

def lowpass(x: np.ndarray, cutoff: float, sr: int, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, min(cutoff, sr * 0.45), "low", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x: np.ndarray, cutoff: float, sr: int, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, min(cutoff, sr * 0.45), "high", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def bandpass(x: np.ndarray, low: float, high: float, sr: int, order: int = 2) -> np.ndarray:
    high = min(high, sr * 0.45)
    sos = signal.butter(order, [low, high], "band", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def sweep(x: np.ndarray, cutoff: np.ndarray, sr: int, kind: str = "low",
          width: float = 0.6, block: int = 128) -> np.ndarray:
    """Time-varying 2nd-order filter (coefficients updated per block).

    kind 'low' uses `cutoff` as the corner; 'band' a band around it
    (cutoff * (1 -+ width/2)).
    """
    out = np.empty_like(x)
    zi = None
    nyq = sr * 0.45
    for start in range(0, x.size, block):
        end = min(start + block, x.size)
        fc = float(np.clip(cutoff[start], 30.0, nyq))
        if kind == "low":
            sos = signal.butter(2, fc, "low", fs=sr, output="sos")
        else:
            lo, hi = fc * (1 - width / 2), min(fc * (1 + width / 2), nyq)
            sos = signal.butter(1, [max(lo, 20.0), hi], "band", fs=sr, output="sos")
        if zi is None or zi.shape[0] != sos.shape[0]:
            zi = signal.sosfilt_zi(sos) * 0.0
        out[start:end], zi = signal.sosfilt(sos, x[start:end], zi=zi)
    return out


def formants(x: np.ndarray, sr: int, centers: list[float], gains: list[float],
             q: float = 6.0) -> np.ndarray:
    """Vowel-like color: parallel band-passes."""
    y = np.zeros_like(x)
    for fc, g in zip(centers, gains):
        bw = fc / q
        y += g * bandpass(x, fc - bw / 2, fc + bw / 2, sr)
    return y


# --- effects -----------------------------------------------------------------

def _comb(x: np.ndarray, delay: int, feedback: float) -> np.ndarray:
    a = np.zeros(delay + 1)
    a[0], a[-1] = 1.0, -feedback
    return signal.lfilter([1.0], a, x)


def _allpass(x: np.ndarray, delay: int, g: float) -> np.ndarray:
    b = np.zeros(delay + 1)
    a = np.zeros(delay + 1)
    b[0], b[-1] = -g, 1.0
    a[0], a[-1] = 1.0, -g
    return signal.lfilter(b, a, x)


def reverb(x: np.ndarray, sr: int, size: float = 0.8, mix: float = 0.25,
           damp: float = 6000.0) -> np.ndarray:
    """Small Schroeder reverb (4 combs + 2 all-passes)."""
    scale = sr / 44100.0
    combs = [1116, 1188, 1277, 1356]
    wet = np.zeros_like(x)
    for d in combs:
        wet += _comb(x, int(d * scale * size) + 1, 0.78 + 0.12 * size)
    wet = lowpass(wet / len(combs), damp, sr, order=1)
    for d in (225, 556):
        wet = _allpass(wet, int(d * scale) + 1, 0.5)
    return (1.0 - mix) * x + mix * wet


def echo(x: np.ndarray, sr: int, seconds: float, feedback: float = 0.35,
         mix: float = 0.3) -> np.ndarray:
    wet = _comb(x, samples(seconds, sr), feedback) - x
    return x + mix * wet


def drive(x: np.ndarray, amount: float = 1.5) -> np.ndarray:
    return np.tanh(x * amount) / np.tanh(amount)


# --- mixing ------------------------------------------------------------------

def place(dest: np.ndarray, src: np.ndarray, at: int, gain: float = 1.0) -> None:
    """Add src into dest at sample `at` (clipped to dest)."""
    if at >= dest.size:
        return
    end = min(dest.size, at + src.size)
    dest[at:end] += gain * src[: end - at]


def normalize(x: np.ndarray, peak_db: float) -> np.ndarray:
    peak = np.max(np.abs(x))
    if peak == 0:
        return x
    return x * (10.0 ** (peak_db / 20.0) / peak)


def to_int16(x: np.ndarray) -> np.ndarray:
    return np.clip(np.round(x * 32767.0), -32768, 32767).astype(np.int16)
