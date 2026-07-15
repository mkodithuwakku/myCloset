# ADR-0002: Keep deterministic constraints around intelligent ranking

**Status:** Accepted
**Date:** 2026-07-14

## Context

Outfit recommendation benefits from personalization and potentially cloud/on-device models, but product validity depends on enforceable rules: the item belongs to the user, is available, fills a valid slot, respects locks, and does not violate explicit safety/context constraints.

## Decision

Use a hybrid pipeline. Deterministic code constructs and validates candidates. Soft scoring or an optional reviewed model may rank valid candidates and help explain them. Model output is revalidated and cannot bypass hard constraints.

## Consequences

### Positive

- Locks/ownership/availability remain testable invariants.
- Core generation degrades when model providers fail.
- Explanations can refer to explicit reason codes.
- Rule/model changes can be versioned and replayed.

### Negative

- More orchestration than a single model prompt.
- Rule taxonomy and conflicts require ongoing ownership.
- Candidate generation quality can limit ranking quality.

## Guardrails

- Never fabricate closet items.
- Never send private content to a third-party AI without reviewed disclosure/permission.
- Store rule/model versions and reason codes.
- Provide deterministic fallback and rollback.
- Do not infer protected/sensitive traits.
