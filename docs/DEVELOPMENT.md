# Development Guide

## 1. Supported development environment

- macOS
- Xcode 26.x recommended; project deployment target iOS 17.0
- Swift 5 language mode
- iPhone simulator
- Git

No third-party packages, package manager, API keys, or backend are required for Phase 0.

## 2. Setup

```sh
git clone https://github.com/mkodithuwakku/myCloset.git
cd myCloset
open myCloset.xcodeproj
```

Select the shared `myCloset` scheme and an iPhone simulator. Build with `Command-B` and run with `Command-R`.

## 3. Command-line workflows

### Compile without signing

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

### Full tests

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetTestDerivedData \
  test
```

### Documentation validation

```sh
./scripts/verify_docs.sh
```

### Import a local image test closet

For deterministic results, keep test garments in one folder and include the type in each filename, such as `blue-shirt.jpg`, `dark-jeans.png`, `white-sneakers.jpeg`, `rain-jacket.jpg`, or `black-watch.png`. Open **Closet → + → Import image files** and multi-select the images.

To test the PhotosPicker route, copy the folder into the currently booted simulator:

```sh
xcrun simctl addmedia booted ~/Desktop/test-closet/*
```

Open **Closet → Import** and multi-select up to 50 images. This route may not preserve filenames, so the importer falls back to Apple's on-device Vision classifier. Any low-confidence or unmatched image defaults safely and is called out for manual review. Imported names are automatically suffixed when a batch would create duplicates.

## 4. Prototype launch arguments

Debug-only arguments support deterministic smoke tests:

| Argument | Effect |
|---|---|
| `-resetPrototypeData` | Clears closet, profile content, and outfit history before use |
| `-loadPrototypeSamples` | Loads the twelve-piece sample closet when empty |
| `-openPrototypeGenerator` | Selects the Generate tab |
| `-generatePrototypeOutfit` | Generates an outfit after the generator appears |

These must remain guarded by `#if DEBUG` and must not become production administration controls.

## 5. Source organization

| File/area | Responsibility |
|---|---|
| `Models.swift` | Stable domain values and persistence DTOs |
| `ClosetStore.swift` | Current local state, persistence, history, and daily orchestration |
| `OutfitEngine.swift` | Pure generation constraints, scoring, and explanations |
| `WeatherService.swift` | Location/city acquisition and forecast adapter |
| `ImageUtilities.swift` | Image normalization and palette suggestion |
| `ClothingTypeDetector.swift` | Filename/Vision type suggestion and batch-import defaults |
| `*View.swift` | SwiftUI presentation and short-lived interaction state |
| `Components.swift` | Shared visual primitives and theme |

## 6. Coding guidance

- Keep SwiftUI bodies declarative; extract domain operations.
- Prefer stable enums and IDs over display-string business logic.
- Use explicit fallbacks for permission and network failures.
- Preserve historical outfit snapshots when current items change.
- Make random or intelligent selection subordinate to deterministic validation.
- Add accessibility labels/identifiers to icon-only and test-critical controls.
- Avoid force unwraps in production code unless an invariant is locally proven.
- Keep tests deterministic; do not call live weather or identity providers.

## 7. Data changes

Phase 0 persistence has no schema version. Any model change that breaks decoding must either:

1. remain backward-compatible through defaults/custom decoding; or
2. introduce the schema-version/migration mechanism planned for Phase 1.

Do not silently discard user data after a decoding failure.

## 8. Debugging

### App starts empty

Tap **Load sample closet**, or add a top, bottom, and footwear. Generation intentionally refuses to invent missing pieces.

### Outfit generation fails

Check availability, selected season/formality, locked category conflicts, and whether an alternative exists. The error should remain actionable.

### Weather unavailable

Use a city or season-only mode. Live weather is optional. Network unit tests should replace the provider with a future injected fake rather than depend on Open-Meteo.

### Simulator service errors

Confirm a runtime is installed, close/reopen Simulator, and run:

```sh
xcrun simctl list devices available
```

Use a listed device name/ID in the test destination.

## 9. Pull-request workflow

Follow [CONTRIBUTING.md](../CONTRIBUTING.md). Before requesting review:

1. build;
2. run all tests;
3. exercise the changed journey manually;
4. run documentation verification;
5. update the changelog and phase/README status;
6. review the diff for secrets and generated local files.
