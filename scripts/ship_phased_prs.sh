#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT="${1:-eae49d98}"
BASE="${2:-origin/develop}"

phase1_router() {
  git show "${SNAPSHOT}:lib/common/routes/router.dart" > lib/common/routes/router.dart
  python3 - <<'PY'
from pathlib import Path
p = Path("lib/common/routes/router.dart")
text = p.read_text()
drops = [
    "import '../../features/profile/public_profile_screen.dart';\n",
    "import '../../services/deep_link_service.dart';\n",
]
for d in drops:
    text = text.replace(d, "")
start = text.find("    RouteName.publicProfile:")
if start != -1:
    end = text.find("    },\n  };", start)
    if end != -1:
        text = text[:start] + text[end + len("    },\n") :]
marker = "    // Profile deep link:"
idx = text.find(marker)
if idx != -1:
    end = text.find("    // Handle Firebase Authentication", idx)
    if end != -1:
        text = text[:idx] + text[end:]
p.write_text(text)
PY
}

phase1_route_name() {
  git show "${SNAPSHOT}:lib/common/routes/route_name.dart" > lib/common/routes/route_name.dart
  sed -i '' '/publicProfile/d' lib/common/routes/route_name.dart
}

phase2_main() {
  git show "${BASE}:lib/main.dart" > lib/main.dart
  python3 - <<'PY'
from pathlib import Path
p = Path("lib/main.dart")
text = p.read_text()
needle = "        Locale('en', 'US'),\n"
insert = (
    "        Locale('en', 'US'),\n"
    "        Locale('yo', 'NG'),\n"
    "        Locale('ig', 'NG'),\n"
    "        Locale('ha', 'NG'),\n"
)
if "Locale('yo', 'NG')" not in text:
    text = text.replace(needle, insert, 1)
p.write_text(text)
PY
}

commit_phase() {
  local branch="$1"
  local msg="$2"
  git checkout -B "$branch"
  git add -A
  if git diff --cached --quiet; then
    echo "No changes for ${branch}"
    exit 1
  fi
  git commit -m "$msg"
  git push -u origin "$branch" --force-with-lease
}

echo "Using snapshot ${SNAPSHOT} and base ${BASE}"

# --- Phase 1 ---
git checkout "${BASE}" -f
git checkout -B feature/pe-phase-1-connect
git checkout "${SNAPSHOT}" -- \
  lib/features/explore/screens/tribe_connect_screen.dart \
  lib/features/likes_received \
  lib/features/community_groups/ui/screens/community_groups_screen.dart \
  test/features/likes_received \
  test/services/undo_service_test.dart
phase1_route_name
phase1_router
commit_phase "feature/pe-phase-1-connect" "$(cat <<'EOF'
feat(connect): surface undo and Likes You on Connect

Wire UndoService snackbar on pass, add Likes Received screen with premium
gating, and remove stale community groups placeholder CTA.
EOF
)"

# --- Phase 2 ---
git checkout feature/pe-phase-1-connect -f
git checkout -B feature/pe-phase-2-monetization
git checkout "${SNAPSHOT}" -- \
  lib/services/profile_boost_service.dart \
  lib/services/profile_boost_purchase_service.dart \
  lib/features/profile/widgets/profile_boost_banner.dart \
  lib/features/profile/profile_screen.dart \
  lib/common/data/repo/discovery_boost_sort.dart \
  lib/common/data/repo/user_search_repo.dart \
  asset/translation/yo-NG.json \
  asset/translation/ig-NG.json \
  asset/translation/ha-NG.json \
  lib/features/settings/language_settings_screen.dart \
  test/common/data/repo/discovery_boost_sort_test.dart \
  test/services/profile_boost_service_test.dart
phase2_main
commit_phase "feature/pe-phase-2-monetization" "$(cat <<'EOF'
feat(monetization): profile boost IAP and Nigerian locales

Add boost banner with consumable IAP, discovery boost sorting, and
yo/ig/ha translation bundles with runtime locale switching.
EOF
)"

# --- Phase 3 ---
git checkout feature/pe-phase-2-monetization -f
git checkout -B feature/pe-phase-3-chat
git checkout "${SNAPSHOT}" -- \
  lib/features/chat_shared \
  lib/features/messages \
  lib/services/media_sharing_service.dart \
  test/features/messages/chat_reply_payload_test.dart
commit_phase "feature/pe-phase-3-chat" "$(cat <<'EOF'
feat(chat): images, typing, replies, search, and safety sheet

Extend chat thread with media sharing, typing indicators, in-thread search,
message replies/reactions, and pre-meet safety guidance.
EOF
)"

# --- Phase 4 ---
git checkout feature/pe-phase-3-chat -f
git checkout -B feature/pe-phase-4-communities
git checkout "${SNAPSHOT}" -- \
  lib/features/groups \
  lib/services/group_posts_service.dart \
  lib/services/contact_invitation_service.dart \
  lib/services/profile_sharing_service.dart \
  lib/services/deep_link_service.dart \
  lib/features/profile/public_profile_screen.dart \
  lib/features/onboarding/widgets/profile_preview_screen.dart \
  lib/features/cultural_learning \
  lib/features/explore/widgets/hinge_profile_card.dart \
  lib/common/routes/route_name.dart \
  lib/common/routes/router.dart \
  lib/main.dart \
  pubspec.yaml \
  pubspec.lock \
  macos/Flutter/GeneratedPluginRegistrant.swift
commit_phase "feature/pe-phase-4-communities" "$(cat <<'EOF'
feat(communities): group posts, sharing, deep links, cultural UX

Add group posts on unified group details, contact/profile sharing, profile
deep links via app_links, and cultural learning plus profile prompt polish.
EOF
)"

# --- Phase 5 ---
git checkout feature/pe-phase-4-communities -f
git checkout -B feature/pe-phase-5-firestore
git checkout "${SNAPSHOT}" -- firestore.rules firestore.indexes.json
commit_phase "feature/pe-phase-5-firestore" "$(cat <<'EOF'
chore(firestore): rules and indexes for boost, typing, group posts

Add security rules for boosts, chat typing indicators, and group posts plus
composite indexes for boost expiry and group post feeds.
EOF
)"

echo "All phase branches pushed."
