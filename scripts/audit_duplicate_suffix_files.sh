#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
OUTPUT_FILE="${2:-docs/refactoring/DUPLICATE_SUFFIX_FILE_AUDIT.txt}"

cd "$ROOT_DIR"

mkdir -p "$(dirname "$OUTPUT_FILE")"

{
  echo "# Duplicate Suffix File Audit"
  echo
  echo "Generated: $(date -u +"%Y-%m-%d %H:%M:%SZ")"
  echo
  echo "## Scope"
  echo "- Files ending with numeric suffix before extension, e.g. \`name 2.dart\`"
  echo
  echo "## Candidate Files"
  echo
  echo '```'
  git ls-files -co --exclude-standard | awk '/ [0-9]+\.[^\/]+$/ { print }' || true
  echo '```'
  echo
  echo "## Count by Extension"
  echo
  echo '```'
  git ls-files -co --exclude-standard |
    awk '/ [0-9]+\.[^\/]+$/ { print }' |
    awk -F. 'NF > 1 { print $NF }' |
    sort |
    uniq -c |
    sort -nr || true
  echo '```'
  echo
  echo "## Next Steps"
  echo "- Validate each candidate is not imported/referenced."
  echo "- Remove in small batches by feature area."
  echo "- Run analyze/tests after each batch."
} > "$OUTPUT_FILE"

echo "Audit written to $OUTPUT_FILE"
