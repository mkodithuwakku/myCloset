# Phase 0 — Local Prototype and Engineering Foundation

**Status:** Complete
**Release marker:** 0.1.0
**Purpose:** Validate the private wardrobe-to-outfit loop before broader product investment.

## Outcome

A user can launch a native iPhone app, load sample pieces or create private local items, receive a season/weather-aware daily outfit, generate for an occasion/formality, lock or reroll pieces, and retain saved/worn history.

## Delivered scope

- Five-tab SwiftUI application shell with a truthful Following Coming Soon state.
- Local `Codable` wardrobe/profile/history persistence.
- Closet add/bulk-import/edit/search/filter/favorite/availability/archive/delete.
- Garment Photos/Files import, filename/Vision type suggestion, resizing, palette suggestion, and manual confirmation.
- Multi-season and multi-formality metadata.
- Duplicate-name warning without forced merge.
- Optional current-location/city weather and season fallback.
- Deterministic outfit structure, availability, exclusion, and lock rules.
- Soft scoring for formality, color relationship, favorites, and variety.
- Daily recommendation, generator, individual reroll, unlocked reroll.
- Saved and worn immutable snapshots.
- Shared Xcode scheme, CI workflow, 37 unit and 3 UI tests.
- SRS, roadmap, architecture, testing, traceability, and contributor documentation.

## Explicit exclusions

- Authentication and accounts.
- Cloud/media sync.
- Real following, feed, posts, reports, blocking, or moderation.
- Direct camera capture and foreground segmentation.
- Trip/packing workflows.
- Push notifications, export, deletion, operations, and store submission.

## Key decisions

- Local-first prototype: [ADR-0001](../decisions/0001-local-first-prototype.md).
- Deterministic constraints around scoring: [ADR-0002](../decisions/0002-hybrid-recommendation-engine.md).
- No fake social data; the Following placeholder communicates the approved post-release plan without simulating activity.
- No third-party package dependency for Phase 0.

## Verification evidence

- Generic iOS Simulator build passes.
- `myClosetTests`: 37 passing tests.
- `myClosetUITests`: 3 passing journeys.
- Runtime verified on iPhone 17 Pro simulator / iOS 26.3.
- Empty and seeded Home states visually reviewed.
- Generated result with lock/reroll controls visually reviewed.

See [Prototype Status](../../PROTOTYPE_STATUS.md) and [Testing](../TESTING.md).

## Accepted debt handed to later phases

- Store combines state/repository/orchestration.
- Persistence lacks schema version and uses embedded image data.
- Image colors include background pixels.
- Weather adapter is not injectable/cached.
- Random source is not injectable.
- Accessibility has foundations but not a full manual audit.

## Exit criteria

- [x] Core loop works without network/account.
- [x] No invalid fabricated item is returned.
- [x] Locked/unavailable/structural rules have automated coverage.
- [x] Persistence survives relaunch.
- [x] Current limitations are visible and documented.
- [x] Phase 1 has an implementable scope and entry state.
