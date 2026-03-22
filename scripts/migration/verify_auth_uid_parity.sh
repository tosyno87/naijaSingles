#!/usr/bin/env bash
set -euo pipefail

# Quick UID parity check between source and destination Auth projects.
#
# Usage:
#   scripts/migration/verify_auth_uid_parity.sh naijasingles-74a75 afropeep-xxxx

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <source_project_id> <destination_project_id>"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "This script requires jq."
  exit 1
fi

SOURCE_PROJECT_ID="$1"
DEST_PROJECT_ID="$2"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SRC_EXPORT="$TMP_DIR/src_users.json"
DST_EXPORT="$TMP_DIR/dst_users.json"

echo "📦 Exporting source users from $SOURCE_PROJECT_ID ..."
firebase auth:export "$SRC_EXPORT" --project "$SOURCE_PROJECT_ID" --format=json >/dev/null

echo "📦 Exporting destination users from $DEST_PROJECT_ID ..."
firebase auth:export "$DST_EXPORT" --project "$DEST_PROJECT_ID" --format=json >/dev/null

jq -r 'if type=="array" then .[] else .users[] end | .localId' "$SRC_EXPORT" \
  | sort >"$TMP_DIR/src_uids.txt"
jq -r 'if type=="array" then .[] else .users[] end | .localId' "$DST_EXPORT" \
  | sort >"$TMP_DIR/dst_uids.txt"

SRC_COUNT="$(wc -l <"$TMP_DIR/src_uids.txt" | tr -d ' ')"
DST_COUNT="$(wc -l <"$TMP_DIR/dst_uids.txt" | tr -d ' ')"

echo "Source UIDs:      $SRC_COUNT"
echo "Destination UIDs: $DST_COUNT"

comm -23 "$TMP_DIR/src_uids.txt" "$TMP_DIR/dst_uids.txt" >"$TMP_DIR/missing_in_dest.txt"
MISSING_COUNT="$(wc -l <"$TMP_DIR/missing_in_dest.txt" | tr -d ' ')"

if [[ "$MISSING_COUNT" -gt 0 ]]; then
  echo "❌ Missing $MISSING_COUNT source UIDs in destination (first 20):"
  sed -n '1,20p' "$TMP_DIR/missing_in_dest.txt"
  exit 2
fi

echo "✅ UID parity check passed (all source UIDs exist in destination)"
