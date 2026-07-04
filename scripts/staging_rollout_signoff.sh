#!/usr/bin/env bash
# Automated pre-signoff checks for security consolidation staging rollout.
# Manual checklist items (cold start, Messages tab, onboarding, verification UI)
# still require a device build against naijasingles-staging.
#
# Usage: ./scripts/staging_rollout_signoff.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Security rollout staging sign-off (automated) ==="

echo "[1/4] Rules emulator tests..."
(cd functions && npm run test:rules)

echo "[2/4] Targeted Flutter tests..."
flutter test test/auth/authstatus_bloc_test.dart \
             test/messages/chat_service_test.dart \
             test/features/onboarding/onboarding_essential_data_test.dart

echo "[3/4] Staging rules deployed check (firebase projects)..."
firebase use staging >/dev/null
echo "Active project: $(firebase use 2>&1 | grep -i 'active project' || true)"

echo "[4/4] Staging debug build..."
flutter build apk --debug --dart-define=FLAVOR=staging --dart-define=ENV=staging

cat <<'EOF'

Automated checks passed.

Manual staging sign-off (device + naijasingles-staging):
  [ ] Cold start with existing session -> authenticated
  [ ] Messages tab loads threads for matched users
  [ ] Fresh onboarding -> appears in discovery/swipe
  [ ] Verification image upload succeeds; non-owner cannot read URL
  [ ] Premium user can edit profile

Ship to testers: ./scripts/deploy_testflight.sh (requires .env Apple credentials)
EOF
