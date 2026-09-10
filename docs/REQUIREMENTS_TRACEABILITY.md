# Requirements Traceability

This document maps SRS requirement groups to implementation phases and current verification. Individual work items should link to specific IDs; this is the program-level map.

## Status legend

- **Implemented:** present in Phase 0 at prototype quality.
- **Partial:** useful subset exists; production requirement remains open.
- **Planned:** assigned to a future phase.
- **Excluded:** explicitly outside current product scope.

## Traceability matrix

| SRS group | Phase | Current status | Implementation/evidence |
|---|---:|---|---|
| AUTH — authentication/account lifecycle | 2 | Excluded | Conventional account backend is superseded; Phase 7 uses iCloud-scoped CloudKit ownership only after release |
| ONB — onboarding/permissions | 1, 6 | Partial | Empty/sample flow exists; account-free onboarding remains |
| PROF — local/public profile | 0, 6, 7 | Partial | Local profile editing implemented; controlled CloudKit public profile planned after release |
| SOC — following/feed | 7 | Planned | Coming Soon navigation implemented; CloudKit service gated on interest and safety |
| ITEM — capture/creation | 0, 1 | Partial | Import and fully editable image-derived defaults implemented; every new/replacement photo requires a category-independent closed lasso before metadata confirmation, with experimental guided edge refinement, Refined/My outline comparison and explicit application, exterior transparency, retrace/multiple-region/rotate/reset recovery, progress, skip recovery, separate review guidance, expanded footwear/outerwear recognition, guided review, single-item re-analysis, summaries, and synchronized default names covered; guided camera, calibrated quality confidence, and outline-point refinement remain Phase 1 |
| CLO — closet management/privacy | 0, 1 | Partial | Local CRUD, metadata-aware search/filter, and availability implemented; capture quality remains |
| WEA — weather/season | 0, 3 | Partial | Location/city/season works; resilience/caching/safety Phase 3 |
| HOME — Outfit of the Day | 0, 3 | Partial | Local daily outfit; production stability/personalization Phase 3 |
| GEN — generation inputs | 0, 3 | Partial | Optional visual preset/formality brief and weather implemented; generation requires no starting piece and structured free text is deferred |
| COMP — composition/locks/rerolls | 0, 3 | Partial | Core invariants, single-piece reroll, and different-look search implemented/tested; richer rules/undo Phase 3 |
| REC — recommendation engine | 0, 3 | Partial | Deterministic local rules/scoring; versioning/replay/feedback Phase 3 |
| FB — feedback | 3 | Planned | Save/worn signals only; explicit feedback/preferences deferred |
| HIST — saved/worn history | 0, 3 | Partial | Local immutable snapshots; local filters/preferences remain |
| POST — outfit posts | 7 | Planned | Detached generated-outfit composition posts planned through CloudKit after release |
| TRIP — trip planning | 5 | Planned | Local-only Phase 5 |
| NOTIF — notifications | 5 | Excluded | No notification service in approved release |
| SAFE — reporting/moderation | 7 | Planned | Required before CloudKit social activation; not active in first release |
| SET — settings/help/legal | 0, 6 | Partial | Local settings/reset implemented; release legal/help remains |
| ADM — administration | 2, 4 | Excluded | No backend or remote administration |
| ARCH | 0, 1, 3, 5, 6, 7 | Partial | First release is local; optional CloudKit social stays behind a repository boundary |
| SEC | 0, 1, 6, 7 | Partial | Local-container controls exist; CloudKit ownership/block/report controls are Phase 7 gates |
| PRIV | 0, 1, 6, 7 | Partial | Local/private boundary; detached public-snapshot review is required before Phase 7 activation |
| A11Y | Every phase | Partial | Native/label foundations; full manual audit Phase 6 |
| PERF/REL/SCALE | 3, 6, 7, 8 | Planned | Phase 0 functional measurements only |
| OFF | 0, 5 | Partial | Local reads work; local trips/recovery Phase 5 |
| OBS | 6 | Excluded | No paid/hosted telemetry; Apple-provided diagnostics may be used |
| ENG | Every phase | Partial | Shared scheme, CI, tests, docs; expands continuously |
| COMPAT | 0, 6 | Partial | iPhone/iOS 17 target; release matrix Phase 6 |
| STORE | 6 | Planned | Phase 6 release work |
| COST | Every phase | Implemented | ADR-0003 protects the local release; ADR-0004 limits later social to included CloudKit capacity |

## Phase 0 verification links

| Behavior | Code | Automated evidence |
|---|---|---|
| Closet models and metadata | `myCloset/Models.swift` | `ModelsAndImageTests` |
| Local persistence and history | `myCloset/ClosetStore.swift` | `ClosetStoreTests` |
| Outfit constraints/scoring | `myCloset/OutfitEngine.swift` | `OutfitEngineTests` |
| Photo preparation, required closed-lasso isolation, preview-to-cutout orientation including asymmetric hems/sleeves and separate off-center regions, exterior transparency, rotation/reset recovery, garment-focused perceptual colors, and accent suppression | `myCloset/ImageUtilities.swift`, `myCloset/GarmentOutlineEditor.swift` | `ModelsAndImageTests`, `MyClosetUITests.testImportRequiresSimpleLassoBeforeMetadata` |
| Footwear/outerwear suggestions, season defaults, separate review confidence, guided review, and synchronized import names | `myCloset/ClothingTypeDetector.swift`, `myCloset/ClosetImportReviewView.swift` | `ClothingTypeDetectorTests`, `MyClosetUITests` |
| Batch progress, image metadata suggestions, batch/single-item re-analysis, and import readiness summary | `myCloset/ClothingTypeDetector.swift`, `myCloset/ClosetView.swift`, `myCloset/ClosetImportSummaryView.swift` | `ClothingTypeDetectorTests`, `ClosetImportSummaryTests`, `ClosetStoreTests` |
| Required per-piece import confirmation, skip recovery, metadata progression, and next-piece top reset | `myCloset/ClosetImportReviewView.swift`, `myCloset/ClosetView.swift` | `MyClosetUITests.testImportedPieceMustBeConfirmedAndCanBeCorrectedBeforeSaving`, `MyClosetUITests.testImportReviewCanSkipAnAccidentalPhoto` |
| Empty → personal image import | `HomeView`, `ClosetView`, `ClosetStore` | `MyClosetUITests.testEmptyClosetStartsWithOwnImageImport`, `ClosetStoreTests.testLegacySampleClosetIsRemovedOnNextLaunchWithoutTouchingImportedItems` |
| Closet → body-aligned isolated Generate composition | `ClosetView`, `GeneratorView`, `OutfitCanvas` | `MyClosetUITests.testCoreClosetAndGeneratorJourney`, `ModelsAndImageTests.testSnapshotPrefersIsolatedOutfitRendition`, `ModelsAndImageTests.testOutfitLayoutOverlapsWaistAndStandardizesFootwearScale`, `OutfitEngineTests.testAlternativeGenerationChangesAvailableSlotsAndKeepsLocks`, `OutfitEngineTests.testSeasonPreferenceFallsBackToOwnedPieces`, `OutfitEngineTests.testOnePieceCompletesOutfitWhenSeparatesAreIncomplete` |
| Closet piece → editable metadata | `ClosetView` | `MyClosetUITests.testClosetPieceOpensEditableMetadata` |
| Selectable and persisted garment types/defaults (ITEM-002–ITEM-003, ITEM-013–ITEM-018) | `Models`, `ClosetView`, `ClosetImportReviewView`, `ClothingTypeDetector` | Specific-type model/default and legacy-decoding tests, `ClosetStoreTests.testSpecificTypesPersistAndDeletionKeepsSavedAndWornSnapshots`, `MyClosetUITests.testSpecificImportTypeUpdatesAutomaticNameSeasonsAndSavedDetails` |
| Hold-menu deletion with history preservation (CLO-009–CLO-010) | `ClosetItemCard`, `ClosetStore` | `MyClosetUITests.testLongPressDeleteCanBeCancelledThenPersistsAfterRelaunch`, snapshot persistence tests |
| Shoe-pair outlining, proportional footwear, and smaller upper-body pieces (ITEM-005, HOME-002) | `GarmentOutlineEditor`, `OutfitCanvasLayout` | Lasso UI guidance, top/jacket-to-pants width and overlap limits, and footwear sizing/board-bound tests |
| Jacket replaces the top, including locks, replacements, and readiness (COMP-001–COMP-002, COMP-005–COMP-013) | `OutfitEngine`, `GeneratorView`, `ClosetImportSummary`, ADR-0005 | Five repeated-generation/lock/replacement regressions in `OutfitEngineTests`, `ClosetImportSummaryTests.testJacketAndBottomAreReadyWithoutAShirt` |
| Following roadmap state | `FollowingView` | `MyClosetUITests.testFollowingIsClearlyMarkedComingSoon` |

## Traceability workflow

Each pull request should state:

1. affected SRS IDs;
2. roadmap phase;
3. code and migration artifacts;
4. automated/manual evidence;
5. requirements still open;
6. documentation updated.

This file must be updated when a requirement group changes phase or status. Fine-grained requirement-to-test links may move into a test-management system as the project grows, but stable SRS IDs remain authoritative.

Simulator launch reliability (ENG-004–ENG-006) is covered by the shared Run pre-action, `scripts/tests/test_simulator_run.py` (8 host-side checks), the isolated `scripts/test_ios.py` runner, and repeated Command-R/cold-start execution evidence. These workflow checks are separate from the app’s 91 unit and 10 UI tests.

Outline-guided refinement (ITEM-007–ITEM-008, ITEM-019, PERF-007) is covered by `GarmentEdgeRefinerTests`: inward/outward correction, asymmetric hem and color preservation, separate shoes, ambiguous-color recovery, invalid/large images, instance selection, destructive-mask rejection, and cancellation. The comparison/apply/retrace journey is covered by `testRefinedOutlineCanBeComparedAppliedAndClearedForRetracing`. Device-specific Vision accuracy remains a physical-device gate.
