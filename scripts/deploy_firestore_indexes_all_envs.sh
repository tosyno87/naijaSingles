#!/usr/bin/env bash
# Deploy firestore.indexes.json to every unique Firebase project in .firebaserc.
#
# Aliases cover: dev (feature/CI), staging, legacy prod (74a75), prod2 (some
# docs/CI), and next-production (Afropeep cutover). Remove any alias from
# .firebaserc if that project does not exist in your Firebase org.
#
# Usage (from repo root):
#   ./scripts/deploy_firestore_indexes_all_envs.sh
#
# Optional: comma-separated extra project IDs (not in .firebaserc):
#   EXTRA_FIREBASE_PROJECTS=afropeep-dev,afropeep-staging ./scripts/deploy_firestore_indexes_all_envs.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install: npm i -g firebase-tools" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to parse .firebaserc" >&2
  exit 1
fi

PROJECTS_OUT="$(node -e "
const fs = require('fs');
const j = JSON.parse(fs.readFileSync('.firebaserc', 'utf8'));
const fromRc = Object.values(j.projects || {});
const extra = (process.env.EXTRA_FIREBASE_PROJECTS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const all = [...fromRc, ...extra];
console.log([...new Set(all)].sort().join('\\n'));
")"

PROJECTS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && PROJECTS+=("$line")
done <<< "$PROJECTS_OUT"

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "No projects found in .firebaserc" >&2
  exit 1
fi

echo "Deploying firestore:indexes to ${#PROJECTS[@]} project(s):"
printf '  - %s\n' "${PROJECTS[@]}"
echo

for project in "${PROJECTS[@]}"; do
  echo ">>> firebase deploy --only firestore:indexes --project $project"
  firebase deploy --only firestore:indexes --project "$project" --non-interactive
  echo
done

echo "Done."
