# Changelog

All notable changes to myCloset are recorded here. The project follows a lightweight form of [Keep a Changelog](https://keepachangelog.com/) while it is pre-1.0.

## [Unreleased]

### Fixed

- Made the Simulator media loader verify the actual camera roll on every run, preventing stale loader markers or repeated commands from copying the same test images again.
- Tightened the outfit canvas waist overlap and normalized footwear placement so isolated pieces read as one dressed look instead of disconnected images.
- Made the import-review flow so metadata choices advance to the next relevant section and confirming one piece returns immediately to the top of the next piece.
- Expanded low-confidence footwear recognition and shoe-related filename vocabulary without allowing generic clothing labels to override a specific shoe result.
- Prevented photographed floors and other untrusted backgrounds from becoming accent suggestions when a dependable foreground mask is unavailable.
- Replaced separated outfit-photo cards with a body-aligned composition that overlaps tops, outerwear, bottoms, footwear, and accessories like a dressed flat lay.
- Reworked on-device color suggestions to select and inset one garment-like foreground instance, emphasize the garment center, classify neutrals and hues perceptually, suppress background leakage, and omit insignificant accent colors.
- Added explicit jacket and hoodie outerwear suggestions after structural bottom detection.
- Made generated import names follow confirmed type and main-color changes until the user manually edits the name, after which the custom name remains fixed.
- Made the documentation gate portable to a clean GitHub-hosted macOS runner without assuming `ripgrep` is installed.
- Prevented valid closets from dead-ending when the only owned category match has different season/formality metadata; these fields now influence ranking but fall back to the best available owned piece.
- Made a one-piece reliably complete an outfit when the closet does not contain both separates, and preserved the current look when a reroll has no replacement.
- Made full outfit rerolls search for an actually different valid combination while preserving locked pieces, with honest feedback when the current brief has only one possible look.
- Replaced unreliable jeans/jacket label precedence with foreground-silhouette analysis for top-versus-bottom separation, while retaining dependable filename and footwear signals.
- Expanded foreground-shape detection to recognize wide trousers and compact shorts in Photos imports while keeping jacket-like silhouettes out of the bottom category.
- Made the Simulator media loader content-idempotent per Simulator so repeated runs and same-content source files no longer add duplicate gallery assets.
- Made every user-triggered outfit generation attempt scroll to its result and show immediate failure feedback instead of appearing to ignore the tap.
- Removed the demo wardrobe from every user-facing path and automatically cleans up the complete legacy photo-free sample set without touching imported items.
- Prevented imported and re-analyzed metadata suggestions from being written directly to the closet; every piece must now be reviewed and confirmed first, and generic silhouette classifications are always marked uncertain.

### Added

- Added a visible “Analyzing x of y” counter for large Photos, Files, and re-analysis batches.
- Added per-photo skip controls so accidental selections can be removed without cancelling the remaining import.
- Added left/right rotation and one-tap reset to the quick garment crop editor.
- Added separate type, colour, and cutout confidence guidance with an explicit “Please check” warning for weak or merely likely results and a one-tap explicit confirmation path only when all three signals are strong.
- Added single-item photo re-analysis inside the piece editor while preserving curated name, season, formality, favorite, and availability fields until save.
- Added a post-import summary with per-category counts, skipped/failed-image details, and an actionable closet-readiness result.
- Added kind-aware and category-aware season defaults, including spring/summer defaults for shorts, while keeping every suggested season user-editable.
- Added on-device transparent garment renditions for outfit composition plus a fast movable crop control when automatic isolation or framing needs correction.
- Added garment-kind-aware import defaults: opaque Photos/file names now become useful color-and-kind names such as “Blue Shorts,” with editable type, season, formality, dominant color, and accent color suggestions.
- Added a required sequential import-review screen where the photo, name, type, dominant/accent colors, seasons, and formality can be corrected for every piece before the batch is committed; canceling saves nothing.
- Added kind-specific defaults for common garments including shorts, shirts, jeans, dresses, coats, footwear, and accessories, while keeping uncertain on-device Vision results explicitly reviewable.
- Added on-device foreground-instance masking so dominant and accent colors are sampled from the garment instead of the room or product-photo background.
- Added a user-confirmed batch re-analysis action for repairing the detected types and colors of existing photographed pieces without overwriting curated names, seasons, formality, favorites, or availability.
- Expanded Closet search across names, categories, colors, seasons, and formalities, and exposed detected color beside each closet card's type.
- Added automatic metadata suggestions when choosing a photo for a new manual item; replacing an existing item's photo refreshes colors without overwriting curated details.
- Updated the Simulator media loader to import WebP test assets through temporary JPEG copies without modifying the source images.
- Added a root `AGENTS.md` durable Codex handoff covering current product boundaries, architecture, commands, testing expectations, documentation synchronization, and phase priorities.
- Added bulk Photos and Files closet import for up to 50 images, with filename-first and on-device Vision clothing-type suggestions, automatic color/default metadata, duplicate-name suffixing, progress, and review feedback.
- Added deterministic clothing-type, footwear, outerwear, silhouette, Vision-mask-format, confidence-assessment, perceptual foreground-color, transparent-background, isolation-fallback, crop/rotation, import-summary/readiness, outfit-layout, snapshot-rendition, batch-persistence, legacy-demo cleanup, recommendation-fallback, alternative-generation, and guided import-review UI coverage; the current suite contains 69 unit tests and 6 UI tests.
- Added a repository-local `TestClosetImages/` workflow and simulator loader script; test photos remain ignored by Git.
- Added ADR-0003 and SRS 1.1 to establish a zero-backend, on-device App Store release with no mandatory recurring service cost beyond Apple Developer Program membership.
- Added ADR-0004, SRS 1.2, and a dedicated post-release phase for gated CloudKit profiles, following, controlled outfit posts, and required safety operations.

### Changed

- Rebuilt Generate as a photo-first editorial fitting room: the complete outfit is now the dominant canvas, imported images preserve their aspect ratio, the first valid look appears automatically, and generation/filter controls sit beneath it.
- Replaced Generate's settings-style filters with an optional visual brief for scene and dressed-up level; generation starts from the full eligible closet without requiring a starting piece, while generated pieces can still be locked for rerolls.
- Replaced the rounded-card visual language with a sharper paper-and-ink system, restrained forest accents, serif display typography, monospaced utility labels, and an intentionally asymmetric outfit board shared by Home and Generate.
- Reworked Home into a minimal, whitespace-led experience with compact weather context, a composed garment-image outfit canvas, one primary worn action, and a secondary bookmark action.
- Replaced the placeholder-name greeting with a natural “there” fallback until the user edits their profile.
- Restored Following as a minimal Coming Soon tab with no fake profiles, posts, counts, or service behavior.
- Kept the first release local-only while approving CloudKit social after release interest and safety gates pass; conventional backend, cloud AI, and private-closet upload remain unapproved.

### Planned

- Phase 1 guided camera capture, brush-based mask correction, calibrated photo/color confidence, and persistence migration.
- Phase 7 CloudKit profiles and following after the first App Store release demonstrates user interest.

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
