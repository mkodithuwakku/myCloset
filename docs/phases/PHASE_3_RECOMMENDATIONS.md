# Phase 3 — Recommendation Quality and Personalization

**Status:** Planned
**Primary SRS groups:** WEA, HOME, GEN, COMP, REC, FB, PERF, OBS
**Goal:** Make recommendations consistently useful, explainable, reproducible, and resilient.

## Entry criteria

- Phase 1 wardrobe metadata quality and the local persistence model are stable.
- Phase 1 wardrobe metadata quality is measurable.
- Product approves recommendation quality metrics and feedback taxonomy.
- Weather behavior passes the zero-recurring-cost review; optional ranking remains on-device.

## User outcomes

- Reliable daily recommendation using fresh context when available.
- Occasion preset, formality, weather mode, and optional free-text detail.
- Multiple locks with clear conflict resolution.
- Manual replacement, one-piece reroll, unlocked reroll, and undo.
- Explanations showing weather/season, occasion, formality, lock, and color factors.
- Private quick feedback and controls to remove learned preferences.
- Useful fallback when weather/model providers fail.

## Engine architecture

The current prototype follows [ADR-0005](../decisions/0005-garment-types-and-jacket-composition.md): separates contain a top or outerwear with a bottom. A jacket replaces the top, while a one-piece may still have outerwear. Locked upper-body choices and replacements retain this invariant. This delivered correction does not complete Phase 3's versioning or personalization gates.

1. Version and validate request inputs.
2. Apply authorization/ownership and item lifecycle constraints.
3. Construct valid outfit candidates.
4. Apply weather-safety and trip constraints.
5. Score formality, occasion, season, weather comfort, colors, favorites, recency, variety, and feedback.
6. Optionally use reviewed on-device model ranking/explanation assistance.
7. Revalidate the selected outfit deterministically.
8. Store reason codes, rule/model version, and privacy-safe trace ID.

## Weather resilience

- Provider adapter, cache, freshness, attribution, and quotas.
- Apparent temperature, precipitation, wind, and severe-condition rules.
- Current location → city → cached → season → neutral fallback.
- Destination/date context used later by trips.
- User comfort preferences without sensitive health inference.

## Feedback and evaluation

- Accept/reject/save/worn/reroll/unavailable events.
- Quick reason taxonomy from SRS.
- User-editable preference signals.
- Local feedback persistence with migration coverage.
- Offline evaluation corpus with expected invariants/relevance judgments.
- Controlled beta experiment design without manipulative ranking.

## Test plan

- 100% hard-constraint branch coverage.
- Property/combinatorial tests across categories, locks, seasons, weather, and availability.
- Replay test for every rule/model version.
- Provider timeout/malformed/quota fallback.
- Free-text interpretation contract and abuse limits.
- Explanation truthfulness against applied reason codes.
- Feedback weighting and preference deletion.
- Latency/load targets and cost budgets.
- Bias/inclusion review for taxonomy and evaluation set.

## Exit criteria

- [ ] Ownership, locks, availability, structure, and safety invariants never fail evaluation tests.
- [ ] Rules/models are versioned, replayable, monitored, and rollback-capable.
- [ ] Provider outages degrade to a usable deterministic result when possible.
- [ ] Users can inspect/remove preference signals.
- [ ] Approved beta acceptance and latency targets are met.
- [ ] Explanations describe applied facts without unsupported certainty.
- [ ] Recommendation telemetry excludes private raw content by default.
