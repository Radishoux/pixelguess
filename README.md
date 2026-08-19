# PixelGuess

A Flutter mobile game built around progressive pixelation. You are shown a photo
rendered at a fraction of its native resolution — barely more than a handful of
coloured blocks — and you have to type what it is. Spend **pixels** to raise the
resolution a step at a time until you recognise it.

Ten levels, all unlocked from the start, fully offline.

## How it plays

- Every level starts at **intensity 1**, meaning it renders at 1% of the source
  image's linear resolution. A 512x512 photo becomes a 5x5 grid of blocks.
- Raising the intensity costs pixels. Intensity is **sticky**: once you have paid
  to go from 1 to 2, that level stays at 2 forever, across app restarts.
- Every guess costs **1 energy**. Energy caps at 20 and regenerates one unit
  every five minutes, computed from a persisted wall-clock timestamp rather than
  a background timer, so it accrues correctly while the app is closed.
- A correct answer awards 100 pixels plus a bonus scaled to how little you
  revealed, so solving one early is worth considerably more.
- Intensity is capped at 99 while a level is unsolved. You never see the clean
  image until you get it.

There is deliberately **no level gating**. Every level is playable in any order,
so a player stuck on level 1 can go earn pixels on level 3 and come back.

## The pixelation

The blockiness is real, not a blur. Images are decoded at the target size via
`ui.instantiateImageCodec` with explicit `targetWidth` / `targetHeight`, then
scaled back up with `FilterQuality.none` so the pixels stay hard-edged squares.
Decoding full-resolution and downscaling in a widget, or faking it with an
`ImageFiltered` blur, both produce the wrong look and are specifically avoided.

Decoded frames are cached per `(levelId, intensity)` and disposed when leaving a
level.

## Tech

- Flutter / Dart, null-safe, targeting Android and iOS
- **Riverpod** for state management
- `shared_preferences` behind a `SaveRepository` interface, so the storage layer
  can be swapped for Hive or sqflite without touching game logic
- Fully offline: no backend, no network calls, no analytics, no ads, no IAP
- Every tunable number lives in `lib/core/game_config.dart`

## Content model

Levels are data, not code. `assets/data/levels.json` holds one object per level
with its image path, answer, and accepted alternatives. The JSON is validated on
load and fails loudly with a clear message if a level is malformed. Adding a
level means dropping in an image and appending one object.

Answer matching normalises both sides before comparing: lowercase, diacritics
stripped, non-alphanumerics removed, whitespace collapsed. So `La Joconde`,
`la joconde` and `lajoconde` all match.

## Project layout

```
lib/core/      models, game config, pure logic (economy, energy, matching)
lib/data/      repositories: levels, save state
lib/features/  level select, puzzle, settings screens
assets/        level images and levels.json
test/          unit tests for every pure-logic module
tool/          placeholder art generator
```

`SPEC.md` holds the original design brief, including the reasoning behind the
decisions above.

## Running it

```bash
flutter pub get
```

```bash
flutter run
```

```bash
flutter test
```

The suite covers answer matching, the economy, energy regeneration, level
loading and validation, pixel dimension maths, the pixelation cache, and save
round-tripping, plus a boot smoke test.

## Asset licensing

The images currently in `assets/images/levels/` are placeholders used during
development and include third-party logos and artwork that are **not cleared for
redistribution**. They must be replaced with owned or properly licensed images
before this repository is made public or the game is released.

`tool/generate_placeholders.py` generates neutral geometric stand-ins that are
safe to ship.

## Status

Feature-complete at v1: ten levels, the full economy, persistence, and all three
screens. 55 tests passing.
