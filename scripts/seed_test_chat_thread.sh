#!/usr/bin/env bash
# Seed chatThreads + matches for Messages-tab QA using gcloud + Firestore REST API.
#
# Usage:
#   ./scripts/seed_test_chat_thread.sh
#   ./scripts/seed_test_chat_thread.sh QcDPYcH7XBSM5nbHwDlUHoQlJVB3 hnNwP71qSKXJ1Hxi73qiiiOiVk13
#
# Requires: gcloud auth login (firebase/gcloud project access)
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-naijasingles-74a75}"
EMAIL_UID="${1:-QcDPYcH7XBSM5nbHwDlUHoQlJVB3}"
OTHER_UID="${2:-hnNwP71qSKXJ1Hxi73qiiiOiVk13}"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI is required. Install Google Cloud SDK first."
  exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
  echo "Run: gcloud auth login"
  exit 1
fi

TOKEN="$(gcloud auth print-access-token)"
BASE="https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents"

create_doc() {
  local collection="$1"
  local payload="$2"
  curl -sS -X POST "${BASE}/${collection}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}"
}

THREAD_PAYLOAD="$(cat <<EOF
{
  "fields": {
    "userIds": {
      "arrayValue": {
        "values": [
          {"stringValue": "${EMAIL_UID}"},
          {"stringValue": "${OTHER_UID}"}
        ]
      }
    },
    "userNames": {
      "mapValue": {
        "fields": {
          "${EMAIL_UID}": {"stringValue": "Obatos"},
          "${OTHER_UID}": {"stringValue": "Phone User"}
        }
      }
    },
    "lastMessage": {"nullValue": null},
    "lastMessageText": {"stringValue": "You matched! Say hello!"},
    "lastMessageSenderId": {"nullValue": null},
    "lastUpdated": {"timestampValue": "${NOW}"},
    "createdAt": {"timestampValue": "${NOW}"},
    "unreadCount": {
      "mapValue": {
        "fields": {
          "${EMAIL_UID}": {"integerValue": "0"},
          "${OTHER_UID}": {"integerValue": "0"}
        }
      }
    }
  }
}
EOF
)"

echo "Seeding chatThreads on ${PROJECT}..."
THREAD_RESPONSE="$(create_doc "chatThreads" "${THREAD_PAYLOAD}")"

if echo "${THREAD_RESPONSE}" | grep -q '"error"'; then
  echo "❌ Failed to create chatThreads document:"
  echo "${THREAD_RESPONSE}"
  exit 1
fi

THREAD_ID="$(echo "${THREAD_RESPONSE}" | node -e "
  let data = '';
  process.stdin.on('data', (c) => (data += c));
  process.stdin.on('end', () => {
    const doc = JSON.parse(data);
    const name = doc.name || '';
    const id = name.split('/').pop();
    console.log(id || '');
  });
")"

if [[ -z "${THREAD_ID}" ]]; then
  echo "❌ Could not parse chatThreads document ID"
  echo "${THREAD_RESPONSE}"
  exit 1
fi

MATCH_PAYLOAD="$(cat <<EOF
{
  "fields": {
    "users": {
      "arrayValue": {
        "values": [
          {"stringValue": "${EMAIL_UID}"},
          {"stringValue": "${OTHER_UID}"}
        ]
      }
    },
    "matchedAt": {"timestampValue": "${NOW}"},
    "chatThreadId": {"stringValue": "${THREAD_ID}"},
    "matchStatus": {"stringValue": "matched"}
  }
}
EOF
)"

echo "Seeding matches/${THREAD_ID} link..."
MATCH_RESPONSE="$(create_doc "matches" "${MATCH_PAYLOAD}")"

if echo "${MATCH_RESPONSE}" | grep -q '"error"'; then
  echo "❌ Failed to create matches document:"
  echo "${MATCH_RESPONSE}"
  exit 1
fi

MATCH_ID="$(echo "${MATCH_RESPONSE}" | node -e "
  let data = '';
  process.stdin.on('data', (c) => (data += c));
  process.stdin.on('end', () => {
    const doc = JSON.parse(data);
    const name = doc.name || '';
    console.log(name.split('/').pop() || '');
  });
")"

cat <<EOF
✅ Seeded test chat thread
   project:    ${PROJECT}
   email uid:  ${EMAIL_UID}  (obatos2015@gmail.com / simulator)
   other uid:  ${OTHER_UID}  (+12179044453)
   chatThread: chatThreads/${THREAD_ID}
   match:      matches/${MATCH_ID}

Next: open Messages tab on the simulator and confirm the thread appears.
EOF
