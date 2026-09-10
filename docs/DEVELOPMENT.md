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

Select the shared `myCloset` scheme and an iPhone simulator. Build with `Command-B` and run with `Command-R`. The shared Run pre-action verifies the built signature, waits for that exact simulator UUID to finish booting, and synchronously installs the signed app to clear stale updating placeholders before the debugger launch. It skips physical-device runs. The successful preparation timestamp is recorded in `myCloset-simulator-run.log` under Xcode’s target temporary build directory.

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
./scripts/test_ios.py
```

This creates a separate temporary iPhone simulator, waits for boot readiness, runs signed tests serially, and removes only that temporary device afterward. Its printed output directory retains DerivedData and the result bundle. Append `-only-testing:myClosetTests` or `-only-testing:myClosetUITests` for narrower suites. Keep the simulator selected in Xcode for interactive runs only.

### Launch preparation checks

```sh
python3 -m unittest discover -s scripts/tests -v
```

These eight host-side checks use a signed disposable fixture and stub simulator commands, so they do not modify any simulator.

### Documentation validation

```sh
./scripts/verify_docs.sh
```

### Import the repository-local test closet

Place JPEG, PNG, HEIC, HEIF, or WebP files in `TestClosetImages/`. The directory ignores image content in Git to prevent accidental publication of personal or third-party test photos. With a Simulator booted, run:

```sh
./scripts/load_test_closet_images.sh
```

The loader records a content digest inside each booted Simulator and skips images already loaded by an earlier run, as well as same-content duplicates within the source folder. Erasing the Simulator clears this tracking with the rest of its data.

Open **Closet → Import** and multi-select up to 50 images. This route may not preserve filenames, so the importer falls back to Apple's on-device Vision classifier. Specific garment labels are preferred over broad clothing/jacket results; any generic, low-confidence, or unmatched image defaults safely and is called out for manual review. Imported names are automatically suffixed when a batch would create duplicates.

For deterministic results, include the type in each filename, such as `blue-shirt.jpg`, `dark-jeans.png`, `white-sneakers.jpeg`, `rain-jacket.jpg`, or `black-watch.png`. Make those files available to the simulator's Files app through iCloud Drive or another configured document provider, then open **Closet → + → Import image files**. Filename rules take priority over Vision classification.

The iOS Simulator cannot let the app read an arbitrary Mac project directory directly because the app runs in an iOS sandbox. The loader script is the supported bridge from `TestClosetImages/` to Simulator Photos.

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

Import your own top and bottom (or one-piece) from **Closet → Import**. Footwear is included when available. The debug-only `-loadPrototypeSamples` launch argument remains available for automated smoke tests; the real-user app intentionally has no demo wardrobe.

### Outfit generation fails

Check availability, selected season/formality, locked category conflicts, whether the closet contains a valid top-and-bottom or one-piece base, and whether an alternative exists. The error should remain actionable; the Generate closet check should route category problems back to editable piece metadata.

### Weather unavailable

Use a city or season-only mode. Live weather is optional. Network unit tests should replace the provider with a future injected fake rather than depend on Open-Meteo.

### Simulator service errors

The September 9 launch failure was reproduced outside Xcode. Simulator logs showed a successful delta installation followed by SpringBoard refusing to launch an app it still considered “being updated.” A synchronous signed `simctl install` cleared the stale placeholder without uninstalling or erasing app data. The shared scheme now performs that preparation on every Simulator Run. Do not disable code signing, uninstall the app, erase simulator data, or change bundle identifiers as a routine workaround.

Use the shared `myCloset` scheme so its Run pre-action is included. After editing a scheme file outside Xcode, close the project before applying the edit, then reopen it: Xcode can keep the old scheme in memory and overwrite external changes when closing its scheme editor. Verify **Edit Scheme → Run → Pre-actions → Prepare simulator installation** and the preparation timestamp after a real run. Unsigned compile-only output must never be installed. Keep automated XCTest on the separate simulator created by `scripts/test_ios.py`; never run resetting UI tests on the interactive device.

If an unrelated CoreSimulator failure remains, retain the error details and simulator logs for diagnosis. Confirm the selected runtime is installed with:


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
