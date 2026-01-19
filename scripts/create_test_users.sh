#!/bin/bash
# Helper script to create test users via Cloud Function
# This calls the deployed Cloud Function via HTTP

set -e

COUNT=${1:-60}  # Default to 60 users if not specified

FUNCTION_URL="https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers"

# Get admin secret from .env.local file, environment variable, or default
# Priority: .env.local > environment variable > default
if [ -f .env.local ]; then
  source .env.local
fi
ADMIN_SECRET="${ADMIN_SECRET:-dev-secret-change-in-production}"

echo "🚀 Creating $COUNT test users via Cloud Function..."
echo ""

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed"
    exit 1
fi

echo "🔥 Calling createTestUsers function..."
echo ""

# Call the function via HTTP with authentication
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -d "{\"count\": $COUNT}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Success!"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    echo ""
    echo "📊 Check Firebase Console to verify users were created:"
    echo "   Authentication → Users"
    echo "   Firestore → users collection (filter: isTestUser == true)"
elif [ "$HTTP_CODE" -eq 401 ]; then
    echo "❌ Authentication failed"
    echo "   Set ADMIN_SECRET environment variable:"
    echo "   export ADMIN_SECRET='your-secret-token'"
    echo ""
    echo "$BODY"
    exit 1
else
    echo "❌ Error: HTTP $HTTP_CODE"
    echo "$BODY"
    exit 1
fi
