#!/usr/bin/env bash
# Deploy storage.rules then firestore.rules to production Firebase projects only.
# Staging should already be deployed before running this script.
#
# Usage: ./scripts/deploy_prod_rules.sh
set -euo pipefail

cd "$(dirname "$0")/.."

PROD_PROJECTS=(naijasingles-74a75 afropeep-prod-74a75)

echo "================================================"
echo "  PRODUCTION rules deploy"
echo "  Projects: ${PROD_PROJECTS[*]}"
echo "================================================"
read -p "Type 'yes' to deploy Storage + Firestore rules to production: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

for proj in "${PROD_PROJECTS[@]}"; do
  echo "========== Deploying storage rules to $proj =========="
  firebase deploy --only storage --project "$proj"
done

for proj in "${PROD_PROJECTS[@]}"; do
  echo "========== Deploying firestore:rules to $proj =========="
  firebase deploy --only firestore:rules --project "$proj"
done

echo "Production rules deploy finished."
