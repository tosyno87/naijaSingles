#!/usr/bin/env bash
set -euo pipefail

# Build the app against the migrated Firebase project (next-production env).
#
# Usage:
#   AUTH_MIGRATION_CUTOVER_EPOCH=202603221530 \
#   scripts/migration/build_next_production_ios_simulator.sh

if [[ -z "${AUTH_MIGRATION_CUTOVER_EPOCH:-}" ]]; then
  echo "Usage: AUTH_MIGRATION_CUTOVER_EPOCH=<integer> $0"
  exit 1
fi

flutter build ios --simulator --debug \
  --dart-define=ENV=next-production \
  --dart-define=NEXT_PROD_PROJECT_ID=afropeep-prod-74a75 \
  --dart-define=NEXT_PROD_STORAGE_BUCKET=afropeep-prod-74a75.firebasestorage.app \
  --dart-define=NEXT_PROD_MESSAGING_SENDER_ID=719055332974 \
  --dart-define=NEXT_PROD_AUTH_DOMAIN=afropeep-prod-74a75.firebaseapp.com \
  --dart-define=NEXT_PROD_WEB_API_KEY=AIzaSyBWxc1anmtWrHSyi0JKTLaqjEB9mnLRS_M \
  --dart-define=NEXT_PROD_WEB_APP_ID=1:719055332974:web:a49ca0a3d65c2e04c1a87f \
  --dart-define=NEXT_PROD_ANDROID_API_KEY=AIzaSyAJHab2uIqD_t33NVRS7DZSPWlmyMDiBB4 \
  --dart-define=NEXT_PROD_ANDROID_APP_ID=1:719055332974:android:7e1e6c0867db5a92c1a87f \
  --dart-define=NEXT_PROD_IOS_API_KEY=AIzaSyCyiz41z9IzuFS_L0pMY7g9Q1SosNquYwA \
  --dart-define=NEXT_PROD_IOS_APP_ID=1:719055332974:ios:122dfd9293342ac2c1a87f \
  --dart-define=NEXT_PROD_IOS_CLIENT_ID=719055332974-hj18hef39f5tl1i6poil4aadtiivuilh.apps.googleusercontent.com \
  --dart-define=NEXT_PROD_IOS_BUNDLE_ID=com.app.naijasingles \
  --dart-define=FORCE_RELOGIN_AFTER_MIGRATION=true \
  --dart-define=AUTH_MIGRATION_CUTOVER_EPOCH="${AUTH_MIGRATION_CUTOVER_EPOCH}"

echo "✅ next-production iOS simulator build succeeded"
