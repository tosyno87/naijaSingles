#!/usr/bin/env bash
# Deploy firestore.rules to staging, legacy prod, and next-production.
# Run from repo root: ./scripts/deploy_firestore_rules_all_envs.sh
set -euo pipefail

cd "$(dirname "$0")/.."

for proj in naijasingles-staging naijasingles-74a75 afropeep-prod-74a75; do
  echo "========== Deploying firestore:rules to $proj =========="
  firebase deploy --only firestore:rules --project "$proj" || exit 1
done

echo "All firestore:rules deploys finished."
