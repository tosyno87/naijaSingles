#!/usr/bin/env bash
set -euo pipefail

# Import Auth users into destination project (UIDs preserved from export).
#
# Usage:
#   scripts/migration/import_auth_users.sh afropeep-xxxx ./tmp/auth-export.json

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <destination_project_id> <input_json_path>"
  exit 1
fi

DEST_PROJECT_ID="$1"
INPUT_PATH="$2"

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Input file not found: $INPUT_PATH"
  exit 1
fi

echo "📥 Importing Auth users into $DEST_PROJECT_ID ..."
firebase auth:import "$INPUT_PATH" \
  --project "$DEST_PROJECT_ID"

echo "✅ Import complete"
