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
| AUTH — authentication/account lifecycle | 2 | Excluded | Deferred/unfunded; no account in approved release |
| ONB — onboarding/permissions | 1, 6 | Partial | Empty/sample flow exists; account-free onboarding remains |
| PROF — local profile | 0, 6 | Partial | Local profile editing implemented; no public profile |
| SOC — following/feed | 4 | Excluded | Deferred/unfunded; no social navigation or service |
| ITEM — capture/creation | 0, 1 | Partial | Import/metadata/colors implemented; guided camera/segmentation Phase 1 |
| CLO — closet management/privacy | 0, 1 | Partial | Local CRUD/filter/availability implemented; capture quality remains |
| WEA — weather/season | 0, 3 | Partial | Location/city/season works; resilience/caching/safety Phase 3 |
| HOME — Outfit of the Day | 0, 3 | Partial | Local daily outfit; production stability/personalization Phase 3 |
| GEN — generation inputs | 0, 3 | Partial | Presets/formality/weather; structured free text deferred |
| COMP — composition/locks/rerolls | 0, 3 | Partial | Core invariants and rerolls implemented/tested; richer rules/undo Phase 3 |
| REC — recommendation engine | 0, 3 | Partial | Deterministic local rules/scoring; versioning/replay/feedback Phase 3 |
| FB — feedback | 3 | Planned | Save/worn signals only; explicit feedback/preferences deferred |
| HIST — saved/worn history | 0, 3 | Partial | Local immutable snapshots; local filters/preferences remain |
| POST — outfit posts | 4 | Excluded | Deferred/unfunded; would require identity, hosted media, and safety operations |
| TRIP — trip planning | 5 | Planned | Local-only Phase 5 |
| NOTIF — notifications | 5 | Excluded | No notification service in approved release |
| SAFE — reporting/moderation | 4 | Excluded | Not applicable without public user-generated content |
| SET — settings/help/legal | 0, 6 | Partial | Local settings/reset implemented; release legal/help remains |
| ADM — administration | 2, 4 | Excluded | No backend or remote administration |
| ARCH | 0, 1, 3, 5, 6 | Partial | Approved target is on-device with local repository boundaries |
| SEC | 0, 1, 6 | Partial | Local-container and mobile security controls only |
| PRIV | 0, 1, 6 | Partial | Local/private boundary; formal release assessment remains |
| A11Y | Every phase | Partial | Native/label foundations; full manual audit Phase 6 |
| PERF/REL/SCALE | 3, 6, 7 | Planned | Phase 0 functional measurements only |
| OFF | 0, 5 | Partial | Local reads work; local trips/recovery Phase 5 |
| OBS | 6 | Excluded | No paid/hosted telemetry; Apple-provided diagnostics may be used |
| ENG | Every phase | Partial | Shared scheme, CI, tests, docs; expands continuously |
| COMPAT | 0, 6 | Partial | iPhone/iOS 17 target; release matrix Phase 6 |
| STORE | 6 | Planned | Phase 6 release work |
| COST | Every phase | Implemented | ADR-0003 prohibits required backend/paid runtime services |

## Phase 0 verification links

| Behavior | Code | Automated evidence |
|---|---|---|
| Closet models and metadata | `myCloset/Models.swift` | `ModelsAndImageTests` |
| Local persistence and history | `myCloset/ClosetStore.swift` | `ClosetStoreTests` |
| Outfit constraints/scoring | `myCloset/OutfitEngine.swift` | `OutfitEngineTests` |
| Photo preparation/colors | `myCloset/ImageUtilities.swift` | `ModelsAndImageTests` |
| Batch image type suggestions | `myCloset/ClothingTypeDetector.swift`, `myCloset/ClosetView.swift` | `ClothingTypeDetectorTests`, `ClosetStoreTests` |
| Empty → daily outfit | `HomeView`, `ClosetStore` | `MyClosetUITests.testEmptyClosetCanLoadSamplesAndCreateDailyOutfit` |
| Closet → Generate | `ClosetView`, `GeneratorView` | `MyClosetUITests.testCoreClosetAndGeneratorJourney` |

## Traceability workflow

Each pull request should state:

1. affected SRS IDs;
2. roadmap phase;
3. code and migration artifacts;
4. automated/manual evidence;
5. requirements still open;
6. documentation updated.

This file must be updated when a requirement group changes phase or status. Fine-grained requirement-to-test links may move into a test-management system as the project grows, but stable SRS IDs remain authoritative.
