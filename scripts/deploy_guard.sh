#!/usr/bin/env bash
set -euo pipefail

ACTIVE=$(firebase use 2>&1 | grep -i "active project:" || echo "unknown")

if [[ "$ACTIVE" == *"production"* || "$ACTIVE" == *"naijasingles-74a75"* ]]; then
  echo "================================================"
  echo "  WARNING: You are deploying to PRODUCTION"
  echo "  Project: naijasingles-74a75"
  echo "================================================"
  read -p "Are you sure? Type 'yes' to continue: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

firebase deploy "$@"
