---
name: rm-game-mechanics
description: Game rules and formulas for Portal Cards (Rick and Morty card game) – API data mapping, rarity, types, stats, passives, battle, AI, portal rolls, economy, albums. Load before writing or changing anything in lib/core/game, cards, portal, battle, deck, album, or rewards.
---

# Portal Cards – Game Mechanics

This file is the **single source of truth** for game rules. Implement every formula once in `lib/core/game/` (pure Dart) and unit test it. If a rule here is unclear or seems unbalanced, ask the user before changing it, then update this file in the same commit.

---

## 1. API → card mapping

| API field | Game meaning |
|---|---|
| `id` | Seed for fixed stats (same character → same stats forever) |
| `name`, `image` | Card name and artwork |
| `episode.length` | Rarity |
| `species` | Type (advantage triangle) or special trait |
| `status` | Passive ability |
| `origin.name` | Card back info; home-dimension bonus (map, stretch) |
| `location.name` | Card back info |
| `/episode/{id}.characters` | Album page members |
| `/location/{id}.residents` | Dimension opponents (map, stretch) |

Extract ids from URLs: `int.parse(url.split('/').last)`.

---

## 2. Rarity

| Episodes | Rarity | Frame color | Holo strength |
|---|---|---|---|
| 1 | Common | grey `#9AA5B1` | 0.0 |
| 2–4 | Rare | blue `#3FA9F5` | 0.35 |
| 5–19 | Epic | purple `#A55EEA` | 0.65 |
| 20+ | Legendary | gold `#F7B731` (+ rainbow foil) | 1.0 |

Rarity multiplier for stats: Common 1.00 · Rare 1.15 · Epic 1.30 · Legendary 1.50.

---

## 3. Types

### Core triangle (arrow = "is super effective against")
**Human → Robot → Alien → Human**

| Species (API) | Type |
|---|---|
| Human, Humanoid | Human |
| Robot | Robot |
| Alien | Alien |
| Animal | Beast (special) |
| Mythological Creature | Myth (special) |
| Cronenberg, Disease, Poopybutthole, unknown, anything else | Neutral |

Type multiplier (attacker vs defender):
- Advantage: **×1.5** → show "SÜPER ETKİLİ!"
- Disadvantage (reverse direction): **×0.75** → show "Pek etkili değil…"
- Otherwise (including Beast/Myth/Neutral): ×1.0

### Special type traits
- **Beast:** acts first in its first turn (speed treated as +∞ on turn 1).
- **Myth:** 10% chance to dodge any attack (damage 0, show "KAÇTI!").

---

## 4. Stats (deterministic from id)

```
hash(n)   = (n * 2654435761) & 0xFFFFFFFF        // Knuth multiplicative hash
mix(h)    = murmur3 fmix32(h):                    // all steps & 0xFFFFFFFF
              h ^= h >> 16; h *= 0x85EBCA6B; h ^= h >> 13; h *= 0xC2B2AE35; h ^= h >> 16
r(id, k)  = mix(hash(id * 31 + k)) / 0xFFFFFFFF   // 0.0 – 1.0, k = stat index
vary(x)   = 0.85 + 0.30 * x                       // ±15%

base:  HP 100 · ATK 40 · DEF 12 · SPD 10          // ATK 20 → 40 on 2026-11-12, see docs/balance.md
stat = round(base * rarityMult * vary(r(id, k)))   // k: HP=0, ATK=1, DEF=2, SPD=3
```
Why `mix` (added 2026-11-12, owner decision): `hash(id * 31 + k)` alone is linear in `k`, so every card's ATK / DEF / SPD roll was its HP roll shifted by a fixed 0.618 / 0.236 / 0.854 (mod 1); all stat profiles lay on one curve (corr(HP, ATK) = -0.41). With `mix` the rolls are independent (|corr| < 0.08 over ids 1–826).

Reference values (tests): Rick (1, legendary) 152/66/17/17 · Morty (2, legendary) 140/53/16/15 · Conroy (71, common) 85/36/13/11 (HP/ATK/DEF/SPD).

**Base ATK raised 20 → 40 (2026-11-12, delivery mode, owner pre-approved the rule):** with ATK 20 equal cards needed ~7 hits, battles ran ~36 turns and 19–44 % ended in a draw. With ATK 40: 3.6–3.9 hits, 15–21 turns, 0 % draws (1000 seeded battles per scenario, `tool/battle_sim.dart`, report in `docs/balance.md`).
Star bonus (merge, stretch): each star ×1.10 on all stats (max 3 stars).

Tests must check: same id → identical stats; legendary average > epic average > rare > common.

---

## 5. Passives (from `status`)

| Status | Passive | Rule |
|---|---|---|
| Alive | — | none |
| Dead | **Zombi** | Once per battle, when HP drops to 0, revive with 30% max HP. Event: `revive`. |
| unknown | **Belirsiz** | On each of its attacks, 50%: damage ×1.2, otherwise ×0.8. |

---

## 6. Battle (3 vs 3, turn-based)

- Each side has 3 cards. Player and AI alternate turns; the side whose fastest alive card has higher SPD starts (tie → player).
- On a turn, the side picks **one of its alive cards** to attack **one alive enemy**.
- Damage:
```
crit     = random < 0.10 ? 1.5 : 1.0
dmg      = max(1, round(ATK * typeMult * crit * passiveMult * (50 / (50 + DEF))))
dmg      = min(dmg, attacker ATK)        // cap: one hit never exceeds the attacker's ATK stat
```
- A card at HP ≤ 0 faints (unless Zombi revives it).
- Battle ends when one side has no alive cards. Turn limit 40 → draw.
- The engine returns `List<BattleEvent>`: `turnStart, attack, dodge, damage(amount, isCrit, effectiveness), faint, revive, turnEnd, victory, defeat, draw`. The UI only replays events.

### AI (simple, readable)
1. If any AI card has type advantage over an alive player card → use the strongest such pair (highest expected damage).
2. Else attack the player card with the **lowest current HP**, using the AI card with the highest ATK.
3. Use the same damage formula (with the injected Random) – no cheating.

### Opponent generation
Difficulty tier = number of wins / 3 (max 4). Opponent rarities by tier:
- Tier 0: 3 Common · Tier 1: 2 Common + 1 Rare · Tier 2: 1 Common + 2 Rare · Tier 3: 2 Rare + 1 Epic · Tier 4: 1 Rare + 1 Epic + 1 Epic/Legendary (10% legendary)

---

## 7. Portal (card roll)

- Cost: **100 coins** per portal.
- Roll rarity first, then a uniform random character from that rarity pool:

| Rarity | Chance |
|---|---|
| Common | 60% |
| Rare | 28% |
| Epic | 10% |
| Legendary | 2% |

- Legendary → play the legendary cinematic (red portal, music change, silhouette reveal).
- Pity (stretch): no Epic+ in 10 pulls → next is Epic+. No Legendary in 50 pulls → next is Legendary.

### 7.1 First portals (no duplicates)
- **Starter Rick (owner decision 2026-11-13):** the very first portal (`portalsOpened == 0`) gives Rick (id 1) if he is not owned, without a rarity roll, so every player sees his 2.5D card and battle reactions. It plays the legendary cinematic like any legendary. Players who opened portals before this rule and do not own Rick get one copy once at startup (`player.starterChecked`).
- While `player.portalsOpened < 3`, a portal never gives a duplicate.
- Rarity is rolled with the normal table above; the character is picked uniformly from the characters of that rarity the player does **not** own.
- `portalsOpened` increases by 1 after every portal (all portals, not only the first 3).
- Result: every new player owns 3 distinct cards (Rick + 2 rolled) after spending the starting 300 coins, so a deck can always be built.

### 7.2 Demo overrides (hidden demo mode)
- Unlock: 7 taps on the version label in Settings within 3 s. Stored as `player.demoUnlocked`; "Demo modunu kapat" sets it back to false.
- **+1000 coin:** goes through `Economy` with reason `demo`, like every other coin change.
- **Next portal Legendary:** arms a one-shot flag `player.forceNextLegendary`. The next portal skips the rarity roll and uses Legendary (the character pick and §7.1 / §7.3 still apply). The flag is cleared when that portal's result is saved.
- The portal still costs 100 coins. Demo mode changes nothing else (no stat, battle or reward changes).

### 7.3 Empty pool fallback
- Applies whenever a rule needs an unowned character of a rarity (§7.1) and none is left.
- Step down one rarity at a time (Legendary → Epic → Rare → Common) until a rarity has an unowned character; pick uniformly from it.
- If the player owns every character, the portal gives a normal (duplicate) result from the originally rolled rarity.

---

## 8. Economy

| Event | Coins |
|---|---|
| New player start | 300 |
| Victory | 100 + 25 × tier |
| Defeat | 25 |
| Draw | 50 |
| Duplicate card (before merge exists) | Common 20 · Rare 40 · Epic 80 · Legendary 200 |
| Album page completed | min(500, 150 + 10 × members) |

Coins can never go below 0. All coin changes go through one `Economy` class so they are testable and logged.

---

## 9. Episode album

- One page per episode (`/episode`), sorted by season/episode code (`S01E01`).
- A page shows silhouettes for missing characters and artwork for owned ones.
- Completed when the player owns every character in `episode.characters` → reward once (store `completedAlbums`).
- Show progress `owned / total` on each page and overall.

---

## 10. Dimension map (stretch)

- Each location with ≥ 3 residents is a planet. Unlock order: by id.
- Opponents are drawn from that location's residents (fill with random cards of the right tier if fewer than 3 are usable).
- Home bonus: a card whose `origin.name` equals the location name gets **+10% ATK** there.
- Beating a planet unlocks the next one and gives a one-time 150-coin reward.

---

## 11. Merge (stretch)

- 3 copies of the same character → 1 card with +1 star (max 3 stars). Extra copies after 3 stars → duplicate coins.
- Merge animation: three cards orbit, collide, flash, single card pops in with the new star.

---

## 12. Featured characters (MVP: 5) — added 2026-11-12

Featured characters keep their normal **rarity, type, stats, passive and portal chances** (§2 to §5, §7), except the starter Rick rule (§7.1). They only add a special frame, a signature ability (battle, Week 3) and an entrance cinematic (portal, Week 2).

| id | Character | Rarity (episodes) | Type | Passive |
|---|---|---|---|---|
| 1 | Rick Sanchez | Legendary (51) | Human | — |
| 2 | Morty Smith | Legendary (51) | Human | — |
| 3 | Summer Smith | Legendary (42) | Human | — |
| 242 | Mr. Meeseeks | Epic (5) | Human (Humanoid) | Belirsiz |
| 265 | Pickle Rick | Common (1) | Neutral (species "unknown") | — |

The list is a constant in `core/game/featured.dart` (ids only; names come from the API).

### 12.1 Frame
Rarity frame unchanged + 2-unit `portal` green inner line + featured badge (Material `stars` icon) on the name plate (SPEC §5.5).

### 12.2 Signature abilities — **approved 2026-11-12**
Rules for all signatures (numbers approved by the owner 2026-11-12): deterministic except where they use the battle's injected `Random`; each one emits a `signature` BattleEvent (character id) so the UI can show it (Rick's crit is reported as a `crit` event with `signature: dahi`, so the UI swaps the text and sound); they multiply into the damage formula as `signatureMult` (default 1.0) after `passiveMult`; at most one trigger per battle unless stated.

| Character | Name (UI) | Rule | Expected effect |
|---|---|---|---|
| Rick | **Dahi** | Crit chance 20 % instead of 10 % (§6). Always on. Rick's crits show **"DAHİ!"** instead of the normal crit text and play `genius_crit` instead of `crit_hit`. | Average damage ×1.05 (1.05 → 1.10 expected multiplier). |
| Morty | **Aman tanrım!** | Once per battle, the first time his HP drops to ≤ 30 % of max (and he is still alive), his **next** attack deals ×1.5. | One boosted hit in a ~6-hit fight: about +8 % of his output, only when he is losing. |
| Summer | **Takım ruhu** | Once per battle, when an ally on her side faints, her ATK is ×1.2 for the rest of the battle. | Matters only after the team loses a card; comeback help. |
| Mr. Meeseeks | **Görev tamam** | Once per battle, when his attack makes an enemy faint, he heals 20 % of his max HP (not above max). Stacks with Belirsiz. On trigger the UI shows **"Görev tamam!"** with a short "poof" smoke puff and plays `meeseeks_poof`. | About one extra hit of survival for an epic card. |
| Pickle Rick | **Turşu zırhı** | The first attack he receives in a battle deals ×0.5 damage. | Half a hit of extra HP for a common card; keeps him common-tier. |

Balance check (Week 3, with the battle simulation in `tasks/plan.md` "Carry-over to Week 3"): a team with one featured card vs the same team with a non-featured card of the same rarity and type wins 50 % ± 8 % over 1,000 seeded battles. If not, tune the numbers above (owner approves the change).

### 12.3 Entrance cinematic (portal, Week 2)
After the reveal scene lands the card (SPEC §4.3), the art window is empty; the character image falls out of the portal with the same gravity curve and squashes into the window, the featured frame line draws around the card, and the name is shown as a short `callout`. Rick, Morty and Summer are legendary, so this runs inside the legendary cinematic (red portal, music sting). Battle signature animations come in Week 3.
