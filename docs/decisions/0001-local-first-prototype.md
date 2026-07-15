# ADR-0001: Start with a local-first functional prototype

**Status:** Accepted
**Date:** 2026-07-14

## Context

The full SRS includes authentication, cloud media, social safety, trips, moderation, and App Store operations. Implementing all infrastructure before validating wardrobe entry and outfit generation would delay usable feedback and increase privacy/operational scope.

## Decision

Phase 0 stores the closet, profile, and outfit history in the iOS app container and implements no real accounts or social publishing. The application remains useful through sample/user-entered items and date/weather context.

## Consequences

### Positive

- Immediate usable product loop.
- No backend/API keys required.
- Private data stays local during prototype evaluation.
- Domain rules can be tested before service design.

### Negative

- No cross-device sync or real social feature.
- Local persistence and embedded images do not scale.
- Later migration and repository abstraction are required.

## Guardrails

- Do not present placeholder social data as real.
- Do not call local storage production security/cloud sync.
- Preserve stable IDs/snapshots for later migration.
- Implement identity/authorization before enabling public content.
