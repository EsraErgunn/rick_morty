# tools/audio: procedural sound generator

Dev-only tool (SPEC D5, §4.11). It writes every sound of the app into
`assets/audio/` from code and one config file. It is not part of the app.

## Setup
Python 3.12 with numpy and scipy (`pip install -r tools/audio/requirements.txt`).

## Use (from the repo root)
```
python tools/audio/generate.py            # write all 18 WAVs + assets/audio/CREDITS.md
python tools/audio/generate.py --check    # also: determinism, loop seams, peaks, size
python tools/audio/generate.py --only coin hit
```

## Files
| File | What |
|---|---|
| `config.toml` | **The only place to change sounds**: seed, sample rates, levels, every effect's parameters, the music (chords and melodies as `NOTE:beats`). |
| `synth.py` | Building blocks: band-limited oscillators, envelopes, time-varying filters, FM, echo, reverb. |
| `sfx.py` | One recipe per sound effect (15). |
| `music.py` | Sequencer + `battle_loop`, `menu_loop`, `legendary_sting`. Loops are rendered long and the tail is folded onto the start, so they are seamless. |
| `generate.py` | Renders, normalizes, writes WAVs, prints a table with SHA-256, writes CREDITS.md. |

## Rules
- Same seed + config = byte-identical files (checked by `--check`).
- Format: 16-bit mono WAV. SFX 44.1 kHz (peak -3 dBFS); music 22.05 kHz
  (`[rates] music = 32000` if it sounds muffled), loudness matched (RMS -15 dB, peak ≤ -1 dBFS).
- Total < 8 MB. Melodies are original; never transcribe or imitate the show's music.
- Never edit the WAVs by hand: change `config.toml` or a recipe and regenerate.
