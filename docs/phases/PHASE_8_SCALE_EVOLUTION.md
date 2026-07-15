# Phase 8 — Scale and Product Evolution

**Status:** Future
**Primary SRS groups:** SCALE, OBS, P1/P2 scope
**Goal:** Expand only where production evidence shows durable user value.

## Entry criteria

- The public release is stable and measured.
- Any activated CloudKit social feature meets its privacy, safety, reliability, and cost gates.
- Proposed work has user evidence, sustainable cost, and operational ownership.
- No expansion hides unresolved release or safety debt.

## Candidate workstreams

- Localization and region-aware weather or moderation operations.
- iPad and Apple Watch experiences.
- Optional calendar-based outfit planning.
- Wear frequency and cost-per-wear insights.
- Wardrobe-gap insights without pressure or manipulation.
- Advanced on-device preference models.
- Improved packing optimization and optional collaboration.
- CloudKit query, asset, and quota optimization only if measured use requires it.
- A conventional backend only if CloudKit cannot satisfy a demonstrated requirement and a new ADR approves cost and migration.

## Decision framework

Every candidate needs:

1. a measured user problem;
2. a hypothesis and success/failure threshold;
3. a minimum reversible experiment;
4. privacy, bias, safety, and accessibility analysis;
5. compute, storage, moderation, and support cost;
6. rollback and data-deletion plan;
7. an effect on free-app sustainability.

## Advanced intelligence guardrails

- Hard validation remains outside model output.
- Private content is not generalized training data without separate consent.
- Model/provider versions are evaluated, replayable, monitored, and reversible.
- Preferences remain inspectable and removable.
- No sensitive-trait inference or body-value judgments.
- Improvements are measured by usefulness, not addictive engagement.

## Test plan

- Experiment assignment and metric-integrity tests where measurement is permitted.
- Localization layout, semantics, units, season, and moderation coverage.
- Performance and cost regression benchmarks.
- Model evaluation, drift, rollback, and privacy tests.
- Migration tests for new persistence or service boundaries.
- Capacity and failure-injection tests for newly scaled components.

## Exit criteria for each initiative

- [ ] Success metric and guardrails are met.
- [ ] Privacy, security, and accessibility reviews pass.
- [ ] Costs remain sustainable for a free product.
- [ ] Operations and support can own the feature.
- [ ] Rollback and deletion have been exercised.
- [ ] Documentation and SRS scope are updated.
