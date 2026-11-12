# Test fixtures

Unmodified responses from the public Rick and Morty API, saved with
`curl -sf -o <file> <url>` on 2026-11-12 (HTTPS GET, no edits, no formatting).
If the API data changes, re-download and update the expectations in
`fixtures_test.dart`.

| File | Source URL | Covers |
|---|---|---|
| `character_1_rick_sanchez.json` | https://rickandmortyapi.com/api/character/1 | Human, Alive, 51 episodes (Legendary) |
| `character_2_morty_smith.json` | https://rickandmortyapi.com/api/character/2 | Human, Alive, 51 episodes (Legendary) |
| `character_23_arcade_alien.json` | https://rickandmortyapi.com/api/character/23 | Alien, unknown, 5 episodes (Epic) |
| `character_63_centaur.json` | https://rickandmortyapi.com/api/character/63 | Mythological Creature (Myth), Alive, 1 episode (Common) |
| `character_71_conroy.json` | https://rickandmortyapi.com/api/character/71 | Robot, Dead, **1 episode** (Common) |
| `character_82_cronenberg_rick.json` | https://rickandmortyapi.com/api/character/82 | Cronenberg (Neutral), unknown, 2 episodes (Rare) |
| `character_86_cyclops_rick.json` | https://rickandmortyapi.com/api/character/86 | Humanoid (maps to Human), Dead, 3 episodes (Rare) |
| `character_309_scrotian.json` | https://rickandmortyapi.com/api/character/309 | Animal (Beast), Alive, 4 episodes (Rare) |
| `episode_page_1.json` | https://rickandmortyapi.com/api/episode?page=1 | Episode page: `info` + 20 results |
| `location_page_1.json` | https://rickandmortyapi.com/api/location?page=1 | Location page: `info` + 20 results |

Together: all 4 rarities (incl. both boundaries 1 and 20+), all 6 types,
all 3 statuses [GM §2, §3, §5].

Load them in tests with `loadFixture('<file>')` from `fixtures.dart`.
