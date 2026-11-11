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
r(id, k)  = hash(id * 31 + k) / 0xFFFFFFFF        // 0.0 – 1.0, k = stat index
vary(x)   = 0.85 + 0.30 * x                       // ±15%

base:  HP 100 · ATK 20 · DEF 12 · SPD 10
stat = round(base * rarityMult * vary(r(id, k)))   // k: HP=0, ATK=1, DEF=2, SPD=3
```
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
- While `player.portalsOpened < 3`, a portal never gives a duplicate.
- Rarity is rolled with the normal table above; the character is picked uniformly from the characters of that rarity the player does **not** own.
- `portalsOpened` increases by 1 after every portal (all portals, not only the first 3).
- Result: every new player owns 3 distinct cards after spending the starting 300 coins, so a deck can always be built.

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
