# Changelog

All notable changes to myCloset are recorded here. The project follows a lightweight form of [Keep a Changelog](https://keepachangelog.com/) while it is pre-1.0.

## [Unreleased]

### Fixed

- Made the documentation gate portable to a clean GitHub-hosted macOS runner without assuming `ripgrep` is installed.

### Added

- Added a root `AGENTS.md` durable Codex handoff covering current product boundaries, architecture, commands, testing expectations, documentation synchronization, and phase priorities.
- Added bulk Photos and Files closet import for up to 50 images, with filename-first and on-device Vision clothing-type suggestions, automatic color/default metadata, duplicate-name suffixing, progress, and review feedback.
- Added deterministic clothing-type and batch-persistence coverage, bringing the suite to 37 unit tests and 3 UI tests.

### Changed

- Reworked Home into a minimal, whitespace-led experience with compact weather context, a composed garment-image outfit canvas, one primary worn action, and a secondary bookmark action.
- Replaced the placeholder-name greeting with a natural “there” fallback until the user edits their profile.

### Planned

- Phase 1 guided camera capture, foreground isolation, crop correction, and improved color confidence.

## [0.1.0] - 2026-07-14

### Added

- Native SwiftUI iPhone application with Home, Closet, Generate, Following, and Profile tabs.
- Local closet CRUD, search, category filters, favorites, availability, archive, and deletion.
- Garment photo import, resizing, and editable dominant/accent palette suggestions.
- Multiple season and formality assignments per garment.
- Duplicate-name warning using case- and whitespace-normalized comparison.
- Season, current-location weather, and manual-city weather context.
- Deterministic outfit structure and lock enforcement with preference scoring.
- Occasion/formality generator, piece locking, individual rerolling, and unlocked rerolling.
- Outfit of the Day with explanation, saving, and worn confirmation.
- Immutable saved/worn outfit snapshots and local profile editing.
- Twelve-piece sample closet and deterministic UI smoke-test launch controls.
- Unit and UI test targets with 33 automated tests.
- SRS, architecture, roadmap, phase, testing, development, security, and contribution documentation.
- GitHub Actions build/test workflow and repository issue/pull-request templates.

### Known limitations

- No backend, authentication, cloud sync, live social activity, trips, moderation, or push notifications.
- Photo import does not yet remove backgrounds or provide direct guided camera capture.
- Recommendation learning and production-grade weather resilience are deferred.
