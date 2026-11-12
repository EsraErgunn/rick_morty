# CLAUDE.md

## Project
**Portal Cards** (working title) – a Rick and Morty collectible card + battle game built on the public Rick and Morty API.
Loop: open portal → win cards → build deck → battle across dimensions → earn rewards → open portal.
Course graduation project (bitirme projesi). Hard requirement from the teacher: **animations and sound effects**.
Vision, scope and roadmap: `docs/PROJECT.md` (read before planning a new feature).
Game rules and formulas: the `rm-game-mechanics` skill (load it before touching cards, rarity, stats, battle, economy).

- Flutter (stable) · Dart 3 · **Android + iOS**
- State: **flutter_bloc** (+ equatable) · DI: get_it · Routing: go_router
- Network: dio · Local DB: hive_ce (+ path_provider for the Hive directory) · Images: cached_network_image
- Animation: flutter_animate, CustomPainter, **fragment shaders** (`shaders/*.frag`) · no Rive, no Flame
- Card 3D tilt: flutter_tilt ^4.1.0 (driven by our `TiltStream`; its own sensor input is off)
- Sensors: sensors_plus · Haptics: `HapticFeedback` · Audio: audioplayers
- Errors: fpdart (`Either`) · l10n: flutter_localizations + intl
- Dev: build_runner, hive_ce_generator, flutter_lints, bloc_test, mocktail
- Security risk profile: **L1 – Basic** → @docs/security-profile.md
- Package / bundle ID: `com.esraergun.portalcards` (change both together if renamed)

## Commands
- Run:        `flutter run`
- Test:       `flutter test`
- Analyze:    `flutter analyze --fatal-infos`
- Codegen:    `dart run build_runner build --delete-conflicting-outputs`
- Release:    `flutter build apk --release --obfuscate --split-debug-info=build/symbols`
- iOS:        `cd ios && pod install` after adding a plugin with native code

## Architecture (Clean Architecture, feature-first)
```
lib/
  app/                 # App widget, router, DI setup (get_it), theme
  core/
    audio/             # AudioService (sfx pool + music), settings-aware
    haptics/           # HapticsService wrapper
    sensors/           # ShakeDetector, TiltStream
    network/           # Dio client, API endpoints
    storage/           # Hive init, boxes, adapters
    game/              # PURE DART game engine: stats, rarity, types, battle, AI, economy
    widgets/           # shared widgets (GameCard, buttons, dialogs)
    errors/            # Failure types
  features/
    sync/              # first-launch download of characters/episodes/locations
    portal/            # open portal (shake), reveal animations, legendary cinematic
    collection/        # owned cards grid, filters, card detail (flip + holo)
    deck/              # deck builder (3 cards)
    battle/            # 3v3 turn-based battle screen
    album/             # episode album pages
    map/               # dimension map (stretch goal)
    settings/          # sound / music / haptics toggles
    <feature>/{data,domain,presentation/{bloc,pages,widgets}}
shaders/               # portal.frag, holo.frag
assets/audio/{sfx,music}/
```
- Dependency direction: presentation → domain ← data. Domain has no Flutter imports.
- `core/game/` is **pure Dart**: no Flutter, no Hive, no Dio. Every formula there is unit tested.
- Randomness is always injected (`Random` parameter or seed). Never call `Random()` inside game logic.
- Features never import each other's `data/` or `presentation/`. Shared things go to `core/`.

## Code rules
- Repositories return `Either<Failure, T>` (fpdart); no exceptions reach the UI.
- One Bloc per screen flow; states are immutable (`Equatable`, `copyWith`).
- Animation durations, curves, colors and sizes come from `app/theme/` tokens, never magic numbers in widgets.
- All sound goes through `AudioService`, all vibration through `HapticsService`. Both respect the settings toggles.
- Images: always `CachedNetworkImage` with a placeholder and error widget.
- No `print()`; use `AppLogger` (debug only).
- Widgets > ~150 lines → split. Prefer `const`.
- UI text in Turkish via l10n (`lib/l10n/app_tr.arb`); code, comments and identifiers in English.

## Rules files
Topic rules in `.claude/rules/` (architecture, animation & audio, testing) load automatically. Follow them.

## Security (L1)
- No secrets in code (the API needs no key). HTTPS only. No `print()` of data.
- Release builds use `--obfuscate`. Full rules: `docs/SECURITY_GUIDELINES.md` (read before touching network, storage or build config).

## Workflow
- Use the **agent-skills** plugin for the engineering cycle: spec → plan → build → test → review.
  New feature = short spec + plan first, wait for my approval, then build in small steps.
- Use **frontend-design** for screen design and UI polish decisions.
- Work in roadmap order (`docs/PROJECT.md`). Do not start stretch goals before the MVP is done.
- Do not add packages that are not listed above without asking; explain why.
- Before saying a task is done: `flutter analyze` + `flutter test` pass, and you tell me what to check on a real device (animations, sound, sensors).
- Ask when a requirement is unclear instead of guessing.

## Git
- Commit messages in English, Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- Small commits, one logical change each.
- Never commit `build/`, `.env`, `key.properties`, `*.jks`, `build/symbols/`.

## Gotchas
- Rick and Morty API pages have 20 items; read totals from `info.count` / `info.pages`, never hard-code counts.
- Multiple items in one request: `/character/1,2,3` (returns a list; a single id returns an object).
- Episode `characters` and location `residents` are lists of **URLs**; extract the id from the URL end.
- Sensors do not work on most emulators/simulators: test shake and tilt on a real phone.
- Fragment shaders must be listed under `flutter: shaders:` in `pubspec.yaml`.
- iOS minimum version is **15.0** (`platform :ios, '15.0'` in `ios/Podfile`, matches Flutter's default). Raise it only if a plugin requires it, and update both the Podfile and the Xcode deployment target.
- Golden tests are tagged `golden` and use **Windows as the reference platform** (font rasterization differs per OS). `dart_test.yaml` skips the tag on macOS automatically. Update goldens only on Windows: `flutter test --update-goldens --tags golden`. New golden tests must get `tags: ['golden']`.
- Characters and images belong to Adult Swim: this is a non-commercial fan project (README must say so). Do not prepare store release.
