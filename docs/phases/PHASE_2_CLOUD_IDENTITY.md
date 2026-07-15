# Phase 2 — Cloud Identity and Private Data

**Status:** Deferred / unfunded — not an App Store release dependency
**Primary SRS groups:** AUTH, CLO, DATA, ARCH, SEC, PRIV, OFF
**Goal:** Add secure accounts and cross-device private data without weakening local usability.

This phase may start only after an explicit product-owner decision to accept recurring backend and operational costs. ADR-0003 supersedes it for the approved first release.

## Entry criteria

- Phase 1 schema/media model is stable.
- Launch regions and data-residency/privacy requirements are selected.
- Backend/cloud provider decision and threat model are approved.
- Privacy Policy draft identifies all processors and purposes.

## User outcomes

- Sign in with Apple or Google.
- Link verified identities without duplicate accounts.
- Keep closet, profile, history, and photos synchronized privately.
- Use cached content during temporary network loss.
- View/revoke sessions, export data, and delete the account in-app.
- Migrate existing local prototype data after explicit sign-in confirmation.

## Backend deliverables

- Versioned mobile API/BFF.
- Identity verification, nonce/state handling, account linking, refresh/revocation.
- Transactional database with owner-scoped records.
- Private object storage and short-lived authorized media access.
- Idempotent item/history/profile mutations.
- Sync cursors/version fields and conflict policy.
- Export job and deletion orchestrator.
- Audit events, rate limits, secret management, backups, restore exercises.

## iOS deliverables

- Sign in with Apple and Google UX.
- Keychain session storage and refresh.
- Repository protocols, local cache, remote adapters, sync coordinator.
- Local-to-cloud import with progress, retry, and duplicate prevention.
- Offline state and pending-operation visibility.
- Session, export, sign-out, and deletion settings.

## Authorization matrix

At minimum test owner/other/anonymous/operator access for:

- profile draft vs future public profile;
- closet metadata and images;
- saved/worn snapshots;
- feedback/preferences;
- trips reserved for Phase 5;
- exports and deletion jobs;
- audit/support data.

Default is deny. Client-side hiding is not authorization.

## Security/privacy requirements

- Validate provider tokens/claims server-side.
- Revoke Sign in with Apple/provider sessions on deletion.
- Encrypt transport and storage; rotate managed keys/secrets.
- Strip logs of tokens, signed URLs, location, and private text.
- Review every SDK/subprocessor and App Store privacy disclosure.
- No generalized model training on private content without separate consent.
- Delete active-system data within SRS period and document backup expiry.

## Test plan

- Provider success/cancel/error/revocation.
- Identity linking and collision cases.
- Multi-account IDOR/authorization matrix.
- Signed URL expiry/scope/revocation.
- Offline create/edit/delete and conflict resolution.
- Repeat/retry/idempotency under network failure.
- Local migration interrupted at every step.
- Export completeness and deletion propagation.
- Backup restore without resurrecting deleted active records.
- API contract/backward compatibility.

## Exit criteria

- [ ] Authentication and account linking pass production-like integration tests.
- [ ] Cross-account closet/media access is denied in adversarial tests.
- [ ] Local data migrates once without loss/duplication.
- [ ] Offline cache and retry behavior are understandable.
- [ ] Export and in-app deletion complete end-to-end.
- [ ] Threat/privacy assessments are approved.
- [ ] Monitoring, backup, restore, and incident runbooks exist.
- [ ] Social publishing remains disabled until Phase 4 safety gates pass.
