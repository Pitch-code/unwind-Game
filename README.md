# Unwind

A calm untangle puzzle. A board has pins joined by ropes; some ropes cross.
Drag the pins until no rope crosses another, and the board settles. Solving a
board grows a plant in your zen garden — so there are always two things easing
toward completion at once.

Built with **Flutter + Flame**. Targets Android first.

## Status

Early scaffold. What exists and is tested:

- `lib/game/model/` — the pure-Dart puzzle core, with no Flutter or Flame
  dependency so it runs under plain unit tests:
  - `geometry.dart` — the proper segment-crossing test (shared pins and
    touches deliberately do **not** count as crossings).
  - `crossings.dart` — `countCrossings` / `isSolved`, the win condition.
  - `level_generator.dart` — turns a level number into a puzzle.

Not built yet: the Flame board and drag input, the garden meta, ads, and the
in-app purchase (see below).

## Two guarantees the core makes

1. **Deterministic levels.** `LevelGenerator.generate(n)` is a pure function of
   `n`. Level 348 is identical on every device, so 1000+ levels need no server
   and no bundled level data.

2. **Always solvable.** The generator first builds a layout with zero crossings
   (a rope is only accepted if it crosses nothing already placed) and keeps it
   as `Level.solved`, then scrambles the pins for `Level.start`. Because a
   crossing-free arrangement provably exists, the player can always reach one.
   `test/level_generator_test.dart` asserts this across the level range.

## Monetization plan (recorded so it isn't quietly changed)

- **Free / trial:** an **interstitial ad on every second level** — the ad shows
  first, then the next level begins. (Ad hook lands with the game loop; wired to
  Google AdMob, no personal ad server.)
- **Premium:** a **single one-time purchase — "Remove Ads + unlock all garden
  themes"** (~$3–5), sold through **Google Play Billing**. No subscription, no
  personal payment gateway.

Both the ad and the purchase go through Google Play. Nothing bills the user
directly.

## Verifying

There is no Flutter SDK in the build sandbox, so the authority is CI:
`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every
push. Treat a change as unverified until that is green.
