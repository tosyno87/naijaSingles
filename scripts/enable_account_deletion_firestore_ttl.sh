#!/usr/bin/env bash
# Enable Firestore TTL for account-deletion–related collection groups (gcloud).
# Requires: gcloud auth login, datastore.indexAdmin or roles/datastore.indexAdmin (or Owner).
#
# Usage:
#   export GCP_PROJECT_ID=your-firebase-project-id
#   ./scripts/enable_account_deletion_firestore_ttl.sh
#
# Optional: non-default database (Native mode):
#   FIRESTORE_DATABASE='(default)'   # default
#
# Docs: https://cloud.google.com/sdk/gcloud/reference/firestore/fields/ttls/update
#       https://firebase.google.com/docs/firestore/ttl

set -euo pipefail

: "${GCP_PROJECT_ID:?Set GCP_PROJECT_ID to your Firebase / GCP project ID}"
DATABASE="${FIRESTORE_DATABASE:-(default)}"

run_ttl_enable() {
  local field="$1"
  local group="$2"
  echo "Enabling TTL: collection group '${group}', field '${field}'..."
  gcloud firestore fields ttls update "${field}" \
    --collection-group="${group}" \
    --database="${DATABASE}" \
    --project="${GCP_PROJECT_ID}" \
    --enable-ttl
}

echo "Project: ${GCP_PROJECT_ID}, database: ${DATABASE}"
echo "This can take 10+ minutes per policy to become active."
echo ""

run_ttl_enable expireAt accountDeletionAbuse
run_ttl_enable expiresAt accountDeletionVerifications

echo ""
echo "List TTL policies:"
echo "  gcloud firestore fields ttls list --project=${GCP_PROJECT_ID} --database=${DATABASE}"
echo "Track long-running work:"
echo "  gcloud firestore operations list --project=${GCP_PROJECT_ID} --database=${DATABASE}"
