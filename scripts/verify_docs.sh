#!/usr/bin/env bash

set -euo pipefail

required_files=(
  "AGENTS.md"
  "README.md"
  "SRS.md"
  "PROTOTYPE_STATUS.md"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "docs/README.md"
  "docs/ARCHITECTURE.md"
  "docs/DEVELOPMENT.md"
  "docs/ROADMAP.md"
  "docs/TESTING.md"
  "docs/REQUIREMENTS_TRACEABILITY.md"
  "docs/phases/PHASE_0_LOCAL_PROTOTYPE.md"
  "docs/phases/PHASE_1_CAPTURE_WARDROBE.md"
  "docs/phases/PHASE_2_CLOUD_IDENTITY.md"
  "docs/phases/PHASE_3_RECOMMENDATIONS.md"
  "docs/phases/PHASE_4_SOCIAL_SAFETY.md"
  "docs/phases/PHASE_5_TRIPS_OFFLINE.md"
  "docs/phases/PHASE_6_BETA_RELEASE.md"
  "docs/phases/PHASE_7_CLOUDKIT_SOCIAL.md"
  "docs/phases/PHASE_8_SCALE_EVOLUTION.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "Missing or empty required documentation: $file"
    exit 1
  fi
done

phase_count="$(find docs/phases -maxdepth 1 -name 'PHASE_*.md' | wc -l | tr -d ' ')"
if [[ "$phase_count" != "9" ]]; then
  echo "Expected 9 phase documents; found $phase_count"
  exit 1
fi

if ! grep -q 'Phase 0 local functional prototype is complete' README.md; then
  echo "README current-phase statement is missing or stale."
  exit 1
fi

if ! grep -q '56 unit tests and 5' README.md || ! grep -q '56 unit tests + 5 UI tests' docs/TESTING.md; then
  echo "Documented automated test inventory is missing or stale."
  exit 1
fi

if ! grep -q 'Phase 0 complete; Phase 1 next' docs/ROADMAP.md; then
  echo "Roadmap current-phase statement is missing or stale."
  exit 1
fi

ruby scripts/check_local_links.rb

echo "Documentation structure and status checks passed."
