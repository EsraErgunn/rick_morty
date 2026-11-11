# Security Profile – Portal Cards

Follow `docs/SECURITY_GUIDELINES.md` for all rules. This file only sets project-specific values.

## Risk profile
**L1 – Basic.** Reason: no user accounts, no backend of our own, no real money, no personal data. The only network traffic is read-only calls to the public Rick and Morty API.

## Architecture
- Backend: none (public read-only API: `https://rickandmortyapi.com/api`)
- Local data: Hive (game progress, collection, coins) – not sensitive
- Sensors: accelerometer/gyroscope (no permission needed); no camera, location, contacts

## Project values
- Android package: `com.esraergun.portalcards`
- iOS bundle ID: `com.esraergun.portalcards`
- API domain: `rickandmortyapi.com`

## Required (L1 ✅)
- [x] No secrets in code
- [x] HTTPS only, cleartext blocked
- [x] No `print()`; nothing sensitive in logs
- [x] Input validation for anything typed by the user (deck names, if added)

## Optional controls (not required for L1)
- [x] Release obfuscation (`--obfuscate --split-debug-info`) – cheap, keep it
- [ ] Certificate pinning – not needed
- [ ] RASP / root detection – not needed
- [ ] Screen protection – not needed
- [ ] Encrypted local DB – not needed (no sensitive data)

## Exceptions
- Coins and collection are stored locally and can be edited on a rooted device. Accepted: single-player, no real value, no leaderboard.
  If an online leaderboard or trading is ever added → raise the profile to L2 and move economy validation server-side.
