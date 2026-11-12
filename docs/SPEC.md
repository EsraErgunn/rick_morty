# Spec: Portal Cards MVP

Status: **approved** (2026-11-11)
Sources: `CLAUDE.md`, `docs/PROJECT.md`, `docs/security-profile.md`, `.claude/rules/*`, `.claude/skills/rm-game-mechanics/SKILL.md`.
Those files are binding. This spec does not restate formulas: it points to the skill section (written as `[GM §n]`) and only adds what was missing.

---

## 0. Decisions added by this spec

These were missing or conflicting in the sources and were decided with the owner on 2026-11-11.

| # | Gap | Decision |
|---|---|---|
| D1 | New player has 300 coins = 3 portals, but duplicates pay coins instead of a card, so the player could end with < 3 distinct cards and no way to build a deck. | **The first 3 portals never give a duplicate.** Rarity is rolled with the normal table [GM §7]; the character is then picked uniformly from the *unowned* characters of that rarity. Tracked by `player.portalsOpened`. |
| D2 | The jury demo starts with a portal, but each portal costs 100 coins. | **Hidden demo mode.** Tapping the version label in Settings 7 times opens a demo panel: "+1000 coin" and "Sonraki portal Legendary" (one-shot). Works in release builds, invisible to normal players. All coin changes still go through `Economy` with reason `demo`. |

| D3 | D1 needs an unowned character of the rolled rarity, but the legendary pool is small. | If no unowned character is left in the rolled rarity, step down one rarity at a time until one is found. |
| D4 | No tutorial, but first-time players must learn to shake. | On the first visit to the portal screen, show the hint "Telefonu salla!" with an animated shaking-hand icon, once; persisted as `player.shakeHintSeen`. |

D1, D2 and D3 are recorded in `rm-game-mechanics` as [GM §7.1–§7.3].

### Assumptions (approved 2026-11-11)
1. Portrait orientation only.
2. One deck slot (exactly 3 cards). No saved deck presets.
3. UI is Turkish only (`app_tr.arb`); no language switch.
4. Minimum OS = Flutter stable defaults (Android API 21+, iOS 13+). Real-device testing on one mid-range Android phone (the "reference device") and one iPhone.
5. Opponent card art may not be cached offline; a silhouette fallback is acceptable.
6. No tutorial screen. The first-launch flow (sync → main menu with a pulsing portal) teaches the loop, plus the one-time shake hint on the portal screen (D4).

---

## 1. Objective and success criteria

**What:** An offline-first Flutter game (Android + iOS) that turns the public Rick and Morty API into a collectible card + 3v3 battle loop:
portal → cards → deck → battle → coins → portal.

**For whom:** Rick and Morty fans (players) and the graduation jury (evaluators). The teacher's hard requirement is **animations and sound effects**.

**Why:** Showing that static REST data can become deterministic game rules, with all three endpoints (`/character`, `/episode`, `/location`) used as data. In the MVP, `/location` is synced and shown on the card back; the dimension map that turns it into a mechanic is stretch.

### Success criteria (MVP is done when all are true)

| ID | Criterion | How it is checked |
|---|---|---|
| S1 | First-launch sync downloads every page of characters, episodes and locations (counts read from `info.count`) into Hive. | Box sizes equal `info.count` for all three; integration test with fixtures + manual run. |
| S2 | After S1, the app starts and is fully playable in airplane mode. | Manual: kill app, airplane mode, play portal + battle + album. |
| S3 | All `core/game` public functions are unit tested; tests cover every formula in [GM §2–§9] plus D1/D2. | `flutter test` green; one test file per `core/game` file. |
| S4 | `flutter analyze --fatal-infos` clean, `flutter test` green. | CI-style local run before every "done". |
| S5 | Every interaction listed in §4 produces its visual + sound + haptic feedback, and each respects its settings toggle. | Manual device checklist (§4.10). |
| S6 | Portal and holo shaders, battle animations and legendary cinematic stay smooth on the reference Android device: in `flutter run --profile`, the DevTools frame chart shows ≤ 5% janky frames (> 16 ms) over a 30 s portal + battle session. | DevTools profile capture saved under `docs/perf/`. |
| S7 | **Jury demo:** a jury member (synced app, demo mode used beforehand) can go from the main menu to a revealed card by shaking the phone, in ≤ 30 s and without instructions beyond "salla". | Rehearsal with someone who has never seen the app. |
| S8 | Demo script (§6.1) runs end to end twice in a row without a crash or a stuck state. | Rehearsal on the reference device and on the iPhone. |
| S9 | README contains the non-commercial fan-project disclaimer, screenshots and at least 2 GIFs (portal, battle). | Review. |
| S10 | Release APK built with `--obfuscate --split-debug-info`; no `print()` in `lib/`. | Build command + `grep -r "print(" lib/` empty. |

---

## 2. MVP screens and acceptance criteria

Route map (go_router):
`/splash` → `/` (main menu) → `/portal`, `/collection`, `/collection/:id`, `/deck`, `/battle`, `/album`, `/album/:episodeId`, `/settings`.

Every screen has: a loading state, an empty state (if it shows a list), an error state with a retry action, and a `BlocListener` for sound/haptics/navigation [architecture rules].

### 2.1 Splash + sync (`features/sync`)
- **AC1** On first launch, a progress bar shows `downloaded / total` items across the three resources; totals come from the first page's `info.count`.
- **AC2** Each page is written to Hive as soon as it arrives; `syncProgress` stores the last completed page per resource.
- **AC3** If the network fails: what was saved stays saved; a message "Bağlantı koptu. Kaldığın yerden devam edeceğiz." and a "Tekrar dene" button appear; retry resumes from the next page (no page fetched twice when the retry succeeds).
- **AC4** Requests: 15 s timeout, max 3 retries with backoff on 429/5xx [architecture rules].
- **AC5** When sync completes, `syncVersion` + timestamp are stored; later launches skip the network and reach the main menu in ≤ 2 s on the reference device (cold start, measured with a stopwatch, 3 runs).
- **AC6** Starting player state is created once: 300 coins [GM §8], empty collection, settings all on.

### 2.2 Main menu
- **AC1** Shows the coin balance, the idle portal (hero, see §5), and entries to Portal, Collection, Deck, Battle, Album, Settings.
- **AC2** "Savaş" is disabled until the deck has 3 cards, with the hint "Destene 3 kart ekle".
- **AC3** If the collection is empty, the portal entry pulses (the only animated call to action on the screen).
- **AC4** `menu_loop` music plays (fade in) when music is on.

### 2.3 Portal (`features/portal`)
- **AC1** Opening a portal costs 100 coins [GM §7]; it can be triggered by shake (ShakeDetector thresholds in the sensors rules) **or** by the "Portalı aç" button.
- **AC2** With < 100 coins: no coins are spent, the coin counter shakes, and a message "Portal için 100 coin gerekli. Savaşarak coin kazan." with a "Savaşa git" action appears (disabled if no deck).
- **AC3** Rarity roll follows [GM §7]; first-portal guarantee [GM §7.1] applies for `portalsOpened < 3` with the step-down fallback [GM §7.3]; the demo override [GM §7.2] applies when armed, then disarms.
- **AC4** A new card is added to the collection; a duplicate adds coins by rarity [GM §8] and shows the amount.
- **AC5** Portal states map to the shader uniform `uIntensity`: idle 0.15, charging 0.15 → 1.0, opening 1.0, legendary uses `uColor` red [shader rules].
- **AC6** Shake is ignored while a portal is already charging/opening/revealing, and during the 1.5 s cooldown.
- **AC7** Sensor subscriptions pause when the screen is not visible or the app is in background.
- **AC8** Coins are deducted and the card is persisted **before** the animation starts (killing the app mid-animation never loses a card or refunds coins).
- **AC9** First visit only (D4): while `player.shakeHintSeen` is false, the idle portal shows the hint "Telefonu salla!" with a hand icon (Material Icons, vector, no emoji; no lucide package) that rocks left and right. If the Material hand icon does not match the thick ink-outline style (§5), only this icon is drawn with a `CustomPainter`. The hint hides as soon as a portal opens (by shake or button); `shakeHintSeen` is then saved as true, and the hint never appears again, including after an app restart. "İlerlemeyi sıfırla" resets it.

### 2.4 Collection (`features/collection`)
- **AC1** Grid of owned cards (3 columns on phone), each a `GameCard` front with its rarity frame.
- **AC2** Filters: rarity (multi) and type (Human, Robot, Alien, Beast, Myth, Neutral). Sort: rarity desc (default), name, newest.
- **AC3** Header shows `owned / total characters`.
- **AC4** Empty state: "Henüz kartın yok. İlk portalını aç." + button to Portal.
- **AC5** Grid with 100+ cards scrolls smoothly (lazy builder; images via `CachedNetworkImage` with placeholder + error widget).

### 2.5 Card detail
- **AC1** Large `GameCard`; tap flips it (Y-axis, perspective, face swap at 90° [animation rules]).
- **AC2** Front: art, name, rarity, type, HP/ATK/DEF/SPD, passive name. Back: species, status, origin, last location, episode count.
- **AC3** Holo effect: `holo.frag` driven by `TiltStream`, strength by rarity [GM §2]; drag-to-tilt fallback; common cards show no holo.
- **AC4** "Desteye ekle / Desteden çıkar" action (disabled with reason if the deck is full).
- **AC5** Stats shown equal `core/game` output for that id (no formula in UI).

### 2.6 Deck builder (`features/deck`)
- **AC1** Three slots at the top, owned cards below; tap a card to fill the first empty slot, tap a slot to empty it.
- **AC2** A card cannot be in the deck twice.
- **AC3** Shows deck totals (sum HP, ATK, DEF, average SPD) and the type triangle coverage.
- **AC4** Deck is persisted immediately; reopening the app restores it.

### 2.7 Battle (`features/battle`)
- **AC1** Pre-battle: shows the opponent's 3 cards (generated by tier [GM §6]) and the player's deck; "Başla".
- **AC2** Turn order and damage follow [GM §6]; Beast, Myth, Zombi, Belirsiz behave as in [GM §3, §5].
- **AC3** Player turn: tap one own alive card, then one alive enemy; invalid targets (fainted) cannot be selected. AI turn runs automatically.
- **AC4** The engine is called per turn and returns `List<BattleEvent>`; the UI replays events in order and blocks input until the replay ends. The engine never waits for the UI.
- **AC5** Ends in victory / defeat / draw (turn 40); rewards [GM §8] are credited exactly once, before the result animation, and `wins` updates the tier.
- **AC6** Leaving mid-battle asks "Savaştan çıkılsın mı? Bu savaş yenilgi sayılır." and counts as a defeat if confirmed.
- **AC7** A fixed seed + fixed player choices produce the same event list (tested in `core/game`).

### 2.8 Album (`features/album`)
- **AC1** List of episodes sorted by code (`S01E01`), each with `owned / total` and a completed mark.
- **AC2** Overall progress at the top (`completed pages / total pages`).
- **AC3** Episode page: owned characters show art, missing ones show a silhouette with "?".
- **AC4** Completing a page grants `min(500, 150 + 10 × members)` coins once [GM §9], stored in `completedAlbums`; it is checked after every portal result.
- **AC5** Completion reward plays even if the page is completed while on the portal screen (a banner on the reveal).

### 2.9 Settings (`features/settings`)
- **AC1** Toggles: sound, music, haptics; sliders: sfx volume, music volume. Changes apply instantly and persist.
- **AC2** Version label; 7 taps within 3 s open the demo panel (D2). A third row "Demo modunu kapat" hides it again.
- **AC3** "İlerlemeyi sıfırla" (destructive style, confirm dialog in destructive style too) resets player state but keeps synced API data.
- **AC4** Fan-project disclaimer text and audio credits link (from `assets/audio/CREDITS.md`).

---

## 3. Data flow: API → sync → Hive → core/game → Bloc → UI

```
rickandmortyapi.com (HTTPS, read-only)
        │  dio: timeout 15 s, retry 3x on 429/5xx
        ▼
features/sync/data   RemoteDataSource ──DTO.fromJson──► Mapper (URL → id)
        │
        ▼
core/storage (Hive boxes)
   characters  episodes  locations      ← API data, written page by page
   collection  player                   ← game state (coins, deck, wins, settings,
                                          portalsOpened, completedAlbums, demo flags)
        │
        ▼
feature/data repositories  ── Either<Failure, T> ──►  feature/domain use cases
        │                                                     │
        │                                     core/game (pure Dart, Random injected)
        │                                     rarity, cardType, cardStats, passives,
        │                                     portalRoll, battleEngine, battleAi, economy
        ▼                                                     │
presentation Bloc  ◄──────────── results / BattleEvents ──────┘
        │  state (Equatable)          side effects via BlocListener
        ▼                                     ▼
      Widgets                AudioService · HapticsService · go_router
```

Key rules:
- **Derived data is never stored twice.** Rarity, type and stats are computed from the stored character by `core/game` on load. A rarity pool index (`Map<Rarity, List<int>>`) is built once at startup and held in memory (DI singleton).
- **Write-before-animate.** Portal and battle results are persisted first, then the Bloc emits the state that triggers animation (AC 2.3.8, 2.7.5).
- **Economy is the only writer of coins**; every change carries a reason (`portal`, `duplicate`, `victory`, `defeat`, `draw`, `album`, `demo`) and is logged with `AppLogger` in debug.
- **Images:** never prefetched in bulk (bandwidth). Owned cards are cached when first revealed; opponent and album art may fall back to an ink silhouette offline.
- **Battle:** `BattleBloc` holds `BattleState` from `core/game`; on `PlayerActionChosen` it calls `battleEngine.resolvePlayerTurn` then `resolveAiTurn` with the injected `Random`, then emits `replaying(events)`; the page consumes events one by one and dispatches `ReplayFinished`.

---

## 4. Animation, sound and haptics per screen

Tokens: durations `fast 150 / normal 300 / slow 600 / cinematic ≥ 1500 ms`, curves `easeOutBack` (pop-in), `easeInOutCubic` (moves), `elasticOut` (rewards) [animation rules]. Sound files and haptic types are the fixed lists in the rules; nothing new is added. "Reduced motion" = `MediaQuery.disableAnimations`: non-essential motion is cut, sound and haptics remain.

Every button everywhere: press scale 0.96 (`fast`), `button_tap`, `selectionClick`.

### 4.1 Splash
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| App open | Portal swirls in from a point (`slow`, `easeOutBack`), progress bar under it | none (music starts on main menu) | none |
| Sync progress | Bar fills (`normal` per update), counter text | none | none |
| Sync done | Portal flares, crossfade to main menu (`slow`) | `portal_open` | `heavyImpact` |
| Sync error | Portal dims to `uIntensity` 0.05, message slides up (`normal`) | none | none |

### 4.2 Main menu
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Enter | Idle portal shader loops; menu items stagger in once (40 ms apart, `normal`) | `menu_loop` fade in | none |
| Empty collection | Portal entry breathes (scale 1.0 to 1.04, 1.2 s loop) | none | none |
| Coins change | Counter rolls to new value (`slow`, `elasticOut`) | `coin` | `selectionClick` |

### 4.3 Portal
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| First visit hint (D4) | Hand icon rocks ±15° (3 swings, `normal` each, then 1.2 s pause, repeat) above "Telefonu salla!"; fades out (`fast`) on portal open. Reduced motion: static icon | none | none |
| Shake / button | `uIntensity` 0.15 → 1.0 over `slow`, particles pulled inward | `portal_charge` | `mediumImpact` |
| Not enough coins | Coin counter shakes on X (3 cycles, `normal`) | none | `lightImpact` |
| Open | Flash + ring burst; card back flies out of the center and scales up (`slow`, `easeOutBack`) | `portal_open` | `heavyImpact` |
| Waiting | Card back hovers (2 px bob); hint "Çevirmek için dokun" after 1.5 s; auto-flip after 4 s | none | none |
| Flip (common) | Y-axis flip (`normal`) | `card_flip` | `lightImpact` |
| Flip (rare / epic) | Flip + rarity-color burst behind the card, holo turns on | `card_flip` then `rare_reveal` | `lightImpact` then `mediumImpact` |
| **Legendary** | Portal recolors red (`uColor`), screen dims, card back appears as a black silhouette, slow rotation, gold light sweep, flip to rainbow foil (total ≥ `cinematic` 1500 ms; under reduced motion: 600 ms crossfade) | music crossfades to `legendary_sting`, then `legendary_reveal`; `menu_loop` returns after | heavy → 80 ms → heavy → 120 ms → heavy |
| Duplicate | Card shrinks into the coin counter; "+40" floats up (`normal`) | `coin` | `selectionClick` |
| Album completed | Banner drops from top with page name and reward (`slow`, `elasticOut`) | `victory` (short), `coin` | `heavyImpact` |

### 4.4 Collection
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Filter change | Grid items fade/reflow (`normal`, `easeInOutCubic`) | `button_tap` | `selectionClick` |
| Open card | Shared-element hero transition grid → detail (`normal`) | `card_flip` | `lightImpact` |

### 4.5 Card detail
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Tilt / drag | Holo foil and 6° max parallax follow tilt (no animation duration, low-pass filtered) | none | none |
| Tap | Flip front ↔ back (`normal`) | `card_flip` | `lightImpact` |
| Add to deck | Card copy flies to a deck icon (`normal`, `easeInOutCubic`) | `button_tap` | `selectionClick` |

### 4.6 Deck builder
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Slot filled | Card drops into slot (`normal`, `easeOutBack`) | `card_flip` | `lightImpact` |
| Slot emptied | Card slides back down (`fast`) | `button_tap` | `selectionClick` |
| Deck complete | Slots outline in portal green once (`slow`) | `rare_reveal` | `mediumImpact` |

### 4.7 Battle (event replay)
| Event | Visual | Sound | Haptic |
|---|---|---|---|
| Enter | Cards deal in (player from bottom, enemy from top, 80 ms stagger) | `battle_loop` (crossfade from menu) | none |
| `turnStart` | Active side's cards brighten; turn label "Senin sıran" / "Rakip düşünüyor" | none | none |
| Select attacker / target | Selected card lifts 8 px; valid targets get a portal-green outline | `button_tap` | `selectionClick` |
| `attack` | Attacker lunges toward target and back (`normal`, `easeInOutCubic`) | none | none |
| `dodge` (Myth) | Target sidesteps; "KAÇTI!" text | `card_flip` | `lightImpact` |
| `damage` | Target shakes (`fast`), number floats up and fades (`slow`), HP bar tweens (`normal`), turns yellow ≤ 50%, red ≤ 20% | `hit` | `mediumImpact` |
| `damage` + crit | Bigger number + "KRİTİK!" | `crit_hit` | `heavyImpact` |
| `damage` super effective | Banner "SÜPER ETKİLİ!" (`slow`, `elasticOut`) | `super_effective` | `heavyImpact` |
| `damage` not effective | Small grey "Pek etkili değil…" | `hit` | `lightImpact` |
| `faint` | Card desaturates, tilts and drops (`slow`) | `faint` | `mediumImpact` |
| `revive` (Zombi) | Green glow, card rises, HP bar refills to 30% (`slow`) | `rare_reveal` | `mediumImpact` |
| `victory` | Enemy row falls away; "Kazandın!" pops in; coins count up | music stops, `victory`, `coin` ticks | `heavyImpact` |
| `defeat` | Player row greys; "Kaybettin" fades in | music stops, `defeat` | `mediumImpact` |
| `draw` | Both rows dim; "Berabere" | `defeat` | `lightImpact` |

Replay pacing: gap between events = `fast`; a full turn (attack → damage → effects) completes in ≤ 1.6 s. A "2×" toggle halves gaps and durations (not haptic patterns).

### 4.8 Album
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Open page | Page turns in (`normal`) | `card_flip` | `lightImpact` |
| Owned slot | Art shown; silhouettes stay flat ink | none | none |
| Page complete | Gold stamp hits the page (`slow`, `elasticOut`), reward counts up | `victory`, `coin` | `heavyImpact` |

### 4.9 Settings
| Moment | Visual | Sound | Haptic |
|---|---|---|---|
| Toggle | Switch thumb (`fast`) | `button_tap` (only if sound stays on) | `selectionClick` (only if haptics stays on) |
| SFX volume slider released | none | `button_tap` at the new volume | none |
| Demo unlock (7th tap) | Panel slides down (`normal`) | `portal_open` | `heavyImpact` |

### 4.10 Device checklist (for S5)
For each row above on a real phone: correct sound, correct haptic, and silence when the related toggle is off. Plus: music pauses in background and resumes; shake works and has a cooldown; tilt moves the holo; button and drag fallbacks work on a simulator.

---

## 5. Design Direction

### 5.1 Concept: "Cel ink in the void"
The show's own visual language is flat cel color with **thick, slightly uneven ink outlines**. Generic game UI uses glassmorphism, soft glows and gradient cards. Portal Cards instead draws its UI like a cel: flat fills, ink outlines, and **hard offset shadows with no blur**. There is one glowing thing in the whole app, and that is the portal. Everything else is flat, so the portal's light is the most valuable pixel on every screen.

Taste preflight:
```
Domain:          consumer mobile game, fan project, cartoon IP
Audience & tone: fans + jury; energetic, irreverent, but readable at arm's length
Mood:            "alive" (the portal feels like it breathes; everything else holds still)
Motion depth:    expressive choreography at key moments (portal, legendary, battle hits); quiet elsewhere
Layout family:   hero portal (menu) / grid (collection) / stage (battle) / book (album)
Reference anchor: cel animation model sheets: flat color, ink line, hard shadow
```

Spend the boldness in one place: **the portal**. It is the hero of the main menu, the transition between screens, and the stage of the demo. Cards are the second voice and get their personality from rarity frames. Lists, settings and labels stay plain.

### 5.2 Color tokens
One accent: portal green. Rarity colors are semantic (they mean rarity and nothing else) and are taken unchanged from [GM §2].

| Token | Hex | Role |
|---|---|---|
| `void` | `#15112B` | App background: deep space indigo, not neutral black |
| `voidRaised` | `#231B45` | Surfaces: panels, slots, sheets |
| `ink` | `#0B0918` | Outlines (2 to 3 dp) and hard shadows |
| `paper` | `#F2ECDF` | Primary text on `void`, card name plates |
| `paperMuted` | `#A9A3BF` | Secondary text |
| `portal` | `#8FE04A` | The only accent: portal, primary action, selection, progress |
| `portalHot` | `#D4FF7A` | Portal core highlight, focus ring |
| `danger` | `#FF5A4E` | Legendary portal (`uColor`), destructive actions, low HP |
| `warn` | `#FF9F43` | HP ≤ 50%. Orange, deliberately not the legendary gold (changed 2026-11-12: the shared `#F7B731` mixed "legendary" and "at risk") |
| Rarity | `#9AA5B1` `#3FA9F5` `#A55EEA` `#F7B731` | Common, Rare, Epic, Legendary frames [GM §2] |

In code the `void` token is `AppColors.voidBase` (`void` is a Dart keyword).

Contrast, **measured 2026-11-12** (WCAG 2.x relative luminance, `test/app/theme/contrast_test.dart`). Thresholds: body text ≥ 4.5:1, display text / icons / non-text graphics ≥ 3:1.

| Pair | Ratio | Need | |
|---|---|---|---|
| `paper` on `void` / `voidRaised` | 15.55 / 13.57 | 4.5 | ✅ |
| `paperMuted` on `void` / `voidRaised` | 7.57 / 6.60 | 4.5 | ✅ |
| `ink` on `portal` | 12.12 | 4.5 | ✅ |
| `ink` on `warn` / `danger` | 9.65 / 6.40 | 4.5 | ✅ |
| `ink` on common / rare / epic / legendary frame | 7.87 / 7.69 / 5.05 / 11.04 | 4.5 | ✅ |
| `warn` / `danger` text on `void` | 8.97 / 5.95 | 4.5 | ✅ |
| `portal` / `portalHot` on `void` | 11.27 / 16.03 | 3 | ✅ |
| Frame on `voidRaised` body: common / rare / epic / legendary | 6.38 / 6.24 / 4.10 / 8.96 | 3 | ✅ |
| ~~`paper` on rarity frames~~ | 2.13 / 2.17 / 3.31 / 1.52 | 4.5 | ❌ not used |

**Text on any colored fill (`portal`, `warn`, `danger`, rarity frames) uses `ink`, never `paper` or white** (decided 2026-11-12). `ink` on epic (5.05) has the smallest margin: keep that text bold.
Status is never color alone: low HP also shows the number; rarity also shows the rarity name; type shows an icon + label.

### 5.3 Typography
Fonts bundled under `assets/fonts/` (SIL OFL, no new package; `google_fonts` is not in the approved list).

| Role | Typeface | Why |
|---|---|---|
| Display: screen titles, card names, battle callouts ("SÜPER ETKİLİ!") | **Grandstander** (Black 900, Bold 700) | Hand-cut, slightly wobbly letters that match ink-line cartoon drawing without copying the show's logo lettering |
| Body + numbers: stats, lists, settings | **Atkinson Hyperlegible Next** (Regular 400, Bold 700), tabular figures for stats and coins | Built for legibility at small sizes on dense cards |

Turkish glyph support is an acceptance criterion of the Week 1 theme task (§5.8). If either font fails, swap within the same role (display: Lilita One; body: Lexend) and record it here.

**Glyph check, 2026-11-12: passed, no swap.** All four files (Grandstander 700/900, Atkinson Hyperlegible Next 400/700; static TTFs from Google Fonts, OFL next to each family) map `ğ ş ı İ ç ö ü Ğ Ş Ç Ö Ü` in their `cmap` and have `tnum` (tabular figures). Checked by `test/app/theme/glyph_test.dart`, which also renders the sample in every style to `test/app/theme/goldens/glyph_sample.png` (real glyphs, no fallback, no missing-glyph box). Flutter family names: `Grandstander`, `AtkinsonHyperlegibleNext`.
Never use the show's logo typeface or a look-alike (copyright, fan-project rule).

Scale (sp, 1.25 ratio, body 16): `caption 12 · body 16 · title 20 · headline 25 · display 40 · callout 56`.
Display is at least 2.5× body. Battle callouts and the legendary name use `callout`. Sentence case everywhere except battle callouts, which are short shouts in the show's spirit. No all-caps labels.

### 5.4 Shape, outline, depth
- Outline: `ink`, 2.5 dp on cards and buttons, 2 dp on chips. A subtle hand-drawn wobble (±0.6 dp) is drawn by `CustomPainter` only on cards and the primary button.
- Shadow: hard offset `ink`, 4 dp down-right, 0 blur, on interactive raised items only. Pressed = shadow 0 dp and item moves 4 dp (feels like a physical press).
- Radius by hierarchy, not one value: cards 14 dp, buttons 12 dp, chips full pill, sheets 24 dp top.
- No glows, blurs or gradients outside the portal and holo shaders.
- Spacing on a 4 dp grid: `4 · 8 · 12 · 16 · 24 · 32 · 48`. Screen gutter 16 dp.

### 5.5 Rarity frames (GameCard)
Card ratio 5:7. The frame is the rarity; the card body is always `voidRaised` so art pops.

| Rarity | Frame | Extras |
|---|---|---|
| Common | 4 dp flat grey frame, ink outline | none |
| Rare | 5 dp blue frame + inner 1 dp `paper` line | holo 0.35: faint diagonal sheen |
| Epic | 6 dp purple frame with notched corners (cut 6 dp) | holo 0.65: sheen + sparse star speckle |
| Legendary | 7 dp gold frame, notched corners, small portal-ring emblem top center | holo 1.0: rainbow foil + gold edge glint; the only card allowed to glint |

Front layout: name plate (display font) at top, art 60% height, type icon + rarity name row, 2×2 stat grid (tabular figures), passive name at the bottom if any.
Back: `ink` field with a portal-ring pattern; on the detail page, text facts (species, status, origin, location, episodes).

### 5.6 Screen layouts (portrait)

Main menu: the portal leads, left-aligned menu under it, coins top right.
```
┌──────────────────────────┐
│               ◎ 1250     │  coins (tabular), tap → nothing
│                          │
│        .-~~~~~-.         │
│      (  PORTAL   )       │  hero: ~45% height, live shader
│        '-~~~~~-'         │
│   Portalı aç             │  primary, portal green, ink text
│                          │
│   Koleksiyon      84/826 │  list rows, left aligned,
│   Deste            3/3   │  value right aligned
│   Savaş                  │
│   Albüm           12/51  │
│                       ⚙  │
└──────────────────────────┘
```

Portal: full-bleed portal; card arrives in the center; one action at the bottom.
```
┌──────────────────────────┐
│ ←                ◎ 1250  │
│                          │
│      .-~~~~~~~~-.        │
│    (   ┌──────┐   )      │  card back emerges
│    (   │ ◎◎◎  │   )      │
│      '-└──────┘-'        │
│                          │
│   Telefonu salla         │  hint while idle
│   [ Portalı aç · 100 ]   │  fallback button
└──────────────────────────┘
```

Collection: filters as one scrollable chip row; grid of 3.
```
┌──────────────────────────┐
│ ← Koleksiyon      84/826 │
│ (Hepsi)(Rare)(Epic)(Human)…
│ ┌────┐ ┌────┐ ┌────┐     │
│ │    │ │    │ │    │     │
│ └────┘ └────┘ └────┘     │
│ ┌────┐ ┌────┐ ┌────┐     │
└──────────────────────────┘
```

Battle: stage layout, enemy on top, player at the bottom (thumb reach), event text in the middle band.
```
┌──────────────────────────┐
│ Rakip · Seviye 2     2×  │
│ ┌───┐  ┌───┐  ┌───┐      │  enemy row (smaller cards)
│ │   │  │   │  │   │      │
│ └───┘  └───┘  └───┘      │
│ ▓▓▓▓░  ▓▓▓░░  ▓▓▓▓▓      │  HP bars
│                          │
│     SÜPER ETKİLİ!        │  callout band
│                          │
│ ▓▓▓▓▓  ▓▓░░░  ▓▓▓▓░      │
│ ┌────┐ ┌────┐ ┌────┐     │  player row (larger cards)
│ │    │ │    │ │    │     │
│ └────┘ └────┘ └────┘     │
│ Senin sıran: kart seç    │
└──────────────────────────┘
```

Album: book metaphor; one page per episode with a 4-column slot grid; silhouettes in flat `ink`.
Deck: three large slots on top (the leading element), owned cards grid below, totals row between them.
Settings: plain list; disclaimer and version at the bottom.

### 5.7 Copy voice
Short, plain Turkish, second person singular ("Portalı aç", "Destene 3 kart ekle"). A little of the show's irreverence is allowed only in celebration moments (victory, legendary). Errors say what happened and what to do; they never apologize. No emoji anywhere (UI, code, commits). No em dashes in UI copy.

### 5.8 Week 1 theme task: acceptance criteria
The theme task (`app/theme/`: colors, typography, motion, spacing tokens) is done only when:
- **T1 Turkish glyphs:** a widget test (or a screenshot on the reference device) renders `ğ ş ı İ ç ö ü Ğ Ş Ç Ö Ü` in every weight used of both fonts, and none falls back to a system font or shows a missing-glyph box. Result recorded in §5.3.
- **T2 Contrast:** the WCAG contrast ratio is computed (unit test using the WCAG relative-luminance formula on the token values) for: `paper` and `paperMuted` on `void` and `voidRaised`; `ink` on `portal`; `paper` on each rarity frame color; `ink` on `warn` and `danger`. Body text pairs must be ≥ 4.5:1, display/callout text and icons ≥ 3:1. Any failing pair is fixed in the tokens before the task closes, and the measured numbers are written into §5.2.
- **T3** No hex color, duration or font size outside `app/theme/` (`grep` check on `lib/features` and `lib/core/widgets`).

---

## 6. Jury demo

### 6.1 Demo script (≈ 3 min)
1. Before: synced app, demo mode used to add 1000 coins and arm one legendary; deck of 3 ready; volume up; haptics on.
2. Hand the phone over on the main menu: "Salla." → portal charges, opens, card flies out; they tilt → holo. (S7)
3. Second shake → armed legendary: red portal, music change, silhouette, gold foil.
4. Battle: one turn chosen by the jury; point out "SÜPER ETKİLİ!" and the floating damage.
5. Album: show a page with silhouettes; explain `/episode` → album, `/character` → cards, `/location` → card back + map (stretch).
6. Airplane mode toggle, reopen app: still works (offline-first).

---

## 7. Engineering conventions (summary)

Full detail lives in `CLAUDE.md` and `.claude/rules/`; not duplicated here.
- **Commands:** `flutter run`, `flutter test`, `flutter analyze --fatal-infos`, `dart run build_runner build --delete-conflicting-outputs`, `flutter build apk --release --obfuscate --split-debug-info=build/symbols`.
- **Structure:** feature-first Clean Architecture as in `CLAUDE.md`; `core/game` pure Dart.
- **Testing:** `flutter_test`, `bloc_test`, `mocktail`; fixed seeds; probability tests 10,000 rolls ± 2%; fixtures for Rick (1), Morty (2) and a single-episode character. New tests for D1 (first 3 portals unique, over many seeds) and D2 (override fires once).
- **Boundaries**
  - Always: tokens for duration/color/size; sound via `AudioService`, haptics via `HapticsService`; persist before animating; analyze + test before "done".
  - Ask first: any package not listed in `CLAUDE.md`; any change to a formula or constant in `rm-game-mechanics`; adding audio assets beyond the fixed list.
  - Never: formulas in UI code; `Random()` inside `core/game`; secrets; `print()`; store release; the show's logo or logo-like lettering.

---

## 8. Out of scope (stretch, only after the MVP is done)

- Dimension map (`/location` as a mechanic) [GM §10]
- Card merge and stars [GM §11]
- Pity counter and daily free portal [GM §7]
- Multiple deck slots, deck names (would need input validation [security profile])
- Online features of any kind: accounts, leaderboard, trading (would raise the security profile to L2)
- Tablet / landscape layouts, a language other than Turkish
- Store release (fan project)

## 9. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Shader + particles drop below 60 fps on mid-range Android | Fails S6, demo looks broken | Profile in week 1 with the holo shader alone; `RepaintBoundary` around portal and cards; cap particle count; non-shader fallback is the safety net |
| Legendary pool is small (characters with 20+ episodes) | Same legendaries repeat; D1 could run out of unowned legendaries | Step-down fallback [GM §7.3], unit tested |
| Balance: stats formula makes legendary decks unbeatable or battles too long | Boring battles, 40-turn draws | Week 1 balance tests with fixtures; simulate 1,000 AI-vs-AI battles per tier in a test and check average turn count (target 6 to 14) |
| First sync on bad Wi-Fi at the venue | Demo cannot start | Sync before the demo; S2 offline check; resumable sync (AC 2.1.3) |
| Opponent/album art not cached offline | Empty images in the offline demo | Ink silhouette fallback with name; browse album once online before the demo |
| Sensors: no emulator support, shake false positives | Accidental coin spending, untestable in CI | Thresholds + cooldown from the rules; shake only active on the portal screen; button fallback; real-device checklist |
| Audio latency on Android (sfx late vs. animation) | Feedback feels off | SFX pool preloaded at startup; trigger sound at animation start from `BlocListener` |
| Turkish glyphs missing in a chosen font | Broken text | Glyph check before adopting (§5.3) |
| iOS build issues found late | Week 4 slip | Build and run on the iPhone at the end of every week, not only in week 4 |
| Copyright | Takedown / grading concern | Non-commercial disclaimer in README and Settings; no store release; no logo lettering |

## 10. Open questions
None. Assumptions (§0) and the step-down fallback (D3) were approved on 2026-11-11.
