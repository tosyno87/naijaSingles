#!/bin/bash
# Test App Store Connect API Key Authentication

echo "🔍 Testing App Store Connect API Key..."
echo ""

# Check environment variables
if [ -z "$APPSTORE_API_KEY_ID" ]; then
    echo "❌ APPSTORE_API_KEY_ID is not set"
    exit 1
fi

if [ -z "$APPSTORE_API_ISSUER_ID" ]; then
    echo "❌ APPSTORE_API_ISSUER_ID is not set"
    exit 1
fi

if [ -z "$APPSTORE_API_PRIVATE_KEY" ]; then
    echo "❌ APPSTORE_API_PRIVATE_KEY is not set"
    exit 1
fi

echo "✅ API Key ID: $APPSTORE_API_KEY_ID"
echo "✅ Issuer ID: $APPSTORE_API_ISSUER_ID"
echo "✅ Private Key length: $(echo "$APPSTORE_API_PRIVATE_KEY" | wc -c) characters"
echo ""

# Create the AuthKey file
mkdir -p ~/.appstoreconnect/private_keys

cat > ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8 <<EOF
$APPSTORE_API_PRIVATE_KEY
EOF

chmod 600 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8

echo "✅ AuthKey file created at: ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8"
echo ""

# Verify the file content
echo "🔍 Verifying AuthKey file format..."
if head -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8 | grep -q "BEGIN PRIVATE KEY"; then
    echo "✅ File starts with '-----BEGIN PRIVATE KEY-----'"
else
    echo "❌ File does NOT start with '-----BEGIN PRIVATE KEY-----'"
    echo "First line is:"
    head -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
fi

if tail -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8 | grep -q "END PRIVATE KEY"; then
    echo "✅ File ends with '-----END PRIVATE KEY-----'"
else
    echo "❌ File does NOT end with '-----END PRIVATE KEY-----'"
    echo "Last line is:"
    tail -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
fi

echo ""
echo "File line count: $(wc -l < ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8)"
echo ""

# Test API access
echo "🔍 Testing API authentication by listing apps..."
echo ""

xcrun altool --list-apps \
  --apiKey "$APPSTORE_API_KEY_ID" \
  --apiIssuer "$APPSTORE_API_ISSUER_ID" \
  --verbose

RESULT=$?

echo ""
if [ $RESULT -eq 0 ]; then
    echo "✅ API authentication successful!"
else
    echo "❌ API authentication failed with exit code: $RESULT"
    echo ""
    echo "Common issues:"
    echo "1. API key might not have 'App Manager' or 'Admin' role"
    echo "2. API key might be expired"
    echo "3. API key might be for a different team"
    echo "4. Private key format might be incorrect"
fi

