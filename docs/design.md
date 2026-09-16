# Unwind — design notes

A short, living record of what the game is and the decisions behind it, so the
vision doesn't drift as features land. Not a formal GDD — this is a 2D puzzle,
not a 3D RPG, so it's kept to what actually matters here.

## The player fantasy
A calm, tactile untangle. You're handed a knot of pins joined by ropes; some
ropes cross. You drag pins until nothing crosses and the board settles. It
should feel meditative, not tense — the reward is the quiet "click" of a knot
coming undone, not a score or a timer.

## Core loop
1. **Untangle** — drag pins; tangled ropes glow warm, calm ones fade back.
2. **Settle** — crossings reach zero, the board is solved.
3. **Grow** — solving grows a plant in your zen garden (slice 5), so there are
   always two things easing toward completion: the board, and the garden.

## Rules
- Win condition: **no rope properly crosses another.** Ropes sharing a pin, or
  merely touching, don't count as crossed.
- **1000+ levels, no server, no bundled data.** A level is a pure function of
  its number (`LevelGenerator.generate(n)`) — identical on every device.
- **Always solvable, by construction.** The generator builds a crossing-free
  layout first and keeps it as proof, then scrambles the pins for the start.
- Difficulty rises with pin count (4 → ~22) and then with rope density.

## Visual & UI direction
- Dark, restful palette: deep green-black board (`0xFF12211B`), mint pins
  (`0xFF8FE0C0`), muted green ropes, warm amber only for the ropes still
  tangled. No hard reds, no clutter.
- Minimal chrome: level number, crossings remaining, and a quiet "Unwound"
  panel on solve. Touch-first — the whole interaction is drag.

## Progression & garden
- Levels are sequential; each solve advances and (slice 5) grows the garden.
- Garden themes are the cosmetic reward the premium purchase unlocks.

## Monetization (decided — recorded so it isn't quietly changed)
- **Free:** an **interstitial ad before every second level** — the ad shows
  first, then the next level begins. Wired to **Google AdMob**. Premium players
  never see one.
- **Premium:** a **single one-time purchase — "Remove Ads + unlock all garden
  themes"** (~$3–5), through **Google Play Billing**. No subscription.
- Both go through Google. **No personal payment gateway, ever.**
- During development, ads use **Google's official test ad units** so we never
  risk a policy strike clicking real ads.

## Tech architecture
- **Flutter + Flame**, Android first.
- **Pure model, thin engine layer.** Everything in `lib/game/model/` is plain
  Dart with no Flame/Flutter import, so the puzzle logic is unit tested. The
  Flame layer (`unwind_game.dart`) only renders it and turns drags into moves.
- Coordinate maths lives in one tested helper (`board_transform.dart`); the
  engine never does arithmetic of its own.
- Monetization is behind a tiny abstraction (`monetization/`) so the puzzle
  flow never touches an ad or billing SDK directly.

## How we build (the one rule worth keeping from any "AI game" guide)
- **One slice at a time, each verified by CI before the next.** No attempt to
  generate a whole game in one shot.
- **Pure logic first, proven by tests; the platform layer on top.** The parts
  that can't be verified in CI (Flame feel, ad/billing SDKs, on-device) are
  marked as such and confirmed on a real phone.
- **No premature optimization.** With ≤22 pins and a few lines, object pooling
  and draw-call batching would solve problems this game doesn't have. A light
  performance pass belongs near launch, not now.

### Slices
1. ✅ Puzzle core — generator, crossing maths, always-solvable (tested)
2. ✅ Flame board — drag-to-untangle, live crossing highlight
3. ✅ Installable debug APK built in CI
4. ✅ Ads (every 2nd level) + one "Remove Ads + unlock themes" IAP
5. ✅ The zen garden meta — solving grows a plant; premium unlocks themes
6. ✅ Polish + level-feel + release prep — displacement-based early levels,
   solve pulse and softer board lighting, richer garden plants, configurable
   AdMob ids (`--dart-define` / `ADMOB_APP_ID`), release .aab in CI, and a
   release runbook (`docs/RELEASE.md`) + draft listing (`docs/store-listing.md`)
