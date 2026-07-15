# Documentation index

This directory is the maintained engineering and delivery knowledge base for myCloset. `SRS.md` remains the product requirements baseline; these documents explain how the team intends to deliver and verify it.

## Core documents

| Document | Owner | Update trigger |
|---|---|---|
| [Codex Repository Context](../AGENTS.md) | Engineering lead | Durable project context, commands, boundaries, or agent handoff expectations change |
| [Architecture](ARCHITECTURE.md) | Engineering lead | Component, dependency, storage, data-flow, or security-boundary change |
| [Development](DEVELOPMENT.md) | Engineering lead | Toolchain, setup, build, debugging, or coding-convention change |
| [Roadmap](ROADMAP.md) | Product owner | Phase scope, order, status, entry/exit gate, or release-target change |
| [Testing](TESTING.md) | QA/engineering | Suite, command, CI, coverage target, test fixture, or quality-gate change |
| [Latest Test Execution](testing/TEST_EXECUTION_2026-07-14.md) | QA/engineering | A release or phase gate is executed |
| [Requirements Traceability](REQUIREMENTS_TRACEABILITY.md) | Product + QA | Requirement, phase assignment, implementation, or verification change |
| [Prototype Status](../PROTOTYPE_STATUS.md) | Engineering lead | Any change to what the current binary actually supports |
| [SRS](../SRS.md) | Product owner | Approved product requirement or business-rule change |
| [Changelog](../CHANGELOG.md) | Change author | User-visible or maintainer-significant change |

## Phase documents

| Phase | Document | Status |
|---:|---|---|
| 0 | [Local Prototype and Foundation](phases/PHASE_0_LOCAL_PROTOTYPE.md) | Complete |
| 1 | [Capture and Wardrobe Quality](phases/PHASE_1_CAPTURE_WARDROBE.md) | Next |
| 2 | [Cloud Identity and Private Data](phases/PHASE_2_CLOUD_IDENTITY.md) | Planned |
| 3 | [Recommendation Quality](phases/PHASE_3_RECOMMENDATIONS.md) | Planned |
| 4 | [Social and Safety](phases/PHASE_4_SOCIAL_SAFETY.md) | Planned |
| 5 | [Trips and Offline](phases/PHASE_5_TRIPS_OFFLINE.md) | Planned |
| 6 | [Beta and App Store Release](phases/PHASE_6_BETA_RELEASE.md) | Planned |
| 7 | [Scale and Product Evolution](phases/PHASE_7_SCALE_EVOLUTION.md) | Future |

## Architecture decisions

| ADR | Decision |
|---|---|
| [ADR-0001](decisions/0001-local-first-prototype.md) | Start with a local-first functional prototype |
| [ADR-0002](decisions/0002-hybrid-recommendation-engine.md) | Keep deterministic constraints around any intelligent ranking |

## Documentation quality rules

1. Describe current behavior in the present tense and future behavior as planned.
2. Never mark a phase complete until its exit criteria have evidence.
3. Link requirements using their stable SRS IDs.
4. Keep commands executable; do not use pseudocode where the reader expects a runnable command.
5. Record material tradeoffs in an ADR rather than hiding them in a pull-request thread.
6. Remove stale claims instead of accumulating contradictory notes.
7. Update the README whenever a new user or contributor would otherwise form the wrong mental model.

Run `./scripts/verify_docs.sh` to check the required documentation structure.
