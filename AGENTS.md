# Codex Repository Context

This file is the durable handoff for Codex and other coding agents working in this repository. Read it before making changes, including after conversation compaction. It summarizes the current product boundary and points to the authoritative documents; it does not replace them.

## 1. Start-of-task checklist

1. Run `git status --short --branch` and preserve unrelated user changes.
2. Read the specific source files and documents affected by the request.
3. Check [PROTOTYPE_STATUS.md](PROTOTYPE_STATUS.md) before claiming a feature exists.
4. Check [docs/ROADMAP.md](docs/ROADMAP.md) and the applicable phase document before expanding scope.
5. Use stable SRS requirement IDs from [SRS.md](SRS.md) for requirements and traceability work.
6. Make the smallest coherent product slice, with tests and documentation in the same change.
7. Before handoff, run the proportional verification commands in this file and report any unverified boundary honestly.

## 2. Project identity and current state

- Product: `myCloset` is a provisional name; trademark and App Store availability are not confirmed.
- Repository: `https://github.com/mkodithuwakku/myCloset.git`
- Primary branch: `main`
- Platform: native iPhone application built with SwiftUI.
- Minimum deployment target: iOS 17.0.
- Current version/slice: `0.1.0`, Phase 0 local functional prototype complete.
- Next planned phase: Phase 1, Capture and Wardrobe Quality.
- Current bundle identifier: `com.mkodi.myCloset.prototype`.
- Cost model: completely free to users; production service choices must remain cost-conscious.

The prototype is usable locally. It is not an App Store release candidate and has no production backend.

## 3. Product rules that must survive every change

1. Closets are private. Following another user must never grant closet access.
2. Future public outfit posts must contain detached snapshots, never references that expose live closet records.
3. Likes and comments are out of scope. Do not add them implicitly.
4. Hard recommendation constraints are deterministic: ownership, availability, exclusions, valid outfit structure, and locked pieces cannot be overridden by random or AI ranking.
5. Users may lock pieces and reroll an unavailable or unwanted piece while preserving the remaining valid outfit.
6. Weather falls back from current location to manual city to date-derived season. The app must remain usable when location and weather are unavailable.
7. Duplicate clothing records are allowed. Duplicate normalized names produce a warning, not a blocked save.
8. Garment category is user-selected. Dominant and accent colors are suggested automatically but remain user-confirmed and editable.
9. Garments support multiple seasons and formality levels.
10. Saved and worn outfits are immutable snapshots; later closet edits must not rewrite history.
11. Social publishing cannot ship without authorization, detached media, reporting, blocking, moderation, deletion propagation, and operational ownership.
12. Do not present planned services, fake social data, or placeholder network behavior as implemented.

## 4. Current implemented vertical slice

The five tabs are Home, Closet, Generate, Following, and Profile.

- Home: season/weather-aware Outfit of the Day, explanation, refresh, save, and mark-worn actions.
- Closet: local create/edit/search/filter/favorite/archive/delete and availability management.
- Item intelligence: Photos import, fixed 1,200-pixel resizing, palette-based dominant/accent suggestions, and editable metadata.
- Generator: occasion presets, six formality levels, locks, full/unlocked/single-piece rerolls, and explanations.
- Weather: foreground approximate location, manual city through Apple geocoding, Open-Meteo current conditions, and season fallback.
- History: separate saved and worn collections backed by immutable snapshots.
- Profile: local display name, handle, biography, and profile image.
- Following: an explicit preview of the deferred social/safety boundary; no real following backend exists.
- Persistence: atomic local Codable JSON in Application Support.

See [PROTOTYPE_STATUS.md](PROTOTYPE_STATUS.md) for the authoritative implemented/partial/deferred matrix.

## 5. Architecture map

```text
MyClosetApp
└── ContentView / TabView
    ├── HomeView ─────────────┐
    ├── ClosetView ───────────┤
    ├── GeneratorView ────────┼── ClosetStore (@MainActor) ── local JSON
    ├── FollowingView         │          │
    └── ProfileView ──────────┘          └── OutfitEngine

HomeView / GeneratorView ── WeatherService ── Core Location / Geocoder / Open-Meteo
ClosetView ── ImageUtilities
```

Important boundaries:

- `ClosetStore` currently combines observable application state, persistence, and recommendation orchestration. This is accepted prototype debt, not the production service shape.
- `OutfitEngine` is a stateless domain service. Keep hard filtering/validation separate from soft scoring.
- `ImageUtilities` handles decoding, resizing, compression, and simple color sampling. Background isolation and editable segmentation belong to Phase 1.
- `WeatherService` owns location/city/provider behavior. Do not spread transport code into views.
- Views may own temporary UI state but should not own persistence, transport, or recommendation rules.

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before changing data ownership, persistence, recommendation boundaries, media visibility, providers, authentication, or service structure. Record material decisions under `docs/decisions/`.

## 6. Repository map

```text
myCloset/                     Application, views, domain logic, and services
myClosetTests/                Unit/domain/store/image tests
myClosetUITests/              Critical iPhone UI journeys
myCloset.xcodeproj/           Xcode project and shared scheme
myCloset.xctestplan           Checked-in unit and UI test plan
docs/phases/                  Phase implementation contracts and exit gates
docs/decisions/               Architecture decision records
docs/testing/                 Dated test-execution evidence
SRS.md                        Enterprise product requirements baseline
PROTOTYPE_STATUS.md           Truth about the current executable product
README.md                     GitHub entry point and current capability summary
CHANGELOG.md                  User/maintainer-visible changes
scripts/verify_docs.sh        Portable documentation/status gate
.github/workflows/ios.yml     macOS/Xcode build and test workflow
```

## 7. Build and test commands

Compile the simulator target without signing:

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run the complete signed simulator test plan:

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetTestDerivedData \
  test
```

Do not set `CODE_SIGNING_ALLOWED=NO` on UI-test commands; the UI runner needs local simulator signing.

Run narrower suites with `-only-testing:myClosetTests` or `-only-testing:myClosetUITests`. Validate documentation with:

```sh
./scripts/verify_docs.sh
```

Current automated inventory: 30 unit tests and 3 UI tests. The latest recorded execution evidence is [docs/testing/TEST_EXECUTION_2026-07-14.md](docs/testing/TEST_EXECUTION_2026-07-14.md).

Debug-only UI launch arguments are:

- `-resetPrototypeData`
- `-loadPrototypeSamples`
- `-openPrototypeGenerator`
- `-generatePrototypeOutfit`

Keep test data isolated through an injected `ClosetStore(storageURL:)`; never use a developer's real Application Support data in tests.

## 8. Testing expectations

- Recommendation changes must test invariants across repeated randomized generation, not one exact outfit.
- Persistence changes must test reload, failure/migration behavior where applicable, and snapshot immutability.
- Image changes must test large, invalid, and representative color inputs.
- Critical user journeys need UI coverage using observable conditions, not sleeps.
- Backend phases must add complete owner/non-owner authorization tests before enabling networked data.
- New tests require inventory/traceability documentation updates.
- A successful bundle build is not proof that tests executed. Require `** TEST SUCCEEDED **` or inspect the `.xcresult` test count.

## 9. Documentation synchronization rules

Documentation is part of the change, not cleanup for later.

| Change | Required updates |
|---|---|
| User-visible behavior | `README.md`, `PROTOTYPE_STATUS.md`, `CHANGELOG.md` |
| Test count/strategy | `docs/TESTING.md`, README test count, traceability, execution evidence when a gate is run |
| Phase status/scope | `docs/ROADMAP.md`, applicable `docs/phases/*`, README, prototype status |
| Architecture/data boundary | `docs/ARCHITECTURE.md` and an ADR when material |
| Requirement decision | `SRS.md` and `docs/REQUIREMENTS_TRACEABILITY.md` |
| Setup/toolchain/CI | `README.md`, `docs/DEVELOPMENT.md`, `docs/TESTING.md` as applicable |
| Durable agent context | this `AGENTS.md` |

Do not duplicate long specifications here. Update the authoritative document and keep this file as a concise map of durable decisions.

## 10. Phase 1 next-slice priorities

Unless the user reprioritizes, the highest-value next slice is:

1. direct camera capture with category-specific framing guides;
2. Vision foreground-instance masking and user-adjustable crop/mask correction;
3. dominant/accent extraction from the isolated garment only;
4. photo quality/confidence states and retry guidance;
5. persistence schema versioning and tests for capture failure/recovery.

Phase 1 must remain useful without requiring accounts or a backend. Identity/cloud work belongs to Phase 2.

## 11. End-of-task handoff checklist

1. Confirm `git diff --check` and review the complete diff.
2. Run tests proportional to risk plus `./scripts/verify_docs.sh`.
3. Update current-status and roadmap documents if reality changed.
4. Keep build products, `.xcresult` files, credentials, signing material, and user-specific Xcode data out of Git.
5. If asked to publish, commit, push, and verify that `git rev-parse HEAD` matches `git ls-remote origin refs/heads/main`.
6. State what passed, what was not run, current limitations, and the exact commit when publishing.
