#!/usr/bin/env bash
set -euo pipefail

# Cutover preflight checker for migration release builds.
#
# Usage:
#   scripts/migration/cutover_preflight_check.sh
# Optional env:
#   EXPECTED_NEXT_PROD_PROJECT_ID=afropeep-xxxx
#   AUTH_MIGRATION_CUTOVER_EPOCH=2026032201

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "🔎 Running migration preflight checks..."

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != codex/afropeep-firebase-migration ]]; then
  echo "⚠️ Current branch is '$CURRENT_BRANCH' (expected codex/afropeep-firebase-migration)"
fi

if [[ -z "${AUTH_MIGRATION_CUTOVER_EPOCH:-}" ]]; then
  echo "⚠️ AUTH_MIGRATION_CUTOVER_EPOCH not set (forced re-login cutover not armed yet)."
else
  echo "✅ AUTH_MIGRATION_CUTOVER_EPOCH set to $AUTH_MIGRATION_CUTOVER_EPOCH"
fi

if [[ -n "${EXPECTED_NEXT_PROD_PROJECT_ID:-}" ]]; then
  if ! rg -n "NEXT_PROD_PROJECT_ID" lib/firebase_options_next_production.dart >/dev/null; then
    echo "❌ NEXT_PROD_PROJECT_ID wiring missing in lib/firebase_options_next_production.dart"
    exit 1
  fi
  echo "✅ next-production project mapping is define-driven"
fi

if [[ ! -x scripts/verify_release_firebase_config.sh ]]; then
  echo "❌ scripts/verify_release_firebase_config.sh is not executable"
  exit 1
fi

./scripts/verify_release_firebase_config.sh
echo "✅ Migration preflight checks passed"
