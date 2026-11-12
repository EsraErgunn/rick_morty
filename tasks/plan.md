# Implementation Plan: Week 1 (Foundation)

Status: **approved** (2026-11-11)
Sources: `docs/SPEC.md` (approved), `docs/PROJECT.md` §5 Week 1, `CLAUDE.md`, `.claude/rules/*`, `rm-game-mechanics` [GM].
Toolchain: Flutter 3.47.6 stable, Dart 3.13.5 (Mac and Windows machine).

## Where we left off (2026-11-12, Windows machine)
- **Completed:** T1 to T15. Checkpoints A approved. Phase 3 (T10 to T15) done; Checkpoint B review pending (device checks open).
- **Next task:** T15b only after the owner resolves its conflict with SPEC §3 (see T15b notes); otherwise T16 Card factory + rarity pool.
- **Commits:** no `Co-Authored-By` lines (owner request 2026-11-12).
- **Open notes:**
  - Reference Android device: TBD. Device and iOS Simulator checks pending (Checkpoint A).
  - iOS Simulator install hang from T1 (see Known issue), retry at Checkpoint C. `pod install` + iOS build after T5 (new `generate: true`) to re-check on the Mac.
  - Golden `test/app/theme/goldens/glyph_sample.png` was generated on Windows; text rendering differs slightly on macOS, so it may fail there. If it does: regenerate on one agreed machine, or tag it and run goldens on that machine only.
  - To check on device (collected): T1 app opens; T3 to T6 see Checkpoint A.

## Devices
- **Reference Android device:** TBD (no device connected yet). All performance checks run on it once chosen.
- **iOS:** a real iPhone is only available at the end of Week 2 and in Week 4. In Week 1 (and Week 3), iOS checks mean: `flutter build ios --no-codesign` succeeds and the app opens on the iOS Simulator with correct UI. Sensor, haptic and performance checks on iOS move to the Week 2 end and Week 4 device sessions.

## Overview
Week 1 turns the empty repo into a running Flutter app (Android + iOS) with: theme tokens, app shell (DI, router, l10n), the pure-Dart card engine (rarity, type, stats, passives), the API client and resumable first-launch sync into Hive with progress on the splash screen, and the `GameCard` widget with flip, rarity frames, 3D tilt and the holo shader. The portal, sound and haptics come in Week 2.

## Architecture decisions
- **Project creation:** `flutter create --org com.esraergun --project-name portalcards --platforms android,ios .` gives `com.esraergun.portalcards` for both the Android `applicationId` and the iOS bundle ID, and `package:portalcards/...` imports.
- **`core/game` takes primitives, not entities** (`id`, `episodeCount`, `species`, `status`). Then it depends on nothing and the data layer maps entity → engine input.
- **Card model is derived, never stored** [SPEC §3]. A `CardFactory` combines a stored character with `core/game`. A `RarityPool` index is built once after sync (DI singleton).
- **Tilt:** our `TiltStream` is the only sensor subscription. It drives `flutter_tilt` through a `TiltController` (flutter_tilt's own sensors are off), and the holo `uTilt` reads the same value [animation rules]. Task 17 checks the one undocumented point (does `onGestureMove` fire for controller input?) before the shader is wired.
- **Week 1 has no sound or haptics.** The card flip is silent until `AudioService` / `HapticsService` land in Week 2 (roadmap order). The flip widget exposes an `onFlipped` callback so Week 2 only adds a `BlocListener`.
- **Engine and data run in parallel tracks.** Phase 2 (engine) depends only on Task 1, so it can be built while waiting for real-device checks in Phase 3.

## Dependency graph
```
T1 create ─┬─ T2 deps/lints ─┬─ T3 color+motion tokens ── T4 fonts+type ─┐
           │                 ├─ T5 l10n+logger+app ── T6 DI+router ───────┤
           │                 └─ T10 dio client ─┐                         │
           └─ T7 fixtures ─┬─ T8 rarity+type    ├─ T11 DTO/mappers         │
                           ├─ T9 stats+passives │       │                 │
                           │                    │  T12 hive storage        │
                           │                    │       │                 │
                           │                    │  T13 player box          │
                           │                    └─ T14 sync repository     │
                           │                            │                 │
                           │                       T15 sync bloc + splash ◄┘
                           └──────────── T16 card factory + pool
                                               │
                     T17 GameCard front ── T18 back + flip ── T19 TiltStream
                                                                 │
                                                  T20 flutter_tilt wiring ── T21 holo shader
```

---

## Phase 1: Project foundation

### Task 1: Create the Flutter project
**Description:** Run `flutter create` in the repo root for Android + iOS with the agreed IDs. Merge Flutter's `.gitignore` with ours and add the forbidden paths from `CLAUDE.md` (`build/`, `.env`, `key.properties`, `*.jks`, `build/symbols/`). Replace the generated README with a short one that has the non-commercial fan-project disclaimer. Block cleartext traffic on Android.
**Acceptance criteria:**
- [ ] `android/app/build.gradle(.kts)` has `applicationId = "com.esraergun.portalcards"`; the iOS `PRODUCT_BUNDLE_IDENTIFIER` is `com.esraergun.portalcards` (Debug, Release and Profile).
- [ ] Only `android/` and `ios/` platform folders exist; existing `CLAUDE.md`, `docs/`, `.claude/` are unchanged.
- [ ] `android:usesCleartextTraffic="false"` in the main manifest; iOS ATS left at its secure default.
**Verification:** `flutter analyze` clean; `flutter test` (default test) green; `flutter run` on an Android device shows the counter app; `flutter build ios --no-codesign` succeeds and the app opens on the iOS Simulator; `git status` shows no `build/` files.
**Dependencies:** none
**Files:** generated project, `.gitignore`, `README.md`, `android/app/src/main/AndroidManifest.xml`
**Size:** S (mostly generated)

### Task 2: Dependencies and lints
**Description:** Add the approved packages from `CLAUDE.md` at current stable versions, plus the ones the rules require: `fpdart` (code rules), `hive_ce_generator`, `build_runner`, `bloc_test`, `mocktail`, `flutter_localizations` + `intl` (l10n). Set strict analysis options. Create the `lib/` folder skeleton from `CLAUDE.md` (each folder gets its first file in a later task, so empty folders are not committed).
**Acceptance criteria:**
- [ ] `pubspec.yaml` lists exactly the approved runtime packages + the dev packages above; nothing else.
- [ ] `analysis_options.yaml`: `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types`; `avoid_print: error`; `prefer_const_constructors`.
- [ ] `flutter pub get` resolves without overrides; `cd ios && pod install` succeeds.
**Verification:** `flutter analyze --fatal-infos` clean; `flutter test` green; `flutter build apk --debug` succeeds.
**Dependencies:** T1
**Files:** `pubspec.yaml`, `analysis_options.yaml`, `ios/Podfile.lock`
**Size:** XS

### Task 3: Color, motion and spacing tokens (+ contrast test)
**Description:** `app/theme/` tokens from SPEC §5.2 and §5.4 and the `AppMotion` values from the animation rules. A unit test computes WCAG contrast ratios for the pairs in SPEC §5.8 T2.
**Acceptance criteria:**
- [ ] `AppColors` (all tokens in SPEC §5.2 incl. rarity), `AppMotion` (`fast 150`, `normal 300`, `slow 600`, `cinematic 1500`; curves), `AppSpacing` (4 dp scale), `AppRadius`, `AppOutline` exist as `const`.
- [ ] Contrast test passes: body pairs ≥ 4.5:1, display/icon pairs ≥ 3:1. Any failing token is fixed here, and the measured ratios are written into SPEC §5.2 (**SPEC §5.8 T2**).
**Verification:** `flutter test test/app/theme/` green; `flutter analyze --fatal-infos` clean.
**Dependencies:** T2
**Files:** `lib/app/theme/colors.dart`, `motion.dart`, `spacing.dart`, `test/app/theme/contrast_test.dart`, `docs/SPEC.md`
**Size:** M

### Task 4: Fonts, typography and ThemeData (+ glyph check)
**Description:** Bundle Grandstander (700, 900) and Atkinson Hyperlegible Next (400, 700) under `assets/fonts/` with their OFL license files. Build the type scale from SPEC §5.3 and the `ThemeData` that uses all tokens.
**Acceptance criteria:**
- [ ] `AppTypography` with `caption 12, body 16, title 20, headline 25, display 40, callout 56`; tabular figures on the stat/coin styles.
- [ ] Turkish glyphs `ğ ş ı İ ç ö ü Ğ Ş Ç Ö Ü` render in every weight of both fonts, with no fallback font and no missing-glyph box; the result is recorded in SPEC §5.3; a failing font is swapped per SPEC §5.3 (**SPEC §5.8 T1**).
- [ ] No hex, duration or font size literal outside `lib/app/theme/` (**SPEC §5.8 T3**).
**Verification:** widget test that pumps a glyph sample in each style and checks the font family resolves (plus a golden image of the sample, kept under `test/app/theme/goldens/`); screenshot of the same sample on the reference Android device and the iOS Simulator; `grep -rnE "Color\(0x|Duration\(|fontSize:" lib --include=*.dart | grep -v lib/app/theme` returns nothing.
**Dependencies:** T3
**Files:** `assets/fonts/*`, `pubspec.yaml`, `lib/app/theme/typography.dart`, `lib/app/theme/app_theme.dart`, `test/app/theme/glyph_test.dart`
**Size:** M

### Task 5: l10n, AppLogger and the app widget
**Description:** Turkish l10n (`lib/l10n/app_tr.arb`, `l10n.yaml`, generated localizations), `AppLogger` (debug-only, no-op in release), and `PortalCardsApp` using the theme.
**Acceptance criteria:**
- [ ] `app_tr.arb` holds every string used so far; widgets read text only through `AppLocalizations`.
- [ ] `AppLogger` logs only when `kDebugMode`; no `print(` anywhere in `lib/`.
- [ ] App starts with dark `void` background and the theme from T4.
**Verification:** `flutter test` (a widget test pumps the app and finds a localized string); `grep -rn "print(" lib/` empty.
**Dependencies:** T4
**Files:** `l10n.yaml`, `lib/l10n/app_tr.arb`, `lib/core/logging/app_logger.dart`, `lib/app/app.dart`, `lib/main.dart`
**Size:** M

### Task 6: DI and router skeleton
**Description:** `get_it` setup (`configureDependencies()`), `go_router` with every route from SPEC §2 pointing at a placeholder page (title only) except `/splash`, which is the start route.
**Acceptance criteria:**
- [ ] All routes in SPEC §2 exist and are reachable; unknown routes show a "Sayfa bulunamadı" page with a "Ana menü" button.
- [ ] DI registration happens before `runApp`; tests can reset and re-register.
**Verification:** widget test navigates to each route and finds its placeholder title; `flutter analyze --fatal-infos` clean.
**Dependencies:** T5
**Files:** `lib/app/di.dart`, `lib/app/router.dart`, `lib/app/placeholder_page.dart`, `test/app/router_test.dart`
**Size:** S

### Checkpoint A (after T1 to T6)
- [x] `flutter analyze --fatal-infos` clean, `flutter test` green (57/57, 2026-11-12)
- [ ] App runs on the reference Android device and the iOS Simulator: dark themed placeholder screens, Turkish text, fonts correct
  - pending: no device connected (Android device and iOS Simulator run of T1 not verified; build-only so far)
- [x] Contrast and glyph results written into SPEC
- [ ] Review with you before continuing

---

## Phase 2: Card engine (pure Dart, `lib/core/game/`)

### Task 7: Test fixtures from the real API
**Description:** Save real responses as JSON in `test/fixtures/`: Rick (1), Morty (2), one single-episode character, one `Dead` and one `unknown` status character, one Robot, one Alien, one Animal, one Mythological Creature; one episode page and one location page.
**Acceptance criteria:**
- [ ] Files are unmodified API responses (HTTPS GET); the source URL of each is noted in `test/fixtures/README.md`.
- [ ] Together they cover all 4 rarities, all 6 types and all 3 statuses.
**Verification:** a small test loads each fixture and asserts the expected `episode.length`, `species` and `status`.
**Dependencies:** T1
**Files:** `test/fixtures/*.json`, `test/fixtures/README.md`, `test/fixtures/fixtures_test.dart`
**Size:** S

### Task 8: Rarity and card type
**Description:** `rarity.dart` [GM §2] and `card_type.dart` [GM §3] including the type multiplier and effectiveness enum.
**Acceptance criteria:**
- [ ] Rarity thresholds 1 / 2 to 4 / 5 to 19 / 20+; multipliers 1.00 / 1.15 / 1.30 / 1.50; holo strength per rarity.
- [ ] Species → type mapping incl. Humanoid → Human and the Neutral fallback; type multiplier ×1.5 / ×0.75 / ×1.0 with an `Effectiveness` value for the UI text.
- [ ] No Flutter, Hive or Dio import in `lib/core/game/` (checked by a test that scans the imports).
**Verification:** `flutter test test/core/game/` with behavior names like `'Rick (51 episodes) is legendary'`, `'Human attacking Alien is super effective'`; every boundary value (1, 2, 4, 5, 19, 20) tested.
**Dependencies:** T7
**Files:** `lib/core/game/rarity.dart`, `card_type.dart`, `test/core/game/rarity_test.dart`, `card_type_test.dart`, `test/core/game/purity_test.dart`
**Size:** M

### Task 9: Stats and passives
**Description:** `card_stats.dart` [GM §4] and `passives.dart` [GM §5]. Passive functions that need randomness take a `Random`.
**Acceptance criteria:**
- [ ] Same id → identical stats across runs; values match a hand-computed expectation for Rick (id 1) and Morty (id 2).
- [ ] Over all ids 1 to 826 grouped by a synthetic rarity: legendary avg > epic > rare > common for every stat.
- [ ] Status → passive mapping; Zombi revive value = 30% max HP; Belirsiz gives ×1.2 or ×0.8, about 50/50 over 10,000 seeded rolls (± 2%).
**Verification:** `flutter test test/core/game/`; no `Random()` call inside `lib/core/game/` (`grep -rn "Random()" lib/core/game` empty).
**Dependencies:** T8
**Files:** `lib/core/game/card_stats.dart`, `passives.dart`, `test/core/game/card_stats_test.dart`, `passives_test.dart`
**Size:** M

---

## Phase 3: Data and first-launch sync

### Task 10: Dio client
**Description:** `core/network`: Dio with base URL `https://rickandmortyapi.com/api`, 15 s timeouts, a retry interceptor (429/5xx, max 3, exponential backoff), endpoint helpers, and mapping of errors to `Failure` types in `core/errors`.
**Acceptance criteria:**
- [ ] Non-HTTPS base URL is impossible (asserted at construction).
- [ ] 429 and 5xx are retried up to 3 times; 4xx (other) and timeouts after retries return a `Failure`, never throw to callers.
**Verification:** unit tests with a mocked `HttpClientAdapter`: 2× 503 then 200 → success after 3 calls; 4× 503 → `ServerFailure`; 404 → no retry.
**Dependencies:** T2
**Files:** `lib/core/network/dio_client.dart`, `retry_interceptor.dart`, `endpoints.dart`, `lib/core/errors/failures.dart`, `test/core/network/retry_interceptor_test.dart`
**Size:** M

### Task 11: DTOs and mappers
**Description:** `features/sync/data`: page DTO (`info` + `results`) and character, episode and location DTOs with `fromJson`; mappers to domain entities, including id extraction from URLs.
**Acceptance criteria:**
- [ ] Every fixture parses; `episode` / `characters` / `residents` URL lists become id lists.
- [ ] Malformed or missing fields map to a `Failure`, not a crash.
**Verification:** `flutter test test/features/sync/data/` using the T7 fixtures + one malformed sample.
**Dependencies:** T7, T10
**Files:** `lib/features/sync/data/models/*.dart` (3 to 4), `lib/features/sync/data/mappers.dart`, `test/features/sync/data/mappers_test.dart`
**Size:** M

### Task 12: Hive storage for API data
**Description:** `core/storage`: Hive init, `hive_type_ids.dart`, stored models + generated adapters for character, episode and location; boxes `characters`, `episodes`, `locations`.
**Acceptance criteria:**
- [ ] Type IDs are defined once in `hive_type_ids.dart`.
- [ ] Write → close → reopen returns equal objects.
**Verification:** `dart run build_runner build --delete-conflicting-outputs` clean; storage tests on a temp directory.
**Dependencies:** T11
**Files:** `lib/core/storage/hive_init.dart`, `hive_type_ids.dart`, `stored_models.dart` (+ generated), `test/core/storage/storage_test.dart`
**Size:** M

### Task 13: Player box and starting state
**Description:** `player` and `collection` boxes with the player state from SPEC: coins, settings (sound, music, haptics, volumes), deck, wins, `portalsOpened`, `shakeHintSeen`, `completedAlbums`, `demoUnlocked`, `forceNextLegendary`, `syncProgress`, `syncVersion` + timestamp.
**Acceptance criteria:**
- [ ] First open creates the default state exactly once: 300 coins [GM §8], settings all on, all counters 0 / false (SPEC §2.1 AC6).
- [ ] A second open does not reset anything.
**Verification:** tests on a temp directory: fresh → defaults; modify → reopen → kept.
**Dependencies:** T12
**Files:** `lib/core/storage/player_store.dart`, `player_state.dart` (+ generated), `test/core/storage/player_store_test.dart`
**Size:** S

### Task 14: Sync repository (resumable)
**Description:** `features/sync`: domain interface + implementation that downloads characters, episodes and locations page by page, writes each page to Hive at once, updates `syncProgress`, reads totals from `info.count` / `info.pages`, and emits progress.
**Acceptance criteria:**
- [ ] Progress stream emits `downloaded / total` across all three resources (SPEC §2.1 AC1, AC2).
- [ ] A failure on page N keeps pages 1..N-1; the next run starts at page N and fetches no page twice (AC3).
- [ ] Completion stores `syncVersion` + timestamp; a completed sync makes no network call on the next run (AC5).
**Verification:** unit tests with a fake remote: full run; fail at page 5 then resume; already-synced → 0 calls.
**Dependencies:** T10, T12, T13
**Files:** `lib/features/sync/domain/sync_repository.dart`, `lib/features/sync/data/sync_repository_impl.dart`, `lib/features/sync/data/remote_data_source.dart`, `test/features/sync/sync_repository_test.dart`
**Size:** M

### Task 15: Sync bloc and splash page
**Description:** `SyncBloc` (`SyncStarted`, `SyncRetryRequested`) and `SplashPage` with the `PortalLoader`, a progress bar with percentage, the error message + "Tekrar dene", and navigation to the main menu placeholder when done.
**PortalLoader** (`lib/core/widgets/portal_loader.dart`, added 2026-11-12 by the owner; matches SPEC §4.1 "portal swirls in from a point"):
- Opens from a point: scale 0 → 1 with `AppMotion.popIn` (`easeOutBack`) over `AppMotion.slow`, then keeps rotating while waiting.
- Week 1: a green spiral drawn with `CustomPainter` (`portal`, `portalHot`, `ink` outline). Week 2 swaps the inside for `portal.frag`; the widget's public API (constructor, `visible`/`intensity`) does not change.
- Anti-flicker: if loading finishes in < 300 ms the loader is never shown; once shown it stays at least 600 ms. Both values are `AppMotion` tokens.
- Reduced motion (`MediaQuery.disableAnimations`): no scale or rotation, only a fade in/out.
- Controllers disposed; wrapped in `RepaintBoundary`.
**Acceptance criteria:**
- [ ] States: `initial → loading(progress) → success` or `failure`; retry resumes (SPEC §2.1 AC3).
- [ ] Splash shows sync progress as a bar **and a percentage** (plus `downloaded / total`).
- [ ] PortalLoader: hidden for loads < 300 ms, visible ≥ 600 ms once shown, fade only with reduced motion (widget tests with fake time).
- [ ] Already-synced launch reaches the main menu in ≤ 2 s on the reference device (AC5).
**Verification:** `bloc_test` per event; widget tests for the error state and the loader timing rules; device: first launch on Wi-Fi to the end, then airplane mode + relaunch reaches the menu; turning Wi-Fi off mid-sync shows retry and resumes.
**Dependencies:** T6, T14
**Files:** `lib/features/sync/presentation/bloc/sync_bloc.dart`, `sync_event.dart`, `sync_state.dart`, `lib/features/sync/presentation/pages/splash_page.dart`, `lib/core/widgets/portal_loader.dart`, `lib/app/theme/motion.dart`, `test/features/sync/sync_bloc_test.dart`, `test/core/widgets/portal_loader_test.dart`

### Task 15b: Background image precache (added 2026-11-12 by the owner)
**Description:** After a completed sync, warm the disk cache of character images in the background so collection and portal screens show art offline. It never blocks the splash or the navigation to the menu.
**Acceptance criteria:**
- [ ] Starts after `SyncBloc` reaches success (and on later launches if not finished); the menu opens without waiting for it.
- [ ] Downloads to the `cached_network_image` disk cache only (no decoding of ~800 images into memory), a few at a time (concurrency ≤ 4), stops when the app goes to background, resumes later; failures are skipped and retried on the next launch.
- [ ] Uses only approved packages; if it needs `flutter_cache_manager` as a direct dependency, ask first.
**Verification:** unit test with a fake downloader (concurrency limit, skip on error, resume); device: after first sync, airplane mode → collection shows art (once T17 exists).
**Dependencies:** T15
**Size:** S
**Open (2026-11-12):** conflicts with SPEC §3 "Images: never prefetched in bulk (bandwidth). Owned cards are cached when first revealed." All 826 avatars are roughly 10 to 15 MB. Not started; owner decides: change SPEC §3, limit it (e.g. Wi-Fi only, or owned + deck + next album page), or drop it. No new package is needed (`CachedNetworkImageProvider.defaultCacheManager.downloadFile`).
**Size:** M

### Checkpoint B (after T7 to T15)
- [x] `flutter analyze --fatal-infos` clean, `flutter test` green (199/199, 2026-11-12)
- [ ] Real device: full first sync; box sizes match `info.count` for all three (SPEC S1); airplane-mode relaunch works (S2)
- [ ] Review with you before continuing

---

## Phase 4: GameCard, tilt and holo

### Task 16: Card factory and rarity pool
**Description:** `CardFactory` builds a `GameCardData` (name, image, rarity, type, stats, passive, back facts) from a stored character via `core/game`. `RarityPool` (`Map<Rarity, List<int>>`) is built once after sync and registered in DI.
**Acceptance criteria:**
- [ ] Factory output for the fixtures equals the `core/game` results (no formula outside `core/game`).
- [ ] Pool covers every synced character exactly once; it is rebuilt only after a sync.
**Verification:** unit tests with fixtures + a fake box.
**Dependencies:** T9, T13
**Files:** `lib/core/cards/card_factory.dart`, `game_card_data.dart`, `rarity_pool.dart`, `test/core/cards/card_factory_test.dart`
**Size:** M

### Task 17: GameCard front with rarity frames
**Description:** `core/widgets/game_card/`: 5:7 card, front layout and the four rarity frames from SPEC §5.5 (ink outline, notched corners for epic/legendary, legendary emblem), `CachedNetworkImage` with placeholder and an ink-silhouette error widget.
**Acceptance criteria:**
- [ ] Frame width, color and corner style per rarity match SPEC §5.5.
- [ ] Text shows name, type icon + label, rarity name, 2×2 stats (tabular), passive name (never color alone).
- [ ] Image error shows the silhouette with the name.
- [ ] Card lab cards are built from the T7 fixtures through `CardFactory` / `core/game` (real rarity, type, stats, passive); no hand-written sample data (owner note 2026-11-12: the palette preview's placeholder cards were wrong, e.g. Morty must be legendary).
**Verification:** widget tests per rarity (frame color + texts found); golden images for 4 rarities; a "card lab" route (`/debug/card-lab`) shows all four; the route is registered only when `kDebugMode` is true, so it does not exist in release builds (checked by a router test).
**Dependencies:** T4, T16
**Files:** `lib/core/widgets/game_card/game_card.dart`, `card_front.dart`, `rarity_frame_painter.dart`, `test/core/widgets/game_card_test.dart`
**Size:** M

### Task 18: Card back and flip animation
**Description:** `card_back.dart` and a flip widget: Y-axis rotation with perspective (`setEntry(3, 2, 0.001)`), face swap at 90°, `AppMotion.normal` + `easeInOutCubic`, `onFlipped` callback; reduced motion = instant swap.
**Acceptance criteria:**
- [ ] Tap flips front ↔ back; only one face is visible at any angle; no flicker at 90°.
- [ ] `MediaQuery.disableAnimations` → swap without rotation.
- [ ] The controller is disposed (no ticker leak warning in tests).
**Verification:** widget tests (pump halfway → back hidden; pump end → back shown; reduced motion path); device: flip looks smooth.
**Dependencies:** T17
**Files:** `lib/core/widgets/game_card/card_back.dart`, `flip_card.dart`, `test/core/widgets/flip_card_test.dart`
**Size:** S

### Task 19: TiltStream
**Description:** `core/sensors/tilt_stream.dart`: `accelerometerEventStream` → low-pass (α 0.15) → clamp [-1, 1] → `Stream<Offset>`; pause/resume with app lifecycle and page visibility. The sensor source is injected so it can be tested.
**Acceptance criteria:**
- [ ] Filter and clamp behave as specified for a scripted input sequence.
- [ ] Pausing cancels the sensor subscription; resuming opens exactly one.
**Verification:** unit tests with a fake sensor stream (values, clamp, subscription count).
**Dependencies:** T2
**Files:** `lib/core/sensors/tilt_stream.dart`, `test/core/sensors/tilt_stream_test.dart`
**Size:** S

### Task 20: flutter_tilt wiring (3D tilt, light, shadow)
**Description:** Wrap `GameCard` in `Tilt` with `enableGestureSensors: false`, `fps: 60`, light + shadow, a `TiltController` fed from `TiltStream`, touch drag on. **First step is a spike:** log `onGestureMove` and confirm whether it fires for `GesturesType.controller`. Record the answer in `.claude/rules/animation-audio.md` (the rule already names both paths).
**Acceptance criteria:**
- [ ] Tilting the phone tilts the card; dragging on the card also tilts it (fallback); releasing returns it to rest.
- [ ] Exactly one accelerometer subscription while the card detail placeholder is open (debug counter in `TiltStream`).
- [ ] A single `ValueListenable<Offset>` exposes the current tilt for the holo (from `onGestureMove`, or from the documented fallback path).
**Verification:** widget test drives the controller and checks the listenable updates; device: tilt + drag on the reference Android device; iOS Simulator: drag works (iPhone sensor check moves to the Week 2 end session).
**Dependencies:** T18, T19
**Files:** `lib/core/widgets/game_card/tilting_game_card.dart`, `lib/features/collection/presentation/pages/card_detail_page.dart` (placeholder), `test/core/widgets/tilting_game_card_test.dart`, `.claude/rules/animation-audio.md`
**Size:** M

### Task 21: Holo shader
**Description:** `shaders/holo.frag` (uniforms `uSize`, `uTilt`, `uStrength`), listed under `flutter: shaders:`; a loader that loads `FragmentProgram` once and caches it; a non-shader fallback (static diagonal sheen) if loading fails; `uStrength` by rarity (common 0 → no shader layer).
**Acceptance criteria:**
- [ ] Holo follows the same tilt value as the 3D tilt (from T20); strength 0 / 0.35 / 0.65 / 1.0 per rarity; legendary shows the rainbow foil.
- [ ] The shader is loaded once per app run, never in `build`.
- [ ] On the reference Android device in `--profile`, 30 s of tilting a legendary card gives ≤ 5% janky frames (early check of SPEC S6); the capture is saved under `docs/perf/`.
**Verification:** unit test for the loader cache + fallback path (forced load failure); device check per rarity; DevTools profile.
**Dependencies:** T20
**Files:** `shaders/holo.frag`, `pubspec.yaml`, `lib/core/widgets/game_card/holo_layer.dart`, `lib/core/widgets/game_card/shader_cache.dart`, `test/core/widgets/shader_cache_test.dart`
**Size:** M

### Checkpoint C: Week 1 complete
- [ ] `flutter analyze --fatal-infos` clean, `flutter test` green
- [ ] `flutter build apk --release --obfuscate --split-debug-info=build/symbols` and `flutter build ios --no-codesign` succeed
- [ ] Device checklist (reference Android device; iOS Simulator for UI only): first sync + offline relaunch; card lab shows 4 rarities; flip; tilt by sensor and by drag; holo per rarity; no jank in profile mode
- [ ] Review with you, then the Week 2 plan

---

## Carry-over to Week 3: battle balance (owner, 2026-11-12)
Add this to the Week 3 battle engine task when the Week 3 plan is written. No code change before then.
- **Problem:** with the current base stats (HP 100, ATK 20, DEF 12) two equal cards need about 6 hits to faint each other (average 6.2 common to 6.8 legendary with `dmg = ATK * 50 / (50 + DEF)`). A 3v3 battle then runs about 36 turns; with the 40-turn limit draws may be frequent and the battle is too long for the jury demo.
- **Simulation:** a seeded simulation of 1000 battles (seeds 0 to 999) with the real engine and AI: equal teams, and teams with rarity gaps (e.g. common vs rare, rare vs epic, common vs legendary, mixed tiers from [GM §6]). Report average turns per battle, draw rate, and win rate by rarity gap. Keep it as a test or a `tool/` script so it can be re-run.
- **Targets:** equal cards faint each other in 3 to 4 hits; 15 to 25 turns per battle; draws < 5%.
- **If off target:** adjust the base ATK/HP ratio (e.g. raise base ATK or lower base HP). **Propose the change with the simulation numbers to the owner first**, then update [GM §4] and the reference values in the same commit.

## Risks and mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Package versions do not resolve on Flutter 3.47.6 (e.g. `hive_ce_generator` with `build_runner`) | High | T2 is resolved and built before any code depends on it; pin working versions in `pubspec.lock` |
| `flutter_tilt` `onGestureMove` does not report controller input | Medium | Spike first in T20; the documented fallback path already exists in the rules |
| `flutter_tilt` API churn (4 major versions so far) | Low | Pin `^4.1.0`; all usage stays in one widget file (`tilting_game_card.dart`) |
| Holo shader too slow on mid-range Android | High | T21 profiles it in Week 1, not Week 4; fallback sheen is ready |
| A chosen font lacks Turkish glyphs | Medium | T4 checks it before any screen uses the fonts; alternatives named in SPEC §5.3 |
| Contrast fails for a palette pair | Low | T3 fixes the token before screens are built |
| Sync slower than expected (about 52 requests) or rate-limited | Medium | Retry/backoff (T10), resumable sync (T14), measured at Checkpoint B |
| iOS issues found late | Medium | Every checkpoint includes an iOS build + Simulator run; real iPhone sessions at Week 2 end and Week 4 |

## Parallelization
- Phase 2 (T7 to T9) needs only T1 and can run alongside Phase 1.
- T10 and T19 need only T2.
- Everything else follows the dependency graph.

## Progress notes

### T1 (2026-11-11)
- Android: `flutter build apk --debug` OK. Not yet run on a device: `flutter devices` found no Android device or emulator.
- iOS: `flutter build ios --no-codesign` OK and `flutter build ios --simulator` OK. **Simulator install not verified.**

### T2 (2026-11-11)
- Packages added at current stable versions (see `pubspec.yaml`); `cupertino_icons` removed (Material Icons only). No `dependency_overrides`.
- `analysis_options.yaml`: `flutter_lints` + strict-casts / strict-inference / strict-raw-types, `avoid_print: error`, const and single-quote rules; `*.g.dart` excluded.
- `flutter pub get`: OK. `flutter analyze --fatal-infos`: no issues (223 s). `flutter test`: 1/1 passed.
- `pod install`: OK (4 pods). It failed first with `Encoding::CompatibilityError` because the shell had no UTF-8 locale; fixed by `LANG`/`LC_ALL=en_US.UTF-8` (now in the owner's `~/.zshrc`). `ios/Podfile` sets `platform :ios, '15.0'`. Remaining CocoaPods warning about the Profile base configuration is the known, harmless Flutter one.
- **APK build: to be re-verified at home.** The first `flutter build apk --debug` ran 20+ min (first Gradle build with native plugins) and was stopped when the session ended. Afterwards `./gradlew assembleDebug` (with `JAVA_HOME` = Android Studio JBR) finished `BUILD SUCCESSFUL in 56s`, but `flutter build apk --debug` itself was stopped again before finishing. Note: `./gradlew` from a plain shell fails with "Unable to locate a Java Runtime" because `JAVA_HOME` is not set; `flutter` finds the JBR on its own.
- **APK build verified 2026-11-12 (Windows machine):** `flutter build apk --debug` → `✓ Built build\app\outputs\flutter-apk\app-debug.apk`. First run took about 34 min (Gradle 9.3.1 download + Build-Tools 36 install), after the Avast truststore fix below.
- `lib/` folder skeleton: not created on purpose (empty folders are not committed; each folder gets its first file in a later task).

### T3 (2026-11-12)
- `AppColors` (SPEC `void` is `voidBase`: `void` is a Dart keyword), `AppMotion`, `AppSpacing`, `AppRadius`, `AppOutline`, `AppDepth` (hard shadow offset).
- Owner decisions: text on rarity frames is `ink`; `warn` changed `#F7B731` → `#FF9F43` (no shared meaning with legendary gold).
- `contrast_test.dart`: 19 pairs, all pass; numbers in SPEC §5.2. Review page `docs/design/palette_preview.html` (placeholder cards only).

### T4 (2026-11-12)
- Static TTFs from Google Fonts with OFL: Grandstander 700/900, Atkinson Hyperlegible Next 400/700. Flutter families `Grandstander`, `AtkinsonHyperlegibleNext`.
- `glyph_test.dart` parses each TTF `cmap` (all 12 Turkish glyphs present) and `GSUB` (`tnum` present), checks the scale, renders a golden. Result in SPEC §5.3: no swap.
- `token_usage_test.dart` enforces SPEC §5.8 T3 over all of `lib/` (except `app/theme`, `l10n`, generated code).

### T5 (2026-11-12)
- `l10n.yaml` (`nullable-getter: false`), `lib/l10n/app_tr.arb`; generated `app_localizations*.dart` are committed. `pubspec.yaml` has `flutter: generate: true`.
- `AppLogger` (`lib/core/logging/`): `dart:developer` log, only when `kDebugMode`; sink injectable for tests. Test also scans `lib/` for `print(`.
- Template counter app and `test/widget_test.dart` removed.

### T6 (2026-11-12)
- `di.dart` (`getIt`, `configureDependencies()`), `router.dart` (`AppRoutes`, `createRouter()`), `placeholder_page.dart`, `not_found_page.dart` (one small file more than planned, same task scope).
- `PortalCardsApp` takes the router as a parameter (`main` passes `getIt<GoRouter>()`), so widget tests need no DI.
- Placeholders show only the title (as planned), so on a device the app stays on the `/splash` placeholder until T15.
- Checks: `flutter analyze --fatal-infos` clean, `flutter test` 57/57, `flutter build apk --debug` OK.

### T7 (2026-11-12)
- 8 character fixtures (ids 1, 2, 23, 63, 71, 82, 86, 309) + `episode_page_1.json` + `location_page_1.json`, raw `curl` output; sources in `test/fixtures/README.md`. Loader: `test/fixtures/fixtures.dart`.
- Coverage: rarities common (63, 71), rare (82, 86, 309), epic (23), legendary (1, 2); all 6 types (86 is Humanoid → Human, 82 is Cronenberg → Neutral); all 3 statuses.

### T8 (2026-11-12)
- `Rarity` (multiplier, holo strength, `fromEpisodeCount`), `CardType` (`fromSpecies`, `strongAgainst`), `Effectiveness` (×1.5 / ×0.75 / ×1). Frame colors stay in `app/theme`.
- `purity_test.dart`: no Flutter / `dart:ui` / Hive / Dio import and no `Random()` in `lib/core/game`.

### T9 (2026-11-12)
- `CardStats.forCharacter(id, rarity)` (equatable), `Passive.fromStatus`, `Passives.zombieReviveHp`, `Passives.attackMultiplier(passive, random)`. English identifiers `zombie` / `uncertain`; UI names Zombi / Belirsiz come from l10n later.
- Hand-computed (Python, independent) stats match: Rick 135/32/17/13, Morty 142/34/18/14, Conroy 94/22/12/9.
- **Balance observation (resolved 2026-11-12, option A applied in `759cf0f`):** `r(id, k) = hash(id*31 + k)` is linear in `k`, so for every card the ATK, DEF and SPD rolls are the HP roll shifted by a fixed 0.618 / 0.236 / 0.854 (mod 1). All 826 stat profiles lie on one curve; corr(HP roll, ATK roll) = -0.41. Possible fix: apply a non-linear mixer (e.g. murmur3 `fmix32`) to the hash. Changing it needs a GM §4 update in the same commit.
- After the mixer: Rick 152/33/17/17, Morty 140/26/16/15, Conroy 85/18/13/11; GM §4 updated in the same commit.
- `flutter analyze --fatal-infos` clean, `flutter test` 138/138 (whole suite).

### T10 (2026-11-12)
- `core/network/dio_client.dart` (`ApiClient`), `retry_interceptor.dart`, `endpoints.dart` (incl. `idFromUrl`), `core/errors/failures.dart` (sealed `Failure`).
- Retries 429, 5xx, timeouts and connection errors (max 3; 500 ms, 1 s, 2 s; `Retry-After` honored, capped 10 s). Other 4xx never. dio 5.11 has a new `transformTimeout` type, mapped to `TimeoutFailure`.
- HTTPS check throws `ArgumentError` (not `assert`), so it also holds in release.
- `token_usage_test` skips `lib/core/network/` (timeouts are not design tokens).

### T11 (2026-11-12)
- Shared entities `Character`, `Episode`, `Location` in `lib/core/entities/` (used by several features; features may not import each other's data layer).
- DTOs + strict `JsonReader` (missing or mistyped field → `FormatException` naming the field → `ParseFailure`). Empty origin/location URL → null id.

### T12 (2026-11-12)
- **Decision:** `path_provider` added as a direct dependency (owner approved); see Decisions.
- `hive_type_ids.dart`, `stored_models.dart` (+ `.g.dart`), `hive_init.dart` (`initHive(dir)`, adapters registered once), `api_data_store.dart` (one `putAll` per page). hive_ce_generator also writes `lib/hive_registrar.g.dart` on every build; committed, not used.

### T13 (2026-11-12)
- `player_state.dart` (`PlayerState`, `PlayerSettings`, `OwnedCard`), `player_store.dart` (`PlayerStore`, `CollectionStore`). Start: 300 coins, settings on, counters 0, created once.
- `core/game/economy.dart` holds `EconomyRules.startingCoins` / `portalCost` so [GM §8] numbers live in `core/game` only; the `Economy` class comes in Week 2.

### T14 (2026-11-12)
- Order: page 1 of characters, episodes, locations (all totals known early), then remaining pages. Each page: write items, then save progress. `PlayerState.syncPages` added (field 13).
- **Real API run (Windows desktop, Wi-Fi, 2 runs):** 52 requests, 17.5 s and 25.6 s; stored 826 characters, 51 episodes, 126 locations = `info.count` of each.

### T15 (2026-11-12)
- `SyncBloc`, `SplashPage` (bar + `%NN` + `downloaded / total`, error message + Tekrar dene, portal dims to 0.05 on error), `PortalLoader` in `core/widgets` (owner requirements above). Splash gets `onDone` from the router (no `features → app/router` import).
- `PortalLoader.onSettled` runs after the frame (it navigates; must not run during build).
- Splash placeholder title removed; DI now opens Hive with `getApplicationSupportDirectory()`.
- Checks: `flutter analyze --fatal-infos` clean, `flutter test` 199/199, `flutter build apk --debug` OK.

### Environment: Windows machine (2026-11-12)
- Flutter SDK at `C:\flutter` pinned to **3.47.6** (`git checkout 3.47.6`; it was 3.38.3 / Dart 3.10.1, which fails `pub get` on `sdk: ^3.13.5`). No iOS work on this machine (`pod install`, iOS builds run on the Mac).
- **Avast HTTPS scanning breaks Gradle downloads.** Avast re-signs TLS with its own root (`CN=Avast Web/Mail Shield Root`); Windows trusts it, Android Studio's JBR does not → `PKIX path building failed`. The JBR has no `SunMSCAPI`, so `trustStoreType=Windows-ROOT` does not work.
- Fix (machine-level, nothing in the repo): a copy of the JBR `cacerts` with the Avast root imported, at `C:\Users\Lenovo\.gradle\truststore\cacerts-avast` (password `changeit`), used via `C:\Users\Lenovo\.gradle\gradle.properties`:
  `systemProp.javax.net.ssl.trustStore=C:/Users/Lenovo/.gradle/truststore/cacerts-avast` and `systemProp.javax.net.ssl.trustStorePassword=changeit`.
- **Redo when:** Avast regenerates its root certificate, or an Android Studio update changes the JBR (its own new CA certs are then missing from the copy). Steps: export the Avast root from `Cert:\LocalMachine\Root` to `.cer`, copy `<Android Studio>\jbr\lib\security\cacerts`, `keytool -importcert -noprompt -alias avast-web-mail-shield-root -file avast-root.cer -keystore cacerts-avast -storepass changeit`, then delete any `*.part`/`*.lck` under `~/.gradle/wrapper/dists/`.
- Alternative: an Avast exclusion for `services.gradle.org`, `dl.google.com`, `repo.maven.apache.org`, `plugins.gradle.org` (then remove the two `systemProp` lines).

### Known issue: iOS Simulator install hangs (retry at Checkpoint C)
- The iPhone 17 simulator boots (`simctl bootstatus`: booted), but `xcrun simctl install` hung for 8+ minutes and `simctl launch` timed out.
- `open -a Simulator` failed: "Unable to find application named 'Simulator'". The Xcode / CoreSimulator setup may be incomplete.
- At Checkpoint C, check `xcode-select -p`, run `xcrun simctl list runtimes`, open Simulator from Xcode (Xcode > Open Developer Tool > Simulator), then retry `flutter run -d <simulator>`.
- Until then, iOS checks in this plan mean "build OK"; UI checks run on the Android device.

## Decisions (2026-11-11)
0. (2026-11-12) Hive directory: `path_provider` added as a direct dependency (it was already in the lockfile through `cached_network_image` → `flutter_cache_manager`); `Hive.init(getApplicationSupportDirectory())`. Listed in `CLAUDE.md`.
1. Packages approved and listed in `CLAUDE.md`: `fpdart`, `flutter_localizations`, `intl`, `build_runner`, `hive_ce_generator`, `flutter_lints`, `bloc_test`, `mocktail`.
2. Reference Android device: see Devices. iOS real-device tests only at Week 2 end and Week 4.
3. Card lab route approved, `kDebugMode` only.
4. Icons: Material Icons; no lucide package. The shake-hint hand is drawn with `CustomPainter` only if the Material icon does not fit the bold-outline style (SPEC §2.3 AC9).
5. Until a device is connected, task verification = `flutter analyze --fatal-infos` + `flutter test` (+ `flutter build apk --debug` when relevant). Device-only checks are collected per task under "To check on device".

## Open questions
- Reference Android device model (TBD in Devices).
