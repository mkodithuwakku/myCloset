# Phase 4 — Social Profiles, Following, Posting, and Safety

**Status:** Planned
**Primary SRS groups:** PROF, SOC, POST, SAFE, ADM, PRIV, STORE
**Goal:** Enable outfit inspiration without exposing closets or shipping unsafe user-generated content operations.

## Non-negotiable dependency

Real posting cannot launch without reporting, blocking, moderation, deletion propagation, published guidelines/contact, and operational response ownership. Safety is part of the feature, not a later enhancement.

## Entry criteria

- Phase 2 identity/private media/authorization is production-ready.
- Phase 3 creates immutable, explainable outfit snapshots.
- Community Guidelines, moderation policy, escalation, and appeal design are approved.
- Moderation staffing/ownership and launch-region coverage exist.

## User outcomes

- Edit a public-facing profile and profile picture.
- Search authenticated users by handle/display name.
- Follow/unfollow and view reverse-chronological followed posts.
- Confirm worn outfit, choose a photo, preview safe snapshot, publish explicitly.
- Delete own post while retaining private worn history.
- Report and block from every relevant surface.
- No likes, reactions, comments, DMs, or engagement ranking.

## Privacy architecture

- Closet service remains owner-only.
- Post creation copies approved fields/renditions into a detached immutable snapshot.
- Snapshot excludes live closet IDs/URLs, availability, notes, feedback, trips, and full inventory.
- EXIF location is stripped.
- Block filtering applies to search, feed, profiles, follower lists, notifications, and direct URL/API access.
- Account/post deletion invalidates CDN/media derivatives.

## Trust and safety

- Structured report reasons and optional detail.
- Severe-content screening and review queue.
- Moderator actions: no action, remove, warn, restrict, suspend, permanently remove.
- Least-privilege console with MFA and tamper-evident audit.
- Reporter confidentiality and user appeal/support path.
- Response dashboards, queue alerts, incident escalation, and evidence retention policy.

## Abuse controls

- Search/follow/post/report rate limits.
- Spam/impersonation signals and handle policy.
- Upload validation/malware/media limits.
- Block evasion and account-creation abuse monitoring.
- No public popularity counts or recommendation amplification in v1.

## Test plan

- Full follow/unfollow/block relationship matrix.
- Block enforcement across every discovery/serving path.
- Post snapshot cannot retrieve live closet/trip resources.
- Author edit/delete and account-deletion propagation.
- Report lifecycle, role access, audit events, appeals.
- Feed pagination/order and removed-content invalidation.
- Upload policy and EXIF stripping.
- Accessibility for post/report/block flows.
- App Store UGC review checklist.

## Exit criteria

- [ ] Detached snapshots pass privacy/authorization review.
- [ ] Block hides both accounts across all normal/API surfaces.
- [ ] Report → review → enforcement → appeal is operational end-to-end.
- [ ] Community Guidelines and support contact are public.
- [ ] Moderation response ownership and alerting are active.
- [ ] Account deletion removes public posts/media as required.
- [ ] No likes/comments/DM controls or endpoints are exposed.
- [ ] App Store UGC obligations are rechecked immediately before release.
