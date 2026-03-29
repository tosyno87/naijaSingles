#!/usr/bin/env bash
# Set ACCOUNT_DELETION_ENFORCE_APPCHECK on account-deletion callables (Firebase v2 → Cloud Run).
#
# Usage:
#   ./scripts/set_account_deletion_appcheck_env.sh [PROJECT_ID] [false|true]
#
# Examples:
#   ./scripts/set_account_deletion_appcheck_env.sh naijasingles-74a75 false
#   ./scripts/set_account_deletion_appcheck_env.sh naijasingles-staging false
#   ./scripts/set_account_deletion_appcheck_env.sh naijasingles-74a75 true   # prod: enforce again
#
# Requires: gcloud auth, roles that can update Cloud Run (e.g. Cloud Run Admin).
set -euo pipefail

PROJECT="${1:-naijasingles-74a75}"
MODE="${2:-false}"
REGION="${REGION:-us-central1}"

case "$MODE" in
  true|false) VAL="$MODE" ;;
  *)
    echo "Second arg must be true or false (got: $MODE)" >&2
    exit 2
    ;;
esac

# Must match lowercase Cloud Run service names for these callables.
SERVICES=(
  deleteaccountdirect
  startdeletionotp
  confirmdeletionotp
  confirmdeletionafterphoneproof
)

gcloud config set project "$PROJECT" >/dev/null

for svc in "${SERVICES[@]}"; do
  if ! gcloud run services describe "$svc" --region="$REGION" >/dev/null 2>&1; then
    echo "Skip (not found): $svc"
    continue
  fi
  echo "Updating $svc → ACCOUNT_DELETION_ENFORCE_APPCHECK=$VAL"
  gcloud run services update "$svc" --region="$REGION" \
    --update-env-vars "ACCOUNT_DELETION_ENFORCE_APPCHECK=$VAL"
done

echo "Done. Cold starts should log account_deletion_callable_config with enforceAppCheck: $VAL"
