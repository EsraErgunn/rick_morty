"""Music: a tiny sequencer and three pieces (battle_loop, menu_loop, sting).

Loops are seamless: each piece is rendered longer than the loop, then the
tail (reverb, releases, notes crossing the end) is added onto the start.
Noise beds are filtered circularly (FFT), and every LFO completes a whole
number of cycles per loop, so the last sample flows into the first.
"""

from __future__ import annotations

import numpy as np

import synth as s

TAIL_SECONDS = 3.0


# --- helpers -----------------------------------------------------------------

def parse_line(items: list[str]) -> list[tuple[str | None, float, float]]:
    """['E5:1', 'r:0.5'] -> [(note or None, start beat, length beats)]."""
    out, t = [], 0.0
    for item in items:
        name, beats = item.split(":")
        length = float(beats)
        out.append((None if name == "r" else name, t, length))
        t += length
    return out


def parse_chord(token: str) -> list[float]:
    """'E2:m' -> midi numbers of the triad (root, third, fifth)."""
    root, quality = token.split(":")
    r = s.midi(root)
    third = 3 if quality == "m" else 4
    return [r, r + third, r + 7]


def wrap(buffer: np.ndarray, loop_n: int) -> np.ndarray:
    """Fold everything after the loop end back onto the start."""
    out = buffer[:loop_n].copy()
    tail = buffer[loop_n:]
    k = 0
    while k < tail.size:
        chunk = tail[k:k + loop_n]
        out[: chunk.size] += chunk
        k += loop_n
    return out


def circular_lowpass(x: np.ndarray, cutoff: float, sr: int) -> np.ndarray:
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(x.size, 1.0 / sr)
    spec *= 1.0 / (1.0 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spec, n=x.size)


def loop_lfo(cycles: int, loop_n: int, phase: float = 0.0) -> np.ndarray:
    """Sine LFO with a whole number of cycles over the loop."""
    t = np.arange(loop_n) / loop_n
    return np.sin(2.0 * np.pi * (cycles * t + phase))


# --- instruments -------------------------------------------------------------

def kick(sr: int) -> np.ndarray:
    n = s.samples(0.38, sr)
    body = s.sine(s.ramp(155.0, 44.0, n, "exp"), n, sr) * s.decay(n, sr, 0.13)
    click = s.highpass(np.r_[1.0, -1.0, np.zeros(s.samples(0.004, sr))], 2000.0, sr)
    out = s.drive(body, 1.8)
    s.place(out, click, 0, 0.3)
    return out


def snare(sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(0.22, sr)
    rattle = s.bandpass(s.noise(n, rng), 1200.0, min(7000.0, sr * 0.45), sr) * s.decay(n, sr, 0.06)
    tone = s.sine(195.0, n, sr) * s.decay(n, sr, 0.04)
    return 1.5 * rattle + 0.5 * tone


def hat(sr: int, rng: np.random.Generator, length: float = 0.05) -> np.ndarray:
    n = s.samples(length, sr)
    return s.highpass(s.noise(n, rng), min(7000.0, sr * 0.35), sr) * s.decay(n, sr, length / 3)


def pluck(f: float, seconds: float, sr: int) -> np.ndarray:
    n = s.samples(seconds, sr)
    v = s.square(f, n, sr, duty=0.25)
    return s.lowpass(v, 2600.0, sr) * s.decay(n, sr, 0.09)


def bass(f: float, seconds: float, sr: int) -> np.ndarray:
    n = s.samples(seconds, sr)
    v = s.saw(f, n, sr) + 0.6 * s.sine(f / 2.0, n, sr)
    v = s.sweep(v, s.ramp(1400.0, 350.0, n, "exp"), sr)
    return s.drive(v * s.adsr(n, sr, 0.004, 0.08, 0.6, 0.03), 1.4)


def lead_square(f: float, seconds: float, sr: int) -> np.ndarray:
    n = s.samples(seconds, sr)
    vib = 1.0 + 0.006 * s.sine(5.5, n, sr) * s.ramp(0.0, 1.0, n)
    v = s.square(f * vib, n, sr, duty=0.5) + 0.5 * s.square(f * 1.003 * vib, n, sr, duty=0.33)
    v = s.lowpass(v, 3600.0, sr)
    return v * s.adsr(n, sr, 0.006, 0.12, 0.65, min(0.08, seconds * 0.3))


def pad(freqs: list[float], seconds: float, sr: int, rng: np.random.Generator,
        attack: float, cutoff: float) -> np.ndarray:
    n = s.samples(seconds, sr)
    v = np.zeros(n)
    for f in freqs:
        for detune in (-0.005, 0.005):
            v += s.saw(f * (1 + detune), n, sr, rng.random())
    v = s.lowpass(v / (2 * len(freqs)), cutoff, sr)
    return v * s.adsr(n, sr, attack, 0.3, 0.85, min(0.6, seconds * 0.3))


# --- pieces ------------------------------------------------------------------

def battle_loop(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    beat = 60.0 / p["bpm"]
    bars = int(p["bars"])
    loop_n = s.samples(bars * 4 * beat, sr)
    buf_n = loop_n + s.samples(TAIL_SECONDS, sr)
    drums, low, mid, lead = (np.zeros(buf_n) for _ in range(4))
    k, sn = kick(sr), snare(sr, rng)
    chords = [parse_chord(c) for c in p["chords"]]

    def at(b: float) -> int:
        return s.samples(b * beat, sr)

    for bar in range(bars):
        b0 = bar * 4
        tones = chords[bar]
        for q in range(4):
            s.place(drums, k, at(b0 + q), 0.9)
            if q in (1, 3):
                s.place(drums, sn, at(b0 + q), 0.55)
        steps = 16 if bar >= bars // 2 else 8
        for h in range(steps):
            pos = b0 + h * 4 / steps
            if steps == 8 and h % 2 == 0:
                continue
            s.place(drums, hat(sr, rng), at(pos), 0.18 if h % 2 else 0.1)
        if bar + 1 in p["fill_bars"]:
            for f in range(4):
                s.place(drums, sn, at(b0 + 3 + f * 0.25), 0.3 + 0.1 * f)
        for i, step in enumerate(p["bass_steps"]):
            f = s.hz(tones[0] + step)
            s.place(low, bass(f, beat * 0.45, sr), at(b0 + i * 0.5), 0.5)
        arp = [tones[0], tones[1], tones[2], tones[1]]
        for i in range(16):
            f = s.hz(arp[i % 4] + 24 + (12 if i % 8 >= 4 else 0))
            s.place(mid, pluck(f, beat * 0.3, sr), at(b0 + i * 0.25), 0.12)
        pad_f = [s.hz(t + 12) for t in tones] + [s.hz(tones[0] + 24)]
        s.place(mid, pad(pad_f, 4 * beat, sr, rng, 0.02, 1500.0), at(b0), 0.35)

    for note, start, length in parse_line(p["melody"]):
        if note:
            s.place(lead, lead_square(s.hz(note), length * beat * 0.95, sr), at(start), 0.32)

    # Sidechain pump on the pad/arp (synthwave), whole cycles per loop.
    pump = np.ones(buf_n)
    t = (np.arange(buf_n) / sr) % beat
    pump -= 0.55 * np.exp(-t / 0.11)
    mid *= pump

    mid = s.echo(mid, sr, beat * 0.75, 0.3, 0.2)
    lead = s.echo(lead, sr, beat * 0.75, 0.28, 0.25)
    mix = drums + low + 0.9 * mid + lead
    mix = s.reverb(mix, sr, 0.5, 0.1)
    return s.drive(wrap(mix, loop_n), 1.2)


def menu_loop(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    beat = 60.0 / p["bpm"]
    bars = int(p["bars"])
    loop_s = bars * 4 * beat
    loop_n = s.samples(loop_s, sr)
    buf_n = loop_n + s.samples(TAIL_SECONDS, sr)
    pads, low, lead_buf, sparkle = (np.zeros(buf_n) for _ in range(4))

    def at(b: float) -> int:
        return s.samples(b * beat, sr)

    # Pads: merge repeated chords into one long note.
    chords = p["chords"]
    bar = 0
    while bar < bars:
        length = 1
        while bar + length < bars and chords[bar + length] == chords[bar]:
            length += 1
        freqs = [s.hz(n) for n in chords[bar]]
        s.place(pads, pad(freqs, length * 4 * beat + 0.6, sr, rng, 0.9, 900.0), at(bar * 4), 0.5)
        root = s.hz(chords[bar][0]) / 2.0
        for b in range(length * 4):
            if b % 2 == 0:
                nb = s.samples(beat * 1.6, sr)
                tone = s.triangle(root, nb, sr) * s.adsr(nb, sr, 0.02, 0.3, 0.5, 0.4)
                s.place(low, tone, at(bar * 4 + b), 0.22)
        bar += length

    # Theremin-like lead: one continuous pitch curve with glides + vibrato.
    events = [(n, st, ln) for n, st, ln in parse_line(p["melody"])]
    pitch = np.zeros(buf_n)
    amp = np.zeros(buf_n)
    prev = None
    glide_n = s.samples(p["glide"], sr)
    for note, start, length in events:
        i0, n = at(start), s.samples(length * beat, sr)
        if note is None:
            continue
        m = s.midi(note)
        seg = np.full(n, m)
        if prev is not None:
            g = min(glide_n, n)
            seg[:g] = np.linspace(prev, m, g)
        vib_env = s.ramp(0.0, 1.0, n) ** 1.5
        seg += p["vibrato_depth"] * vib_env * s.sine(p["vibrato_hz"], n, sr)
        end = min(buf_n, i0 + n)
        pitch[i0:end] = seg[: end - i0]
        amp[i0:end] = s.adsr(n, sr, 0.12, 0.3, 0.85, min(0.35, length * beat * 0.4))[: end - i0]
        prev = m
    # Hold the last pitch through rests (forward fill) so the oscillator never
    # drops to 0 Hz; before the first note, use the first note's pitch.
    has = pitch != 0.0
    idx = np.where(has, np.arange(buf_n), 0)
    np.maximum.accumulate(idx, out=idx)
    filled = pitch[idx]
    first = np.argmax(has)
    filled[:first] = pitch[first]
    f = 440.0 * 2.0 ** ((filled - 69.0) / 12.0)
    tone = s.sine(f, buf_n, sr) + 0.18 * s.sine(f * 2, buf_n, sr) + 0.06 * s.sine(f * 3, buf_n, sr)
    lead_buf = s.lowpass(tone, 2500.0, sr) * amp

    for _ in range(int(p["sparkles"])):
        pos = rng.random() * loop_s
        kk = s.samples(0.5, sr)
        fr = 1800.0 + 2200.0 * rng.random()
        ping = s.fm(fr, 2.0, s.ramp(1.0, 0.1, kk), kk, sr) * s.decay(kk, sr, 0.15)
        s.place(sparkle, ping, s.samples(pos, sr), 0.05)

    mix = 0.9 * pads + low + 0.42 * lead_buf + sparkle
    mix = s.reverb(mix, sr, 1.0, 0.35, damp=4500.0)
    looped = wrap(mix, loop_n)

    # Space noise bed: circular filter + whole-cycle LFO = seamless.
    bed = circular_lowpass(rng.standard_normal(loop_n), 500.0, sr)
    bed /= np.max(np.abs(bed)) + 1e-9
    bed *= 0.05 * (0.6 + 0.4 * loop_lfo(4, loop_n))
    return looped + bed


def legendary_sting(p: dict, sr: int, rng: np.random.Generator) -> np.ndarray:
    n = s.samples(p["duration"], sr)
    out = np.zeros(n)
    tn = s.samples(1.2, sr)
    timp = s.sine(s.ramp(110.0, 70.0, tn, "exp"), tn, sr) * s.decay(tn, sr, 0.35)
    timp += 0.4 * s.lowpass(s.noise(tn, rng), 300.0, sr) * s.decay(tn, sr, 0.1)
    s.place(out, s.drive(timp, 1.6), 0, 0.8)
    for note, start in p["fanfare"]:
        k = s.samples(0.5, sr)
        f = s.hz(note)
        v = s.saw(f, k, sr) + s.saw(f * 1.005, k, sr)
        v = s.lowpass(v, 3200.0, sr) * s.adsr(k, sr, 0.02, 0.1, 0.7, 0.2)
        s.place(out, v, s.samples(start, sr), 0.18)
    start = s.samples(0.72, sr)
    k = n - start
    chord = np.zeros(k)
    for note in p["chord"]:
        f = s.hz(note)
        chord += s.saw(f, k, sr, rng.random()) + s.saw(f * 1.004, k, sr, rng.random())
    chord = s.sweep(chord / len(p["chord"]), s.ramp(300.0, 4200.0, k, "exp"), sr)
    chord *= s.adsr(k, sr, 0.9, 0.4, 0.75, 1.4)
    s.place(out, chord, start, 0.3)
    shimmer = np.zeros(k)
    for f in (2349.0, 2960.0, 3520.0):
        shimmer += s.sine(f, k, sr) * (0.5 + 0.5 * s.sine(7.0, k, sr))
    s.place(out, shimmer * s.adsr(k, sr, 1.0, 0.5, 0.6, 1.2) * 0.04, start, 1.0)
    return s.fade(s.reverb(out, sr, 1.0, 0.3), sr, 0.003, 0.4)


PIECES = {
    "battle_loop": battle_loop,
    "menu_loop": menu_loop,
    "legendary_sting": legendary_sting,
}
