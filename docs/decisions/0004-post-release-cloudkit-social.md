# ADR-0004: Add CloudKit social only after the first release

**Status:** Accepted
**Date:** 2026-07-14

## Context

The product owner wants profiles and following to remain visible in the product direction, but does not want a conventional backend or a recurring hosting bill. The first App Store release must remain useful, private, and account-free. Public profiles and outfit sharing also introduce App Store user-generated-content obligations even for a small audience.

Apple Developer Program membership includes CloudKit capacity suitable for a small iPhone-only social feature. CloudKit can provide public records, assets, iCloud-scoped identity, synchronization, telemetry, and manual data administration without operating a separate application server.

## Decision

1. The first App Store release remains local-only and contains no functioning social service.
2. The Following tab may ship as a minimal, truthful Coming Soon screen. It shall not display fake people, posts, counts, or network states.
3. CloudKit social is an approved post-release phase that begins only after user feedback demonstrates interest and a named owner accepts moderation and support duties.
4. The initial CloudKit social release shall support:
   - an app-specific public handle, display name, and preset avatar;
   - follow and unfollow relationships;
   - a reverse-chronological feed;
   - explicit publication of detached generated-outfit compositions;
   - reporting, blocking, filtering, deletion, published contact information, and manual moderation.
5. Private closet records, original garment images, saved/worn history, trips, feedback, and recommendation preferences remain local and shall not be uploaded for social functionality.
6. Arbitrary public profile photos, body photos, or other user-selected public media require a later privacy and moderation decision. They are not part of the lowest-cost initial social slice.
7. Likes, reactions, comments, direct messages, contact-book discovery, and engagement ranking remain excluded.
8. CloudKit usage must remain within the allowance included with Apple Developer Program membership. If Apple changes availability, terms, or cost, social writes shall be disableable without breaking the local wardrobe product.

## Interest and activation gate

Before implementation begins, the product owner shall record evidence that released users want in-app profiles or following rather than only external sharing. Before activation, engineering shall also provide:

- a reviewed CloudKit schema and environment-promotion plan;
- ownership and access-control tests for every record type;
- a complete follow/unfollow/block behavior matrix;
- detached-snapshot tests proving that posts cannot expose live closet data;
- an in-app report path and documented response workflow;
- content filtering appropriate to every editable public field;
- public Community Guidelines, Privacy Policy, and support contact;
- self-service deletion for the user's public records;
- a kill switch and documented CloudKit quota/health checks;
- a fresh App Store Review Guideline check immediately before submission.

## Consequences

### Positive

- The first release keeps its simple, zero-backend architecture.
- The product direction remains visible without pretending social already works.
- The later social slice adds no planned cash cost beyond Apple Developer Program membership.
- Public posts can be useful while the private closet stays on-device.
- Controlled generated outfit compositions reduce storage and moderation exposure.

### Negative

- Social users must be signed into iCloud to create CloudKit records.
- CloudKit couples the social implementation to Apple platforms.
- Moderation and support still require human time even when hosting costs nothing.
- Social cannot launch immediately after the local release unless every safety gate is ready.
- Arbitrary public user photography is postponed.

## Superseded alternatives

- A conventional backend with Google and Apple authentication remains documented as an optional P2 architecture, not the approved implementation path.
- Firebase and Supabase remain alternatives only if CloudKit cannot satisfy a demonstrated requirement and the product owner approves the resulting billing and migration decision.
