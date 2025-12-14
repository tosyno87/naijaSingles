#!/bin/bash
# Best Practice: Test App Store Connect API Key Authentication
# This script tests the API key without uploading anything

set -e  # Exit on any error

echo "🔍 Testing App Store Connect API Key Authentication"
echo "=================================================="
echo ""

# Check if environment variables are set
if [ -z "$APPSTORE_API_KEY_ID" ]; then
    echo "❌ APPSTORE_API_KEY_ID is not set"
    echo "Please set: export APPSTORE_API_KEY_ID='your-key-id'"
    exit 1
fi

if [ -z "$APPSTORE_API_ISSUER_ID" ]; then
    echo "❌ APPSTORE_API_ISSUER_ID is not set"
    echo "Please set: export APPSTORE_API_ISSUER_ID='your-issuer-id'"
    exit 1
fi

if [ -z "$APPSTORE_API_PRIVATE_KEY" ]; then
    echo "❌ APPSTORE_API_PRIVATE_KEY is not set"
    echo "Please set: export APPSTORE_API_PRIVATE_KEY='\$(cat path/to/AuthKey.p8)'"
    exit 1
fi

echo "✅ Environment variables are set"
echo "   Key ID: $APPSTORE_API_KEY_ID"
echo "   Issuer ID: $APPSTORE_API_ISSUER_ID"
echo "   Private Key: $(echo "$APPSTORE_API_PRIVATE_KEY" | wc -c) characters"
echo ""

# Create the AuthKey file
echo "🔧 Setting up API key file..."
mkdir -p ~/.appstoreconnect/private_keys

# Create the AuthKey file with exact formatting
printf "%s\n" "$APPSTORE_API_PRIVATE_KEY" > ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8

echo "✅ AuthKey file created: ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8"

# Verify file format
echo "🔍 Verifying file format..."
if head -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8 | grep -q "BEGIN PRIVATE KEY"; then
    echo "✅ File starts correctly"
else
    echo "❌ File does NOT start with BEGIN PRIVATE KEY"
    head -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
    exit 1
fi

if tail -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8 | grep -q "END PRIVATE KEY"; then
    echo "✅ File ends correctly"
else
    echo "❌ File does NOT end with END PRIVATE KEY"
    tail -1 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
    exit 1
fi

echo "✅ File format verified ($(wc -l < ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8) lines)"
echo ""

# Test 1: List apps (most basic authentication test)
echo "🧪 Test 1: Listing accessible apps..."
echo "This tests if the API key can authenticate and what apps it has access to:"
echo ""

if xcrun altool --list-apps \
    --apiKey "$APPSTORE_API_KEY_ID" \
    --apiIssuer "$APPSTORE_API_ISSUER_ID" \
    --verbose; then
    echo ""
    echo "✅ Test 1 PASSED: API authentication successful!"
    echo "   The API key can authenticate and has access to apps."
else
    echo ""
    echo "❌ Test 1 FAILED: API authentication failed"
    echo ""
    echo "🔍 Troubleshooting steps:"
    echo "1. Verify the API key has 'Admin' or 'App Manager' role"
    echo "2. Check if the API key is for the correct team"
    echo "3. Ensure the .p8 file content is exactly correct"
    echo "4. Verify the Key ID and Issuer ID match App Store Connect"
    exit 1
fi

echo ""
echo "🎯 Test 2: Verify specific app access..."
echo "Testing access to our specific app (com.app.naijasingles):"

# Test 2: Check if we can access our specific app
if xcrun altool --list-apps \
    --apiKey "$APPSTORE_API_KEY_ID" \
    --apiIssuer "$APPSTORE_API_ISSUER_ID" \
    --verbose | grep -q "com.app.naijasingles"; then
    echo "✅ Test 2 PASSED: App 'com.app.naijasingles' is accessible"
else
    echo "⚠️  Test 2 WARNING: App 'com.app.naijasingles' not found in accessible apps"
    echo "   This might be normal if the app hasn't been created in App Store Connect yet"
    echo "   The API key authentication is working, but the app might need to be created first"
fi

echo ""
echo "🎉 API Key Authentication Test Complete!"
echo ""
echo "📋 Summary:"
echo "   ✅ API key format: Correct"
echo "   ✅ Authentication: Working"
echo "   ✅ File permissions: Secure"
echo ""
echo "🚀 Next Steps:"
echo "   1. If tests passed, the API key should work in CI/CD"
echo "   2. If upload still fails, the issue might be app-specific"
echo "   3. Make sure the app exists in App Store Connect"
echo ""
echo "💡 Pro Tip: Run this test before every CI/CD deployment to catch issues early!"

