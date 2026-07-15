# Phase 7 — Scale and Product Evolution

**Status:** Future
**Primary SRS groups:** SCALE, OBS, P1/P2 scope
**Goal:** Expand only where production evidence shows durable user value.

## Entry criteria

- Public release is stable and measured.
- Core privacy/safety/reliability SLOs are consistently met.
- Proposed work has user evidence, sustainable cost, and operational ownership.
- No expansion hides unresolved P0 reliability or safety debt.

## Candidate workstreams

- Localization and region-aware weather/moderation operations.
- iPad and Apple Watch experiences.
- Optional calendar-based outfit planning.
- Wear frequency and cost-per-wear insights.
- Wardrobe-gap insights without pressure/manipulation.
- Advanced on-device preference models.
- Improved packing optimization and optional collaboration.
- Provider/cost optimization and regional infrastructure.
- Search/feed scale only if actual usage requires it.

## Decision framework

Every candidate needs:

1. measured user problem;
2. hypothesis and success/failure threshold;
3. minimum reversible experiment;
4. privacy, bias, safety, and accessibility analysis;
5. compute/storage/moderation/support cost;
6. rollback and data-deletion plan;
7. effect on free-app sustainability.

## Scale engineering

- Profile query/index hot paths before sharding.
- Horizontal stateless API/media workers.
- Queue backpressure and tenant fairness.
- CDN/object lifecycle and derivative invalidation.
- Recommendation cache/version invalidation.
- Regional data/processor obligations.
- Load models based on measured traffic with at least approved headroom.

## Advanced intelligence guardrails

- Hard validation remains outside model output.
- Private content is not generalized training data without separate consent.
- Model/provider versions are evaluated, replayable, monitored, and reversible.
- Preferences remain inspectable/removable.
- No sensitive trait inference or body-value judgments.
- Improvements are measured by usefulness, not addictive engagement.

## Test plan

- Experiment assignment and metric-integrity tests.
- Localization layout, semantics, units, season, and moderation coverage.
- Performance/cost regression benchmarks.
- Model evaluation, drift, rollback, and privacy tests.
- Migration tests for any new aggregate/analytics data.
- Capacity/failure-injection for newly scaled components.

## Exit criteria for each initiative

- [ ] Success metric and guardrails are met.
- [ ] Privacy/security/accessibility reviews pass.
- [ ] Costs remain sustainable for a free product.
- [ ] Operations and support can own the feature.
- [ ] Rollback/deletion have been exercised.
- [ ] Documentation and SRS scope are updated.
