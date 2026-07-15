# ADR-0003: Ship the first App Store release without a backend

**Status:** Accepted
**Date:** 2026-07-14

## Context

The expected audience is the product owner's friends and a small number of organic App Store users. The product owner will pay for Apple Developer Program membership but does not authorize a recurring backend, hosted media, paid AI, authentication, moderation, or operational-service bill.

The useful wardrobe loop already works locally. Accounts, public posting, following, and cloud synchronization would add disproportionate privacy, safety, support, and cost obligations.

## Decision

The first public release is a self-contained iPhone application:

- closet, profile, saved/worn history, preferences, and future trips remain in the app container;
- clothing analysis, color detection, recommendation generation, feedback, and explanations run on-device;
- there is no myCloset backend, account, social feed, public post, hosted media, cloud AI, or remote administration;
- live weather may use an allowance included with Apple Developer Program membership or a provider whose terms permit the free no-advertising app, with date-derived season as a permanent fallback;
- public privacy/support pages should use no-charge static hosting;
- any new mandatory recurring service cost requires a new ADR and explicit product-owner approval.

## Consequences

### Positive

- Mandatory operating cash cost is limited to Apple Developer Program membership.
- Private wardrobe photos are not uploaded to a developer-operated service.
- Outfit generation and clothing analysis have no per-use API charge.
- The app remains useful offline and is simpler to test and operate.

### Negative

- No cross-device synchronization or cloud recovery.
- Uninstalling the app may remove local data.
- Users cannot follow friends or publish outfits through myCloset.
- Remote support cannot inspect or repair user data.

## Guardrails

- Do not add an SDK or provider that becomes necessary for core functionality or creates a mandatory recurring charge.
- Do not add sign-in merely for identity presentation; there is no account-backed service.
- Keep deterministic generation and date-derived season functional without network access.
- App Store copy and in-app settings must clearly describe local-only storage and deletion behavior.
- Social and cloud phase documents remain optional reference material and are not release dependencies.
