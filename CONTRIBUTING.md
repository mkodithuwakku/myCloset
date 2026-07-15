# Contributing to myCloset

Thank you for improving myCloset. The repository is in an early product-engineering phase, so changes should preserve the privacy and implementation boundaries defined by the SRS and roadmap.

## Before starting

1. Read [README.md](README.md), [SRS.md](SRS.md), and [docs/ROADMAP.md](docs/ROADMAP.md).
2. Check the applicable phase document under `docs/phases/`.
3. Search existing issues before opening a duplicate.
4. For architecture, privacy, security, or scope changes, open a proposal before implementing.

## Branch and commit workflow

- Branch from the current `main`.
- Use a short descriptive branch name such as `feature/guided-capture` or `fix/locked-reroll`.
- Keep unrelated work in separate branches.
- Write imperative commit subjects, for example `Add garment mask correction`.
- Never commit credentials, signing certificates, provisioning profiles, production user data, or private media.
- Rebase or merge current `main` before final review when the branch has drifted.

## Definition of a reviewable change

A pull request should:

- explain the user or engineering outcome;
- identify affected SRS requirement IDs and roadmap phase;
- include tests for new rules, regressions, and important failure states;
- pass unit and UI suites;
- preserve accessibility labels and Dynamic Type behavior;
- update documentation and the changelog when behavior changes;
- state privacy, security, and data-migration impact;
- avoid expanding product scope implicitly.

## Local validation

Run the full suite described in [docs/TESTING.md](docs/TESTING.md). At minimum:

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetTestDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Also run:

```sh
./scripts/verify_docs.sh
```

## Code conventions

- Keep business and recommendation rules out of SwiftUI view bodies.
- Prefer small value types and explicit dependencies.
- Treat `ClosetStore` as the current local application boundary, not a future backend design.
- Keep hard recommendation constraints separate from soft scoring.
- Make asynchronous state transitions observable and recoverable.
- Use server-enforceable identifiers and ownership concepts in future networking work.
- Use plain, inclusive language; do not infer gender, body type, health, ethnicity, religion, or socioeconomic status.

## Testing expectations

- A bug fix requires a failing regression test whenever the behavior is testable.
- Recommendation changes require tests for locked items, unavailable items, structure, and no-match explanations.
- Persistence changes require round-trip and migration tests.
- User-facing flows require UI coverage for at least the primary success path and important denial/error states.
- Network adapters require deterministic fakes; unit tests must not depend on live provider availability.
- Privacy/authorization boundaries require multi-user integration tests once the backend exists.

## Documentation expectations

The README is continuously maintained. Update it in the same pull request when current capabilities, commands, suite counts, phase status, or architecture change. Follow the maintenance table in [docs/README.md](docs/README.md).

## Pull-request review

At least one project owner should review changes to product behavior. Security-, privacy-, authentication-, moderation-, storage-, or migration-sensitive work should receive an explicit domain review before merge.

## Reporting vulnerabilities

Do not open public issues for suspected vulnerabilities or private-data exposure. Follow [SECURITY.md](SECURITY.md).
