# Test Execution Report — 2026-09-01

## Summary

| Gate | Result |
|---|---|
| Generic iOS Simulator build | **Passed** |
| Full shared-scheme suite | **Passed** |
| Unit tests | 56 passed, 0 failed |
| UI journey tests | 5 passed, 0 failed |
| Total | **61 passed, 0 failed** |
| Repeated Simulator media load | **0 duplicate imports** |
| Documentation validation | Passed |
| Diff whitespace validation | Passed |

## Environment

- Host toolchain: Xcode 26.3 (build 17C529)
- Destination: iPhone 17 simulator
- Simulator OS: iOS 26.3.1
- App deployment target: iOS 17.0
- Scheme and plan: shared `myCloset` scheme and `myCloset.xctestplan`
- Execution date: September 1, 2026

## Commands

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetFinalBuild \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetFinalTests \
  test

./scripts/load_test_closet_images.sh
./scripts/load_test_closet_images.sh
./scripts/verify_docs.sh
git diff --check
```

## New behavior exercised

- a full reroll searches for a different eligible outfit while preserving locked pieces and structural constraints;
- foreground silhouette tests distinguish split-leg wide trousers and compact shorts from tops even when semantic labels are generic;
- strong jeans labels and compact center openings cannot turn a jacket-shaped garment into a bottom, while dependable footwear signals remain available;
- dominant and accent extraction uses an on-device foreground-instance mask before palette quantization;
- garment-color extraction selects and insets one foreground instance, emphasizes its center, separates chromatic hues from neutrals perceptually, and suppresses insignificant accent votes;
- supplied local garment fixtures were used diagnostically to confirm navy trousers stay navy while black outerwear/shorts, a white sweater, blue shirts, orange shorts, and yellow/white garments resolve to their visible main color despite floors, rugs, and sheets;
- explicit jacket and hoodie evidence now suggests outerwear after split-leg bottom detection has had first refusal;
- existing photographed pieces can be explicitly re-analyzed without overwriting curated non-analysis metadata;
- new imports and re-analysis results remain uncommitted until the user reviews every photo and confirms editable name, type, dominant/accent colors, seasons, and formality;
- the import-review UI test verifies a category change updates the generated name, a manual rename disables later auto-renaming, and the corrected piece appears only after confirmation;
- user-triggered generation always scrolls to the outfit/result area and immediately surfaces an actionable failure message;
- the Generate UI automatically renders an unlocked outfit, opens the visual brief without a starting-piece prompt, selects the Work scene, applies the brief, and retains generated-piece lock controls;
- the Simulator media loader imported 27 unique images from 28 source files on its first run, then imported zero and skipped all 28 on its second run;
- incomplete imported closets receive category counts and a direct route to correcting piece metadata;
- all earlier empty-closet import, editable metadata, persistence, history, recommendation, weather, image, and truthful Following journeys remain green.

The Generate screen was also installed and launched on the iPhone 17 simulator. Its 448-point outfit board remained the primary visual, while the Brief and Another Look actions stayed secondary beneath it.

## Remaining qualification work

Apple's general Vision classifier remains best-effort and its exact labels vary by OS release. Structural silhouette analysis reduces the specific top/bottom failure mode but is still advisory. User-adjustable masks/crops, confidence and quality guidance, physical-device permission testing, schema migrations, accessibility audit, and TestFlight/App Store qualification remain Phase 1 or Phase 6 work.
