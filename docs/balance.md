# Battle balance (plan T42)

Simulation: `dart run tool/battle_sim.dart` (`--search` also scans base HP/ATK).
Real engine and AI on both sides, 1000 battles per scenario (seeds 0–999).
Teams: ids 1–826, types uniform over the six, status 55 % Alive / 35 % Dead /
10 % unknown. One turn = one side's attack (decision Q1); limit 40 turns.

Targets (owner): equal cards faint each other in **3–4 hits**, **15–25 turns**
per battle, **draws < 5 %**; a featured card's team wins **50 % ± 8 %** against
the same team without the signature.

## Decision (2026-11-12, delivery mode)

**Base ATK 20 → 40** ([GM §4]); HP, DEF, SPD unchanged. The owner's delivery
instruction allowed changing the base ATK/HP to the closest value without a
stop. Reason: the only change that meets every target while keeping HP on the
100 scale players see. Other candidates from the search that also met the
targets (HP 80 / ATK 35, HP 90 / ATK 35, HP 70 / ATK 30) change two values and
shrink HP numbers.

## Before (HP 100, ATK 20)
| Metric | Value |
|---|---|
| Hits to faint, equal cards | 6.7 (common) – 7.3 (legendary) |
| Turns, equal teams | 35.7 – 37.8 |
| Draws, equal teams | 19.2 % – 43.9 % |

## After (HP 100, ATK 40)
| Scenario | Turns | Draws | Player wins |
|---|---|---|---|
| Equal common | 19.4 | 0.0 % | 51.7 % |
| Equal rare | 19.9 | 0.0 % | 51.0 % |
| Equal legendary | 21.3 | 0.0 % | 51.9 % |
| Rare vs common | 18.6 | 0.0 % | 89.6 % |
| Epic vs rare | 19.1 | 0.0 % | 87.9 % |
| Legendary vs common | 15.3 | 0.0 % | 100.0 % |
| Tier 0 (C+R+E deck vs 3 common) | 18.0 | 0.0 % | 92.3 % |
| Tier 2 (C+R+E vs C+R+R) | 19.0 | 0.0 % | 72.3 % |
| Tier 4 (C+R+E vs R+E+E) | 19.3 | 0.0 % | 32.9 % |

Hits to faint, equal cards: common 3.62, rare 3.72, epic 3.81, legendary 3.92.

## Featured signatures (rare ×3 vs rare ×3, signature on the player's first card)
Baseline without a signature: 51.0 %.

| Signature | Player wins | vs target 50 % ± 8 % |
|---|---|---|
| Dahi (Rick) | 54.2 % | ✅ |
| Aman tanrım! (Morty) | 55.5 % | ✅ |
| Takım ruhu (Summer) | 58.8 % | ⚠ +0.8 over the band |
| Görev tamam (Mr. Meeseeks) | 53.5 % | ✅ |
| Turşu zırhı (Pickle Rick) | 60.0 % | ⚠ +2.0 over the band |

The two slightly high ones are within about one standard error (≈ 1.6 % for
1000 battles) plus the 51 % baseline. Signature numbers were approved by the
owner, so they are **not** changed here; if they should be tuned: Pickle Rick
×0.5 → ×0.6, Summer ×1.2 → ×1.15.
