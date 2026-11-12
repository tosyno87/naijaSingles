#!/usr/bin/env bash
# Staging ops for Houston TestFlight beta.
# Usage: ./scripts/testflight_houston_staging_ops.sh [project-id]
#
# Does NOT set OPENAI_API_KEY or App Check (interactive / Console).
# Does NOT cut TestFlight — run scripts/deploy_testflight.sh after merge.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${1:-naijasingles-staging}"

echo "==> Houston TestFlight staging ops"
echo "    project: $PROJECT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found" >&2
  exit 1
fi

echo "==> Deploy functions (includes extractOnboardingProfile)"
firebase deploy --only functions --project "$PROJECT"

echo "==> Seed Houston weekend events"
(
  cd functions
  npx ts-node src/scripts/seedHoustonReviewEvents.ts --project "$PROJECT"
)

echo "==> Seed Houston public groups"
(
  cd functions
  npx ts-node src/scripts/seedHoustonReviewGroups.ts --project "$PROJECT"
)

echo "==> Done."
echo "Manual follow-ups (if not already set):"
echo "  firebase functions:secrets:set OPENAI_API_KEY --project $PROJECT"
echo "  Set ONBOARDING_AI_REVIEW_UIDS for App Review demo accounts"
echo "  Confirm App Check + TestFlight attestation in Firebase Console"
echo "  See docs/guides/TESTFLIGHT_HOUSTON_OPS_CHECKLIST.md"
