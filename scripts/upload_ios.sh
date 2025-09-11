#!/bin/bash

# iOS Upload Script
# Usage: ./scripts/upload_ios.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if IPA exists
IPA_PATH="ios/build/Runner.ipa"
if [ ! -f "$IPA_PATH" ]; then
    print_error "IPA file not found at $IPA_PATH"
    print_status "Please run ./scripts/build_ios.sh first"
    exit 1
fi

print_status "📱 Found IPA: $IPA_PATH"

# Method 1: Try Xcode Organizer (Recommended)
print_status "🚀 Opening Xcode Organizer for upload..."
open ios/Runner.xcarchive

print_status "📋 Manual upload steps:"
print_status "   1. In Xcode Organizer, select your archive"
print_status "   2. Click 'Distribute App'"
print_status "   3. Select 'App Store Connect'"
print_status "   4. Select 'Upload'"
print_status "   5. Follow the prompts"

# Method 2: Command line upload (if App-Specific Password is configured)
print_warning "Alternative: Command line upload"
print_status "To enable command line upload:"
print_status "   1. Go to appleid.apple.com"
print_status "   2. Sign in with your Apple ID"
print_status "   3. Generate an App-Specific Password"
print_status "   4. Store it in keychain: security add-generic-password -a 'bbtnd_tosin@yahoo.com' -s 'AC_PASSWORD' -w 'YOUR_APP_SPECIFIC_PASSWORD'"
print_status "   5. Then run: xcrun altool --upload-app --type ios --file '$IPA_PATH' --username 'bbtnd_tosin@yahoo.com' --password '@keychain:AC_PASSWORD'"

print_status "🎯 Upload process initiated!"
