# PixelGuess — Claude Code project prompt

> Committed for future sessions so the context behind the design decisions isn't lost.

---

Build a new Flutter mobile game called **PixelGuess** from scratch in `~/24/pixelguess`.

The GitHub remote already exists and is private: `https://github.com/Radishoux/pixelguess`. Initialise the repo locally, add that remote, and make an initial commit — but do not push until confirmed.

## The game in one paragraph

The player is shown a heavily pixelated photo of an object (Mona Lisa, donut, fan, microphone…) and has to type what it is. The image starts almost unreadable and the player spends **pixels** to progressively increase its resolution until they can recognise it. Every guess attempt costs **1 energy**. Guessing correctly awards pixels and marks that level solved. Ten levels ship in this version, **one image per level**.

## Tech decisions (use these)

- **Flutter / Dart**, latest stable, null-safe. Target Android + iOS.
- Bundle id / package: `com.rudymagenta.pixelguess`
- **Riverpod** for state management.
- **Fully offline.** No backend, no network calls, no analytics, no ads, no IAP in this version.
- Persistence: `shared_preferences` storing a single serialised JSON save blob — but put it behind a `SaveRepository` interface so it can be swapped for Hive/sqflite later without touching game logic.
- All tunable game numbers live in **one file**: `lib/core/game_config.dart`. Nothing numeric should be hardcoded anywhere else.

## Content model

Levels are data, not code. Put them in `assets/data/levels.json`:

```json
{
  "levels": [
    {
      "id": 1,
      "image": "assets/images/levels/level_01.png",
      "answer": "mona lisa",
      "alternatives": ["monalisa", "la joconde"]
    },
    {
      "id": 2,
      "image": "assets/images/levels/level_02.png",
      "answer": "microphone",
      "alternatives": ["mic"]
    }
  ]
}
```

10 levels, real answer words, a spread of categories: art, food, everyday objects, music gear, animals, tech, tools, nature, vehicles. Validate the JSON against a schema on load and fail loudly with a clear error if a level is malformed. Adding an eleventh level should mean dropping in an image and appending one object here, nothing more.

## No level gating — this is a design rule, not a placeholder

Every level is unlocked from the start and playable in any order. If a player is stuck on level 1, they need to be able to go earn pixels on level 3 and come back with enough to reveal more. Do not add unlock conditions, stars-to-progress, or a linear path.

## The pixelation mechanic

Images ship at **full resolution** in `assets/images/levels/`. Pixelation happens at runtime.

Each level has an **intensity** from **1 to 99**, meaning "render at that percentage of native resolution":

```
targetWidth  = max(1, floor(sourceWidth  * intensity / 100))
targetHeight = max(1, floor(sourceHeight * intensity / 100))
```

Always round **down**. Every level starts at **intensity 1**. With 512×512 source art that gives a 5×5 image, which is the intended starting point.

The player raises intensity by pressing a reveal button on the puzzle screen, paying pixels. **Intensity is persistent and sticky**: once a player pays to go from 1 to 2, that level stays at 2 forever — leaving the screen, closing the app, coming back days later all preserve it. It only ever moves up, when they pay again or when they solve the level.

Implementation requirements:

- Decode at the target size using `ui.instantiateImageCodec` with `targetWidth` / `targetHeight` — do **not** decode full-res and then downscale in a widget, and do **not** fake this with a blur or an `ImageFiltered` effect. It must be genuine hard-edged blockiness.
- Scale that small image back up to fill the display area using **`FilterQuality.none`** so pixels stay crisp squares, never smoothed.
- Cache decoded frames keyed by `(levelId, intensity)`; dispose them properly when leaving the screen.
- Animate the transition when intensity increases (short cross-fade between the old and new resolution) — it should feel like a reward.

## Economy

**Energy** — guesses and attempts.
- Cap 20, starts full.
- Regenerates 1 unit every 5 minutes (config value).
- Compute regen from a persisted `lastEnergyUpdate` wall-clock timestamp on app launch and on resume. Do **not** rely on a timer running while the app is backgrounded. If the stored timestamp is in the future (clock changed), clamp it to now.
- Submitting a guess costs 1 energy. At 0 energy, block submission and show a live countdown to the next unit.

**Pixels** — revealing.
- Awarded on a correct answer: 100 base, plus a bonus scaled to how little the player revealed (config-driven formula).
- Spent to raise a level's intensity.

Both of these go in `game_config.dart` as pure functions:

```dart
int intensityStepFor(int currentIntensity); // default: 1
int pixelCostFor(int currentIntensity);
```

Keeping the step as a function rather than a constant matters: going from intensity 1 to 2 doubles the linear resolution and is a huge visual jump, while 50 to 51 is nearly invisible. Build for the step growing at higher intensities even though the default is a flat +1.

Intensity is capped at 99 — the player never sees the fully clean image while the level is unsolved.

Pixels may later also buy hints or extra attempts, so the spend path is generic (a `SpendPixels` action with a reason enum) rather than hardwired to reveals only.

## Screens

1. **Level select** — grid of 10 level cards, all tappable. Each card shows its number, a checkmark when solved, and its current intensity while unsolved. Persistent HUD at top with energy (and its regen countdown) and pixel balance.
2. **Puzzle screen** — the pixelated image filling most of the screen, the dash hint below it, a text input, a submit button, and a reveal button labelled with its current pixel cost.
   - The dash hint shows word structure and letter count: `mona lisa` renders as `____ ____`.
   - Input uses the native keyboard via a `TextField`.
   - Wrong answer: shake animation, energy decrements, input clears.
   - Correct answer: reveal the image at full resolution, award animation, then back to level select with that level now checked.
   - Reveal button disabled with a clear reason when the player can't afford it.
3. **Options** — sound/haptics toggles, reset progress (with confirmation), version info, credits.

## Answer matching

Normalise both the input and the stored answers before comparing: lowercase, strip diacritics (`é` → `e`), remove all non-alphanumeric characters, collapse whitespace. Match against the answer and every entry in `alternatives`. No partial-letter reveals on wrong guesses.

## Placeholder art

Real photos come later. `tool/generate_placeholders.py` generates 10 distinct 512×512 PNGs — each with a strong background colour and a simple bold geometric shape, so pixelation produces a meaningful, recognisable-at-high-intensity image rather than flat colour.

## Architecture and quality

- Feature-first structure: `lib/features/level_select/`, `lib/features/puzzle/`, `lib/features/settings/`, with `lib/core/` for config, models, persistence, and the pixelation service.
- Keep game logic (energy regen, pixel costs, answer matching, progress state) in pure Dart classes with no Flutter imports, so it's testable without a widget tree.
- Unit tests covering: intensity → target dimension maths including the floor and the `max(1, …)` guard, energy regen across arbitrary elapsed durations, the pixel cost curve, answer normalisation edge cases, and save/load round-trips including intensity persistence.
- `analysis_options.yaml` with `flutter_lints` and no warnings.
- A `README.md` explaining how to run it, and specifically how to add a new level.

## Assumptions flagged, not silently changed

- No sound assets yet; audio service stubbed behind an interface.
- Answers are in English for now, but strings are structured for later localisation (French is coming).

## Build order

Core models and persistence → pixelation service with tests → puzzle screen → level select → settings. Commit at each milestone.
