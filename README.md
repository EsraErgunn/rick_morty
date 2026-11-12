# Portal Cards

A Rick and Morty collectible card and battle game for Android and iOS, built with Flutter on the public [Rick and Morty API](https://rickandmortyapi.com/). Graduation project.

> **Fan project, non-commercial.** Rick and Morty, its characters and images belong to Adult Swim / Warner Bros. Discovery. This project is not affiliated with or endorsed by them, is not sold, and will not be released on any app store.

**Game loop:** open a portal → win cards → build a deck → battle → earn coins → open a portal.

## Features

- **First-launch sync:** all characters, episodes and locations are downloaded page by page into a local Hive database (resumes after a failure); afterwards the game works offline. Card images download in the background (owned cards and the deck first).
- **Portal:** shake the phone (or tap the button) to open a portal for 100 coins. A fragment-shader portal charges, bursts and reveals the card with a flip; legendary cards get a red portal, a music sting and a silhouette reveal. The first three portals never give duplicates; duplicates later turn into coins.
- **Cards:** stats are derived deterministically from the character id; rarity comes from the episode count (common / rare / epic / legendary) and drives the frame and the holographic foil shader. Cards tilt in 3D with the phone (accelerometer) or by dragging.
- **Featured characters:** Rick, Morty, Summer, Pickle Rick and Mr. Meeseeks have hand-picked art and a signature ability in battle (for example Rick's "DAHİ!" critical hit and Mr. Meeseeks' "Görev tamam!").
- **Collection:** filter and sort owned cards, open a card for its details, flip it, add it to the deck.
- **Deck builder:** three slots, totals (HP, ATK, DEF, average SPD) and type-triangle coverage (Human → Robot → Alien → Human).
- **Battle:** 3 vs 3 turn-based battles against an AI whose team grows stronger with every three wins (five tiers). The pure-Dart engine resolves a turn into a list of events and the screen replays them: lunge, shake, floating damage numbers, HP bars, "KRİTİK!", "SÜPER ETKİLİ!", "KAÇTI!", faint and Zombi revive, with a 2× speed toggle. Rewards are paid exactly once per battle.
- **Sound and haptics:** 15 sound effects and 3 music tracks, all generated procedurally by `tools/audio` (no stock assets), plus haptic feedback for every key moment. Sound, music and haptics can be switched off in Settings; reduced-motion settings are respected.
- **Settings:** sound / music / haptics toggles, SFX volume, "download all images" with progress, and a hidden demo mode for presentations.

## Screenshots

| Menu | Portal | Legendary reveal |
|---|---|---|
| _screenshot: `docs/screenshots/menu.png`_ | _screenshot: `docs/screenshots/portal.png`_ | _screenshot: `docs/screenshots/legendary.png`_ |

| Collection | Deck | Battle |
|---|---|---|
| _screenshot: `docs/screenshots/collection.png`_ | _screenshot: `docs/screenshots/deck.png`_ | _screenshot: `docs/screenshots/battle.png`_ |

## Tech

Flutter (Dart 3) · flutter_bloc · get_it · go_router · dio · hive_ce · cached_network_image · flutter_animate · fragment shaders (`shaders/portal.frag`, `shaders/holo.frag`) · flutter_tilt · sensors_plus · audioplayers · fpdart.

Clean architecture, feature-first (`lib/features/*/{data,domain,presentation}`); the game rules live in `lib/core/game` as pure, unit-tested Dart (randomness is always injected).

## Run

```sh
flutter pub get
flutter run
```

Tests and analysis:

```sh
flutter analyze --fatal-infos
flutter test
```

Release APK (one per ABI, obfuscated):

```sh
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

Shake and tilt need a real phone; most emulators have no motion sensors (the portal button and drag-to-tilt work everywhere).

## Docs
- `docs/PROJECT.md`: vision, scope and roadmap
- `docs/SPEC.md`: MVP specification
- `docs/balance.md`: battle balance simulation and decisions
- `tasks/plan.md`: implementation plan
