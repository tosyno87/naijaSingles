#!/bin/bash

# NaijaSingles TestFlight Deployment Script
# Standardized deployment process using altool (Apple's official upload tool)
# 
# Usage: 
#   ./scripts/deploy_testflight.sh          # Full deployment (with clean if needed)
#   ./scripts/deploy_testflight.sh --fast   # Fast deployment (skip clean)
# Prerequisites: .env file with FASTLANE_USERNAME and FASTLANE_PASSWORD

set -e  # Exit on any error

echo "🚀 NaijaSingles TestFlight Deployment"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Environment Validation
print_status "Step 1: Validating environment..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please create it with FASTLANE_USERNAME and FASTLANE_PASSWORD"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$FASTLANE_USERNAME" ] || [ -z "$FASTLANE_PASSWORD" ]; then
    print_error "FASTLANE_USERNAME and FASTLANE_PASSWORD must be set in .env file"
    exit 1
fi

print_success "Environment variables loaded"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    exit 1
fi

print_success "Flutter and Xcode are available"

# Step 2: Environment Setup (Optimized)
print_status "Step 2: Setting up environment..."

# Check if fast mode is requested
FAST_MODE=false
if [ "$1" = "--fast" ]; then
    FAST_MODE=true
    print_status "Fast mode enabled - skipping clean"
fi

# Check if clean is needed (only if build artifacts are stale and not in fast mode)
if [ "$FAST_MODE" = false ] && ([ ! -f "build/ios/Runner.ipa" ] || [ "ios/Podfile.lock" -nt "build/ios/Runner.ipa" ]); then
    print_status "Cleaning environment (build artifacts stale)..."
    flutter clean
    print_success "Flutter clean completed"
else
    print_status "Skipping clean (fast mode or build artifacts are current)"
fi

flutter pub get
print_success "Dependencies restored"

# Step 3: Code Signing Verification
print_status "Step 3: Verifying code signing configuration..."

cd ios
CURRENT_CERT=$(xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep CODE_SIGN_IDENTITY | cut -d'=' -f2 | xargs)
CURRENT_TEAM=$(xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep DEVELOPMENT_TEAM | cut -d'=' -f2 | xargs)

if [[ "$CURRENT_CERT" == *"Apple Distribution"* ]]; then
    print_success "Apple Distribution certificate configured: $CURRENT_CERT"
else
    print_warning "Current certificate: $CURRENT_CERT"
    print_warning "Consider using Apple Distribution certificate for TestFlight"
fi

if [[ "$CURRENT_TEAM" == "M7HY7333KT" ]]; then
    print_success "Correct development team configured: $CURRENT_TEAM"
else
    print_warning "Current team: $CURRENT_TEAM"
fi

cd ..

# Step 4: Build Process
print_status "Step 4: Building iOS app..."

# Increment build number using Fastlane
print_status "Incrementing build number..."
fastlane run increment_build_number xcodeproj:"ios/Runner.xcodeproj"

# Sync pubspec.yaml with new build number
NEW_BUILD=$(cd ios && xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep CURRENT_PROJECT_VERSION | cut -d'=' -f2 | xargs)
sed -i '' "s/version: [0-9.]\\+\\+[0-9]\\+/version: 1.0.0+$NEW_BUILD/" pubspec.yaml
print_success "Updated pubspec.yaml to version: 1.0.0+$NEW_BUILD"

# Handle CocoaPods compatibility issues by using Flutter's build process
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "iOS build completed successfully"
else
    print_error "iOS build failed"
    exit 1
fi

# Step 5: Validate IPA
print_status "Step 5: Validating IPA file..."

IPA_PATH="build/ios/Runner.ipa"
if [ ! -f "$IPA_PATH" ]; then
    print_error "IPA file not found at $IPA_PATH"
    exit 1
fi

IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
print_success "IPA file found: $IPA_PATH ($IPA_SIZE)"

# Step 6: Upload to TestFlight
print_status "Step 6: Uploading to TestFlight..."

echo "Uploading with altool (Apple's official upload tool)..."
echo "Username: $FASTLANE_USERNAME"
echo "IPA: $IPA_PATH"
echo ""

# Upload using altool
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$FASTLANE_USERNAME" \
    --password "$FASTLANE_PASSWORD"

if [ $? -eq 0 ]; then
    print_success "Upload completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Check App Store Connect: https://appstoreconnect.apple.com/apps"
    echo "2. Wait for processing (5-15 minutes)"
    echo "3. Add testers and configure TestFlight groups"
    echo "4. Add release notes for the build"
    echo ""
    print_success "Deployment completed! 🎉"
else
    print_error "Upload failed"
    exit 1
fi
