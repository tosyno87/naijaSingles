#!/usr/bin/env bash
# Pre-release guard: catch competitor brand names and other copy mistakes
# inside Dart string literals only (skips comments, identifiers, and import paths).
#
# Usage:  ./scripts/pre_release_check.sh
# Returns: exit 0 if clean, exit 1 if violations found.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_PY="${ROOT_DIR}/scripts/check_release_copy.py"

echo "=== Pre-release copy check ==="
echo ""

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 is required for ${CHECK_PY}" >&2
  exit 1
fi

if ! python3 "${CHECK_PY}"; then
  echo "=== BLOCKED: Fix the above before releasing ==="
  exit 1
fi

echo ""
exit 0
