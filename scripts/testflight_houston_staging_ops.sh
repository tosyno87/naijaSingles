#!/usr/bin/env bash
# Staging ops for Houston TestFlight beta.
# Usage: ./scripts/testflight_houston_staging_ops.sh [project-id]
#
# Active Houston TestFlight Firebase project is naijasingles-74a75 (same id the
# iOS GoogleService-Info.plist and ENV=production dart options use). The empty
# naijasingles-staging alias is NOT the default — pass it explicitly only if
# you intentionally target that project.
#
# Does NOT set OPENAI_API_KEY or App Check (interactive / Console).
# Does NOT cut TestFlight — run scripts/deploy_testflight.sh after merge.
# Seed scripts refuse production project ids unless --i-am-sure is passed;
# this wrapper adds that flag automatically for known production ids.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${1:-naijasingles-74a75}"

# Keep in sync with functions/src/scripts/seedHoustonReviewEvents.ts
PRODUCTION_PROJECT_IDS=(
  naijasingles-74a75
  naijasingles-prod2
  afropeep-prod-74a75
)

is_production_project() {
  local candidate="$1"
  local id
  for id in "${PRODUCTION_PROJECT_IDS[@]}"; do
    if [[ "$id" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

SEED_EXTRA_ARGS=()
if is_production_project "$PROJECT"; then
  SEED_EXTRA_ARGS+=(--i-am-sure)
  echo "NOTE: project $PROJECT is treated as production for seeds; passing --i-am-sure"
fi

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
  npx ts-node src/scripts/seedHoustonReviewEvents.ts --project "$PROJECT" "${SEED_EXTRA_ARGS[@]}"
)

echo "==> Seed Houston public groups"
(
  cd functions
  npx ts-node src/scripts/seedHoustonReviewGroups.ts --project "$PROJECT" "${SEED_EXTRA_ARGS[@]}"
)

echo "==> Done."
echo "Manual follow-ups (if not already set):"
echo "  firebase functions:secrets:set OPENAI_API_KEY --project $PROJECT"
echo "  Set ONBOARDING_AI_REVIEW_UIDS for App Review demo accounts"
echo "  Confirm App Check + TestFlight attestation in Firebase Console"
echo "  See docs/guides/TESTFLIGHT_HOUSTON_OPS_CHECKLIST.md"
echo "  Cut IPA with: ./scripts/deploy_testflight.sh --build-only"
echo "  After device launch OK: ./scripts/deploy_testflight.sh --upload-only PATH.ipa"
echo "  (or Xcode Organizer on the same archive — do not full-redeploy)"
