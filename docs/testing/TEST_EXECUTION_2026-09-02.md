# Test Execution Report — 2026-09-02

## Summary

| Gate | Result |
|---|---|
| Generic iOS Simulator build | **Passed** |
| Full shared-scheme suite | **Passed** |
| Unit tests | 62 passed, 0 failed |
| UI journey tests | 5 passed, 0 failed |
| Total | **67 passed, 0 failed** |
| Documentation validation | Passed |
| Diff whitespace validation | Passed |

## Environment

- Host toolchain: Xcode 26.3 (build 17C529)
- Destination: iPhone 17 Pro simulator
- Simulator OS: iOS 26.3.1
- App deployment target: iOS 17.0
- Scheme and plan: shared `myCloset` scheme and `myCloset.xctestplan`
- Execution date: September 2, 2026

## Commands

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetFinalTests \
  -parallel-testing-enabled NO \
  test

./scripts/verify_docs.sh
git diff --check
```

## New behavior exercised

- specific low-confidence shoe labels outrank generic clothing labels, with expanded deterministic shoe and boot filename terms;
- shorts retain spring/summer defaults and corrected broad categories receive editable seasonal starting points;
- transparent garment pixels are excluded from palette analysis and untrusted full-photo backgrounds cannot create an accent suggestion;
- automatic isolation produces a trimmed transparent rendition on a plain background even when the Simulator cannot run Apple's foreground model;
- quick crop sizing and positioning produce the expected output geometry;
- outfit snapshots prefer the private isolated rendition over the original background-bearing photo;
- the sequential import-review UI advances through related metadata sections;
- a manually edited name remains fixed while later category and color choices change;
- confirming one item returns the next item to a visible top-of-review header;
- the corrected two-item review batch is persisted only after final confirmation;
- all prior closet, generator, history, persistence, recommendation, and truthful Following journeys remain green.

## Remaining qualification work

Apple's foreground-instance mask is OS-owned and requires representative physical-device qualification. The app now preserves the original, saves a transparent rendition when the mask succeeds, and offers a fast crop fallback, but confidence scoring, brush-based mask repair and recovery, rotation/reset, direct camera capture, schema-versioned file storage, and a full accessibility audit remain Phase 1 or Phase 6 work.
