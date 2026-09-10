# Test Execution Report — 2026-09-08

## Summary

| Gate | Result |
|---|---|
| Generic iOS Simulator build | **Passed** |
| Full shared-scheme suite | **Passed** |
| Unit tests | 73 passed, 0 failed |
| UI journey tests | 7 passed, 0 failed |
| Total | **80 passed, 0 failed** |
| Documentation validation | Passed |
| Diff whitespace validation | Passed |

## Environment

- Host toolchain: Xcode 26.3 (build 17C529)
- Destination: iPhone 17 Pro simulator
- Simulator OS: iOS 26.3.1
- App deployment target: iOS 17.0
- Scheme and plan: shared `myCloset` scheme and `myCloset.xctestplan`
- Execution date: September 9, 2026 (report updated from the September 8 slice)

## Commands

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetOutlineBuild \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetOutlineFullTests \
  -parallel-testing-enabled NO \
  test

./scripts/verify_docs.sh
git diff --check
```

## New behavior exercised

- imported batches expose observable per-image progress while analysis runs;
- type, colour, and cutout confidence are scored separately, non-strong results are called out for manual review, and all-strong results expose one-tap explicit confirmation;
- accidental images can be skipped without cancelling the remaining batch;
- the crop pipeline supports quarter-turn rotation while retaining movable crop behavior;
- the crop editor offers distinct shirt, long-sleeve, cap, pants, shorts, shoes, dress, jacket/hoodie, and other-accessory guides, metadata-driven defaults, type-specific crop proportions, one-tap fitting, full-source expansion, a finger-traced closed-outline transparent cutout with padded auto-fitting, and an explicit background-preserving quality fallback when no manual mask is traced;
- a pixel-level image test proves the untouched interior of a traced outline remains opaque, the exterior becomes transparent, and the saved manual rendition is trimmed to the selected garment region;
- implausibly tiny, frame-filling, and spatially sparse foreground masks are rejected before a transparent garment rendition is accepted;
- a completed import presents per-category counts, skipped/failed-image details, and actionable outfit-readiness guidance;
- a top plus bottom or one-piece is recognized as a valid generator base;
- body-aligned layout geometry guarantees top/bottom and bottom/footwear overlap with a consistent footwear frame;
- the original guided review journey still preserves manual names, advances between metadata sections, and returns each new piece to the top;
- all prior closet, generator, history, persistence, recommendation, image-isolation, and truthful Following journeys remain green.

## Execution note

One earlier focused UI-test launch encountered the Simulator service's transient `Busy (Application failed preflight checks)` error before any assertion ran. The Simulator was cleanly booted and the affected journey passed. During this slice, the new crop UI test initially found two visible `Cancel` buttons; its selector was scoped to the crop navigation bar and the rerun passed. The first manual-mask implementation was also rejected by the pixel-level test because its blend path did not clear the exterior; direct bitmap-mask compositing fixed the defect. The manual control was then simplified from painting the whole item to tracing its outer edge, with a test proving the untouched enclosed interior is retained. The final full shared-scheme run passed all 80 tests.

## Remaining qualification work

Apple's foreground-instance mask is OS-owned and still requires representative physical-device qualification. Garment templates remain framing guides because garment shapes vary, while a finger-traced lasso provides an explicit hard alpha mask whose enclosed area is retained and exterior is transparent; users can retain the fitted photo instead when they do not trace a manual mask. Outline-point adjustment and undo refinements remain future work. Confidence labels are conservative review guidance, not calibrated accuracy probabilities. Direct camera capture, schema-versioned file storage, minimum-OS/device coverage, and a full accessibility audit remain Phase 1 or Phase 6 work.
