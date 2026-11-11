# Portal Cards – Project Overview

## 1. Why this project?

**For the player:** The Rick and Morty API holds roughly 800+ characters, 50+ episodes and 120+ locations, but on its own it is an encyclopedia: you browse a list and leave. Portal Cards turns that passive data into a loop of **discovery, collection and competition**. Fans pull characters out of portals, complete episode albums and conquer dimensions.

**For the jury (engineering problem):** How do you turn a ready-made REST API into meaningful product mechanics?
- Raw data becomes game rules with **deterministic formulas**: `episode.length` → rarity, `species` → type advantage, `status` → passive ability, `id` → fixed stats.
- **All three endpoints** drive a mechanic: `/character` → cards, `/episode` → albums, `/location` → dimension map.
- **Offline-first:** data is synced once, images are cached, progress is stored locally.
- **Animation, sound, haptics and sensors** work together as a designed experience, not as a checkbox for the requirement.

One-sentence pitch: *"We turned static API data into a playable collectible card game with deterministic rules."*

## 2. Game loop
Portal → cards → deck → battle → rewards (coins) → portal

## 3. Features and scope (3–4 weeks)

| Layer | Feature | Status |
|---|---|---|
| **MVP – core** | Data sync + offline storage | Must |
| | Card stats engine (rarity, type, stats, passives) | Must |
| | GameCard widget: front/back, flip, rarity frames | Must |
| | Portal opening: coded portal shader, reveal animation, sounds, haptics | Must |
| | Collection + card detail | Must |
| | Deck builder (3 cards) | Must |
| | 3v3 turn-based battle + simple AI + rewards | Must |
| | Sound system (sfx + 3 music tracks) + settings toggles | Must |
| **MVP – wow** | Shake phone to open portal | Must |
| | Holographic tilt effect (by rarity) | Must |
| | Legendary cinematic | Must |
| | Episode album (uses `/episode`) | Must |
| **Stretch** | Dimension map (uses `/location`) | If time |
| | Card merge (3 copies → star up) | If time |
| | Pity counter, daily free portal | If time |

## 4. Screens
Splash (portal + sync progress) → Main menu → Portal → Collection → Card detail → Deck → Battle → Album → (Map) → Settings

## 5. Roadmap

**Week 1 – Foundation**
- Project setup, packages, lints, folder structure, DI, router, theme tokens
- API client + models; first-launch sync into Hive (with progress on splash)
- `core/game`: rarity, type, stats, passives + unit tests
- GameCard widget: front/back, flip animation, rarity frames
- Holographic shader on the card (tilt-driven)

**Week 2 – Portal & collection**
- Portal shader (idle / charging / opening / legendary states)
- ShakeDetector + HapticsService + AudioService
- Portal flow: coin cost → rarity roll → card reveal; legendary cinematic
- Collection grid with filters (rarity, species), card detail page

**Week 3 – Battle**
- Deck builder
- Battle engine in `core/game` (pure Dart, seeded, fully tested) + AI
- Battle screen: attack lunge, shake, floating damage, HP bar, "SÜPER ETKİLİ!", victory/defeat
- Rewards and economy

**Week 4 – Album, polish, demo**
- Episode album + completion rewards
- Stretch goals only if all above is done
- Sound/haptic polish, empty and error states, iOS device test
- README (with fan-project disclaimer, screenshots, GIFs), demo rehearsal

## 6. Demo plan (first 30 seconds)
Hand the phone to the jury → they shake it → portal opens → card flies out → they tilt it and see the holo foil. Then: battle, album, "all three endpoints are game mechanics".

## 7. Risks
- **Balance:** test the stats formula early with known characters (Rick, Morty, a 1-episode character).
- **Performance:** shaders and particles must stay at 60 fps on a mid-range Android phone; profile in `--profile` mode.
- **Copyright:** non-commercial fan project; no store release.
- **Sensors:** emulators cannot test them; keep a real device available.
