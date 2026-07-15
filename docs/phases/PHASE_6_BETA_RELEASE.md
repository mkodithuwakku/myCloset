# Phase 6 — Beta, Operations, and App Store Release

**Status:** Planned
**Primary SRS groups:** SEC, PRIV, A11Y, PERF, REL, OBS, COMPAT, STORE
**Goal:** Turn the complete P0 product into an operable, compliant public iPhone release.

## Entry criteria

- Product owner confirms which SRS P0 features enter the release candidate.
- Prior phase exit gates are evidenced.
- Final product name/brand ownership process is underway.
- Production infrastructure, support, moderation, and incident owners are assigned.

## Release workstreams

### Product and design

- Complete onboarding, settings, help, errors, empty/offline/permission states.
- Final original visual system, icon, screenshots, localization-ready strings.
- Minimum/maximum iPhone layouts, light/dark appearance, accessibility.

### Security and privacy

- Threat model, OWASP MASVS/ASVS assessment, penetration test.
- Privacy impact and AI risk assessment.
- SDK/subprocessor inventory, retention, deletion, consent, export verification.
- Secret/key rotation, production access review, audit evidence.

### Reliability and operations

- SLO dashboards and alerts.
- Backup restore and disaster recovery exercise.
- Provider outage, queue backlog, cost/quota, and rollback runbooks.
- On-call/support/moderation escalation and incident communications.

### App Store

- Name/trademark/domain/store availability.
- Privacy Policy, Terms, Community Guidelines, support/privacy-choice URLs.
- App Privacy disclosures and permission descriptions.
- Sign in with Apple, account deletion/token revocation.
- UGC reporting/blocking/moderation evidence.
- Signing, bundle IDs, entitlements, export compliance, age rating, reviewer access.

### Beta

- Internal TestFlight for engineering/product.
- External TestFlight cohorts with beta review where required.
- Structured feedback, crash/performance monitoring, staged feature flags.
- Go/no-go review and rollback plan.

## Test and audit plan

- Full regression on supported devices/OS versions.
- VoiceOver, Dynamic Type, Reduce Motion, contrast, keyboard/switch audit.
- Load/soak and media-pipeline capacity.
- Crash-free, launch, generation, upload latency targets.
- Authorization/deletion/privacy adversarial tests.
- Restore and regional provider failure.
- Store reviewer journey from clean install.
- Production-like moderation and support drill.

## Release gates

- [ ] All included P0 requirements pass or have accountable formal deviations.
- [ ] No unresolved critical/high security or privacy issue without time-bound acceptance.
- [ ] Crash-free, latency, availability, and capacity targets pass beta.
- [ ] Account deletion, export, report, block, moderation, and data isolation pass.
- [ ] Accessibility audit has no core-journey blocker.
- [ ] Legal/store disclosures match actual production behavior.
- [ ] Monitoring, runbooks, backup restore, support, and rollback are operational.
- [ ] Final App Review Guidelines are rechecked at submission time.

## Rollout

Use a staged App Store release and feature flags with privacy-safe cohorts. Monitor authentication, uploads, generation failures, crash-free sessions, report backlog, provider health, deletion jobs, and costs. Define rollback triggers before rollout begins.
