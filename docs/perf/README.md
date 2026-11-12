# Performance measurement (holo shader, T21 / SPEC S6)

Goal (plan T21): on the reference Android device in `--profile`, 30 s of tilting a
**legendary** card gives **≤ 5 % janky frames**. Captures are saved in this folder.

No new package is needed. Two methods; A is the required one, B is a quick check.

## A. DevTools timeline (required, real device)

1. Connect the reference phone (USB debugging on). Sync once in debug so Hive has data.
2. `flutter run --profile` (profile = release-like speed + timeline). Debug builds are
   much slower and never count.
3. Open the printed DevTools URL → **Performance**.
4. Open the card detail of **Rick Sanchez** (legendary, `/collection/1`): see the open
   point below for how to reach it in a profile build.
5. Click **Clear**, then tilt the phone continuously for **30 s** (slow circles, both
   axes), plus a few drags and two flips.
6. Read the frame chart: DevTools marks janky frames (UI or raster over the frame
   budget, 16.7 ms at 60 Hz; on 90/120 Hz phones the budget is smaller).
   `jank % = janky frames / total frames`.
7. **Export** (download icon) → save as `docs/perf/<date>_<device>_legendary_holo.json`
   and add one line to the table below.
8. Repeat once with a **common** card (no shader) as the baseline, and once with the
   holo shader forced off (fallback sheen) if the legendary number is near 5 %.

What to look at if it fails: a tall **raster** bar means the shader or the blend is
too expensive (cut the star grid, drop the foil, or lower the sheen area); a tall
**UI** bar means a rebuild per frame (the holo should only repaint, never rebuild).

**Reaching a card in profile:** the card lab and its menu link exist only in
debug builds. Options:
1. **Chosen (2026-11-12):** `flutter run --profile --dart-define=START_ROUTE=/collection/1`
   (`lib/app/start_route.dart`; debug/profile only, release ignores it, tested). The app
   skips the splash then, so sync once in a debug run first (Hive data stays).
2. (Not used) change `initialLocation` locally for the run, without committing.

## B. Quick check without DevTools

`flutter run --profile`, then press **`P`** in the terminal (performance overlay).
Tilt for 30 s and watch both graphs: green bars only = fine; red bars = jank. Take a
screenshot for this folder. Not precise enough to sign off S6, good for a first look.

## What can be measured on the emulator (no phone)

| Check | Emulator | Why |
|---|---|---|
| Shader compiles and draws (no crash, correct look per rarity) | yes | same Impeller/Skia pipeline |
| Holo moves with **drag** (touch fallback) | yes | mouse drag = touch |
| UI-thread cost: no rebuild per tilt frame (UI bar flat) | yes, roughly | UI work is CPU-bound, similar |
| Holo moves with **phone tilt** (sensor) | partly | Extended controls → Virtual sensors can fake rotation; good for "it reacts", not for feel |
| **Raster time / jank %** for S6 | **no** | emulator GPU is the host GPU through a translation layer; numbers are not representative |
| Battery, thermal throttling | no | |

Emulator status on the Windows machine (2026-11-12): the `Pixel_8` AVD did not finish
booting (qemu idle, WHPX available). Try a cold boot from Android Studio Device
Manager (Cold Boot Now) or set Graphics to "Software" before using it.

## Results

| Date | Device | Build | Card | Frames | Janky | Jank % | File |
|---|---|---|---|---|---|---|---|
| – | – | – | – | – | – | – | – |
