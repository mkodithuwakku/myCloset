# Phase 7 — Post-Release CloudKit Social

**Status:** Planned after release — approved scope, gated on interest and safety readiness
**Primary SRS groups:** PROF, SOC, POST, SAFE, PRIV, SEC, STORE, COST
**Goal:** Add useful profiles and following without uploading private closets or creating a separate hosting subscription.

## Release relationship

This phase starts only after Phase 6 ships the stable local application. The launch binary may contain the non-interactive Following Coming Soon screen, but no CloudKit schema, public record write, fabricated social data, or hidden social service is required for the first release.

## Entry criteria

- The first App Store release is stable.
- Released-user feedback demonstrates demand for in-app profiles or following.
- The product owner records the evidence and names the person responsible for support and moderation.
- Current App Store user-generated-content requirements are reviewed.
- CloudKit remains included within Apple Developer Program membership at an acceptable cost.
- Community Guidelines, Privacy Policy changes, report handling, deletion policy, and escalation workflow are approved.

## Initial user outcomes

- Opt into social using the device's iCloud account.
- Choose a unique app-specific handle, display name, and preset avatar.
- Search profiles by exact or prefix handle where CloudKit query behavior permits.
- Follow and unfollow people.
- View a reverse-chronological feed from followed profiles.
- Explicitly publish a detached generated-outfit composition.
- Delete an owned post without deleting private worn history.
- Report a profile or post and block another profile.
- Delete the user's public social records while preserving or separately clearing local closet data.

Likes, reactions, comments, direct messages, contact discovery, public popularity counts, and engagement ranking remain excluded.

## CloudKit record model

The reviewed schema should contain equivalent records for:

- `SocialProfile` — owner identity, normalized handle, display name, preset avatar, lifecycle state;
- `Follow` — follower identity, followed identity, creation time;
- `OutfitPost` — author identity, detached outfit snapshot, generated composition asset, creation time, lifecycle state;
- `Block` — directional relationship sufficient to enforce hiding in both directions;
- `Report` or an approved private report channel — target reference, reason, reporter, status, timestamps;
- `SocialDeletion` or equivalent client workflow — idempotent removal progress where multiple owned records are involved.

Every record type needs documented creator/read/write/delete permissions. Public records must contain no live closet identifier, local image path, trip information, availability state, notes, feedback, location metadata, or private history reference.

## iOS architecture

- Add a `SocialRepository` protocol before CloudKit calls enter a view.
- Keep `ClosetStore` and local repositories authoritative for private wardrobe data.
- Build publishable snapshots and composition assets locally.
- Strip metadata and resize public assets before upload.
- Cache only public social data needed for a usable feed.
- Represent iCloud unavailable, restricted, offline, quota, partial-delete, and account-change states explicitly.
- Keep a remotely or release-configurable kill switch capable of disabling social writes while leaving local features operational.

## Safety and privacy controls

- Filter every editable public text field before save.
- Use only preset avatars and generated outfit compositions in the initial slice.
- Provide Report and Block on every public profile/post surface.
- Enforce blocks in search, profile, feed, follower/following lists, and direct record presentation.
- Publish support contact information and Community Guidelines.
- Define acknowledgement and response targets for reports.
- Keep reporter details confidential.
- Allow manual removal and account restriction through approved CloudKit administration procedures.
- Recheck whether stronger automated media moderation is required before allowing arbitrary public photographs.

## Test plan

- iCloud account available/unavailable/restricted/change cases.
- CloudKit development-to-production schema promotion rehearsal.
- Creator, other-user, and unauthenticated access matrix for each record type.
- Handle normalization, uniqueness conflict, and impersonation cases.
- Follow/unfollow idempotency and self-follow prevention.
- Complete bidirectional block behavior across all discovery paths.
- Detached snapshot cannot resolve local closet records or private media.
- Feed ordering, pagination, deduplication, deletion, and offline cache behavior.
- Report submission and documented manual response rehearsal.
- Social deletion under retries, partial failure, and app relaunch.
- Quota, CloudKit outage, and kill-switch behavior.
- Accessibility and App Store user-generated-content checklist.

## Exit criteria

- [ ] Interest evidence and accountable moderation owner are recorded.
- [ ] CloudKit schema and production promotion are reviewed and rehearsed.
- [ ] Every record type passes the ownership/access-control matrix.
- [ ] Public snapshots contain no live or private closet data.
- [ ] Follow, block, report, delete, and failure flows pass end-to-end.
- [ ] Community Guidelines, Privacy Policy, and support contact are public.
- [ ] Manual moderation and escalation have been rehearsed.
- [ ] Social writes can be disabled without breaking local functionality.
- [ ] Cost review confirms no new mandatory charge beyond Apple Developer Program membership.
- [ ] Current App Store requirements are rechecked immediately before submission.
