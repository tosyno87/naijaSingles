#!/usr/bin/env bash
# Verify the built iOS app has a resolved (non-empty) GMSApiKey.
# Usage: scripts/verify_ios_gms_api_key.sh [path/to/Runner.app]
set -euo pipefail

APP="${1:-}"
if [[ -z "$APP" ]]; then
  APP="$(find build/ios -name 'Runner.app' -type d 2>/dev/null | head -1 || true)"
fi

if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "❌ Runner.app not found (pass path or build iOS first)"
  exit 1
fi

PLIST="$APP/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "❌ Info.plist missing at $PLIST"
  exit 1
fi

KEY="$(/usr/libexec/PlistBuddy -c 'Print :GMSApiKey' "$PLIST" 2>/dev/null || true)"
if [[ -z "$KEY" ]]; then
  echo "❌ GMSApiKey is empty in $PLIST — Maps will hard-crash on GoogleMap"
  exit 1
fi
if [[ "$KEY" == \$\(* ]]; then
  echo "❌ GMSApiKey was not substituted (still '$KEY') — Secrets.xcconfig missing in CI"
  exit 1
fi

echo "✅ GMSApiKey present in $(basename "$APP") (len=${#KEY})"
