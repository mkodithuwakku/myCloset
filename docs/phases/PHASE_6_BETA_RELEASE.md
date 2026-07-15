# Phase 6 — Beta, Operations, and App Store Release

**Status:** Planned
**Primary SRS groups:** SEC, PRIV, A11Y, PERF, REL, OBS, COMPAT, STORE
**Goal:** Turn the applicable local-only P0 product into a compliant public iPhone release with no backend operating bill.

## Entry criteria

- Product owner confirms which SRS P0 features enter the release candidate.
- Required local phase exit gates are evidenced; deferred cloud/social phases are not dependencies.
- Final product name/brand ownership process is underway.
- App support, signing, privacy, and release owners are assigned.

## Release workstreams

### Product and design

- Complete onboarding, settings, help, errors, empty/offline/permission states.
- Final original visual system, icon, screenshots, localization-ready strings.
- Minimum/maximum iPhone layouts, light/dark appearance, accessibility.

### Security and privacy

- Local-data threat model and mobile security assessment.
- Privacy impact and AI risk assessment.
- SDK/provider inventory, local retention/deletion, permission, and diagnostic-data verification.
- Signing/entitlement review and proof that no private closet media is transmitted to a developer-operated service.

### Reliability and operations

- Crash and performance evidence available through Apple-provided tooling where practical.
- Local persistence migration/corruption recovery exercise.
- Weather outage/quota, release rollback, and support instructions.
- Explicit audit confirming no mandatory recurring service cost beyond Apple Developer Program membership.

### App Store

- Name/trademark/domain/store availability.
- Privacy Policy, Terms, and support/privacy-choice URLs on no-charge hosting where practical.
- App Privacy disclosures and permission descriptions.
- Local clear-data behavior and disclosure that no account/cloud recovery exists.
- Signing, bundle IDs, entitlements, export compliance, age rating, reviewer access.

### Beta

- Internal TestFlight for engineering/product.
- External TestFlight cohorts with beta review where required.
- Structured feedback and Apple-provided crash/performance review.
- Go/no-go review and rollback plan.

## Test and audit plan

- Full regression on supported devices/OS versions.
- VoiceOver, Dynamic Type, Reduce Motion, contrast, keyboard/switch audit.
- Local stress, memory, and garment-processing capacity.
- Crash-free, launch, generation, and image-processing latency targets.
- Local deletion/privacy and app-container data-flow tests.
- Persistence recovery and weather-provider failure.
- Store reviewer journey from clean install.
- Support and release-rollback drill.

## Release gates

- [ ] All included P0 requirements pass or have accountable formal deviations.
- [ ] No unresolved critical/high security or privacy issue without time-bound acceptance.
- [ ] Crash-free, latency, availability, and capacity targets pass beta.
- [ ] Local clear-data and app-container isolation pass.
- [ ] Accessibility audit has no core-journey blocker.
- [ ] Legal/store disclosures match actual production behavior.
- [ ] Apple-provided release diagnostics, persistence recovery, support, and rollback are operational.
- [ ] No required backend, hosted media, cloud AI, or paid runtime provider is present.
- [ ] Final App Review Guidelines are rechecked at submission time.

## Rollout

Use a staged App Store release where available. Review crashes, launch/generation/image failures, weather fallback behavior, support reports, and Apple allowance usage. Define rollback triggers before rollout begins.
