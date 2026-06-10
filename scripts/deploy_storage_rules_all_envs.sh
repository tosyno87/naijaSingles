#!/usr/bin/env bash
# Deploy storage.rules to staging, legacy prod, and next-production.
# Run from repo root: ./scripts/deploy_storage_rules_all_envs.sh
set -euo pipefail

cd "$(dirname "$0")/.."

for proj in naijasingles-staging naijasingles-74a75 afropeep-prod-74a75; do
  echo "========== Deploying storage rules to $proj =========="
  firebase deploy --only storage --project "$proj" || exit 1
done

echo "All storage rules deploys finished."
