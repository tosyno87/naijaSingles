#!/usr/bin/env bash
set -euo pipefail

# Fails when newly changed files include numeric suffix copies such as:
#   foo 2.dart, config 3.yml, notes 4.md
# This checks only changed files in the current diff range to avoid blocking
# existing legacy files outside the current change set.

BASE_SHA="${1:-}"
HEAD_SHA="${2:-HEAD}"

if [[ -z "${BASE_SHA}" ]]; then
  echo "Usage: $0 <base_sha> [head_sha]"
  exit 2
fi

echo "Checking changed files for duplicate suffix patterns..."
echo "Diff range: ${BASE_SHA}..${HEAD_SHA}"

changed_files="$(git diff --name-only "${BASE_SHA}" "${HEAD_SHA}" || true)"
if [[ -z "${changed_files}" ]]; then
  echo "No changed files in range."
  exit 0
fi

violations="$(printf '%s\n' "${changed_files}" | awk '/ [0-9]+\.[^\/]+$/ { print }')"

if [[ -n "${violations}" ]]; then
  echo "❌ Duplicate-suffix filenames detected in changed files:"
  printf '%s\n' "${violations}"
  echo
  echo "Rename files to canonical names without numeric suffixes."
  exit 1
fi

echo "✅ No duplicate-suffix filenames found in changed files."
