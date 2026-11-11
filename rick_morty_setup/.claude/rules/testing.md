# Testing Rules

## What must be tested
- **`lib/core/game/` – every public function.** Rarity thresholds, stat formula (same id → same stats), type advantage table, passives, damage, battle engine events, AI choices, portal roll probabilities, economy.
- Every Bloc: `bloc_test` for each event → expected state sequence.
- Repositories: DTO → entity mapping, offline fallback, error → `Failure`.
- Key widgets: `GameCard` (front/back, rarity frame), `HpBar`. Golden tests are optional.

## How
- Packages: `flutter_test`, `bloc_test`, `mocktail`.
- Randomness: always a fixed seed. Probability tests: roll 10,000 times with a seed and check ranges (± 2%).
- Battle tests assert the **event list**, not the UI.
- Test path mirrors source: `lib/core/game/card_stats.dart` → `test/core/game/card_stats_test.dart`.
- Test names describe behavior: `'Rick (51 episodes) is legendary'`, `'Human attacking Alien is super effective'`.

## Fixtures
Save real API responses as JSON in `test/fixtures/` (Rick id 1, Morty id 2, and at least one single-episode character) so balance problems show up in tests.

## Definition of done
`flutter analyze --fatal-infos` clean + `flutter test` green + a short manual device checklist for the user when the change involves animation, sound or sensors.
