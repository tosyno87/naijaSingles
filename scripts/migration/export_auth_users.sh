#!/usr/bin/env bash
set -euo pipefail

# Export Auth users from source project (keeps password hashes + provider data).
#
# Usage:
#   scripts/migration/export_auth_users.sh naijasingles-74a75 ./tmp/auth-export.json

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <source_project_id> <output_json_path>"
  exit 1
fi

SOURCE_PROJECT_ID="$1"
OUTPUT_PATH="$2"

mkdir -p "$(dirname "$OUTPUT_PATH")"

echo "📦 Exporting Auth users from $SOURCE_PROJECT_ID ..."
firebase auth:export "$OUTPUT_PATH" \
  --project "$SOURCE_PROJECT_ID" \
  --format=json

echo "✅ Export complete: $OUTPUT_PATH"
