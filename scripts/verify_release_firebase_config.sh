#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FIREBASE_OPTIONS_FILE="lib/firebase_options.dart"
STAGING_OPTIONS_FILE="lib/firebase_options_staging.dart"
PRODUCTION_WORKFLOW=".github/workflows/production.yml"

if [[ ! -f "$FIREBASE_OPTIONS_FILE" ]]; then
  echo "::error::Missing $FIREBASE_OPTIONS_FILE"
  exit 1
fi

if [[ ! -f "$STAGING_OPTIONS_FILE" ]]; then
  echo "::error::Missing $STAGING_OPTIONS_FILE"
  exit 1
fi

if [[ ! -f "$PRODUCTION_WORKFLOW" ]]; then
  echo "::error::Missing $PRODUCTION_WORKFLOW"
  exit 1
fi

PROD_PROJECT_ID="$(sed -n "s/^const String productionProjectId = '\\([^']*\\)';$/\\1/p" "$FIREBASE_OPTIONS_FILE" | head -n1)"
if [[ -z "$PROD_PROJECT_ID" ]]; then
  echo "::error::productionProjectId constant not found in $FIREBASE_OPTIONS_FILE"
  exit 1
fi

if ! grep -q "projectId: productionProjectId" "$FIREBASE_OPTIONS_FILE"; then
  echo "::error::Production Firebase options must reference productionProjectId constant"
  exit 1
fi

if grep -q "projectId: '$PROD_PROJECT_ID'" "$STAGING_OPTIONS_FILE"; then
  echo "::error::Staging Firebase options must not use production project id ($PROD_PROJECT_ID)"
  exit 1
fi

IOS_BUILD_LINES="$(grep -n "flutter build ios --release" "$PRODUCTION_WORKFLOW" || true)"
if [[ -z "$IOS_BUILD_LINES" ]]; then
  echo "::error::No iOS release build command found in $PRODUCTION_WORKFLOW"
  exit 1
fi

while IFS= read -r entry; do
  line_number="${entry%%:*}"
  command="${entry#*:}"
  if [[ "$command" != *"--dart-define=ENV=production"* ]]; then
    echo "::error::Line $line_number in $PRODUCTION_WORKFLOW is missing --dart-define=ENV=production"
    exit 1
  fi
done <<< "$IOS_BUILD_LINES"

if grep -q "dart-define=ENV=staging" "$PRODUCTION_WORKFLOW"; then
  echo "::error::Production workflow must not build with ENV=staging"
  exit 1
fi

echo "✅ Release Firebase config guard passed"
echo "   productionProjectId=$PROD_PROJECT_ID"
