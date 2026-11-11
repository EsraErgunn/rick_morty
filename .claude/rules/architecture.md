# Architecture Rules

## Layers
- `domain/`: entities, repository interfaces, use cases. Pure Dart. No `package:flutter`, no Hive, no Dio.
- `data/`: DTO models (`fromJson`), remote/local data sources, repository implementations. Maps DTO → entity.
- `presentation/`: Blocs, pages, widgets. Talks only to use cases / repositories via DI.

## Game engine (`lib/core/game/`)
- Pure Dart. Contains: `rarity.dart`, `card_type.dart`, `card_stats.dart`, `passives.dart`, `battle_engine.dart`, `battle_ai.dart`, `economy.dart`, `portal_roll.dart`.
- Functions are deterministic: the same inputs (and the same seed) always give the same result.
- `Random` is always passed in. Tests use fixed seeds.
- The battle engine produces a list of **BattleEvents** (attack, damage, crit, superEffective, faint, revive, turnEnd, victory, defeat). The UI replays these events as animations. The engine never waits for animations.
- Formulas and constants are defined only in the `rm-game-mechanics` skill and implemented once in `core/game`. Never duplicate a formula in UI code.

## Data sync
- First launch: download all characters, episodes and locations page by page into Hive. Show progress on the splash screen.
- Store a `syncVersion` + timestamp. Later launches work fully offline.
- If the sync fails mid-way: keep what was saved, retry from the last page, show a friendly retry button.
- Network calls: timeouts (15 s), retry with backoff on 429/5xx (max 3).

## Bloc conventions
- File names: `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`.
- Events are past-tense or imperative and specific: `PortalShaken`, `PortalOpenRequested`, `CardRevealed`.
- State has a `status` enum (`initial, loading, success, failure`) plus data fields.
- Side effects that are not state (sound, haptics, navigation) are triggered from `BlocListener`, not inside widgets' `build`.

## Hive
- One box per aggregate: `characters`, `episodes`, `locations`, `collection`, `player` (coins, settings, progress).
- Type adapters generated with `hive_ce_generator`; type IDs are listed in `lib/core/storage/hive_type_ids.dart` and never reused.

## Naming
- Files `snake_case.dart`, classes `PascalCase`, private members `_camelCase`.
- Widgets that are screens end with `Page`; reusable pieces end with descriptive nouns (`GameCard`, `HpBar`, `DamageNumber`).
