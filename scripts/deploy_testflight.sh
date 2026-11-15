#!/bin/bash

# NaijaSingles TestFlight Deployment Script
# Standardized deployment process using altool (Apple's official upload tool)
#
# Usage:
#   ./scripts/deploy_testflight.sh                         # Build + upload
#   ./scripts/deploy_testflight.sh --fast                  # Build + upload (skip clean)
#   ./scripts/deploy_testflight.sh --build-only            # Build IPA only (device-verify first)
#   ./scripts/deploy_testflight.sh --upload-only           # Upload existing IPA under build/ios/ipa/
#   ./scripts/deploy_testflight.sh --upload-only PATH.ipa  # Upload that exact verified IPA
#
# After --build-only, upload the SAME artifact with --upload-only (or Xcode Organizer).
# Do NOT re-run a full deploy: that increments the build number and ships an unverified IPA.
#
# Prerequisites: .env with FASTLANE_USERNAME and FASTLANE_PASSWORD (upload paths only)
#
# Release builds MUST pass --dart-define=ENV=production. Without it, Dart defaults
# to staging and lib/main.dart aborts release startup (STRICT_RELEASE_FIREBASE_GUARD).

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
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
    echo "Usage: $0 [--fast] [--build-only | --upload-only [IPA_PATH]]"
}

FAST_MODE=false
BUILD_ONLY=false
UPLOAD_ONLY=false
UPLOAD_IPA_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fast)
            FAST_MODE=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --upload-only)
            UPLOAD_ONLY=true
            shift
            if [[ $# -gt 0 && "$1" != -* ]]; then
                UPLOAD_IPA_PATH="$1"
                shift
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

if [ "$BUILD_ONLY" = true ] && [ "$UPLOAD_ONLY" = true ]; then
    print_error "--build-only and --upload-only are mutually exclusive"
    usage
    exit 1
fi

# Canonical release Firebase project (must match lib/firebase_options.dart).
RELEASE_ENV="production"
RELEASE_PROJECT_ID="naijasingles-74a75"

require_upload_credentials() {
    if [ ! -f ".env" ]; then
        print_error ".env file not found. Please create it with FASTLANE_USERNAME and FASTLANE_PASSWORD"
        exit 1
    fi

    # shellcheck disable=SC1091
    source .env

    if [ -z "$FASTLANE_USERNAME" ] || [ -z "$FASTLANE_PASSWORD" ]; then
        print_error "FASTLANE_USERNAME and FASTLANE_PASSWORD must be set in .env file"
        exit 1
    fi

    print_success "Environment variables loaded"
}

resolve_ipa_path() {
    # Prints the absolute IPA path on stdout. Errors go to stderr; returns non-zero
    # on failure (safe under command substitution + set -e).
    local explicit_path="$1"
    local resolved=""

    if [ -n "$explicit_path" ]; then
        if [ ! -f "$explicit_path" ]; then
            print_error "IPA not found: $explicit_path"
            return 1
        fi
        resolved="$explicit_path"
    else
        resolved="$(ls -1 build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
        if [ -z "$resolved" ] || [ ! -f "$resolved" ]; then
            print_error "IPA file not found under build/ios/ipa/"
            print_error "Pass an explicit path: $0 --upload-only /path/to/App.ipa"
            return 1
        fi
    fi

    # Prefer absolute path so logs are unambiguous.
    if command -v realpath >/dev/null 2>&1; then
        realpath "$resolved"
    else
        # macOS fallback without realpath
        local dir base
        dir="$(cd "$(dirname "$resolved")" && pwd)"
        base="$(basename "$resolved")"
        echo "${dir}/${base}"
    fi
}

upload_ipa() {
    local ipa_path="$1"
    local ipa_size
    ipa_size=$(du -h "$ipa_path" | cut -f1)

    print_status "Uploading to TestFlight..."
    echo "Uploading with altool (Apple's official upload tool)..."
    echo "Username: $FASTLANE_USERNAME"
    echo "IPA: $ipa_path ($ipa_size)"
    echo ""

    if xcrun altool --upload-app \
        --type ios \
        --file "$ipa_path" \
        --username "$FASTLANE_USERNAME" \
        --password "$FASTLANE_PASSWORD"; then
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
}

# --- Upload-only: ship the exact verified IPA (no bump, no rebuild) ---
if [ "$UPLOAD_ONLY" = true ]; then
    print_status "Upload-only mode: will not increment build number or rebuild"
    require_upload_credentials

    IPA_PATH="$(resolve_ipa_path "$UPLOAD_IPA_PATH")"
    print_success "Using verified IPA: $IPA_PATH"
    print_warning "Confirm this is the same artifact you device-tested (do not rebuild first)."
    upload_ipa "$IPA_PATH"
    exit 0
fi

# Step 1: Environment Validation
print_status "Step 1: Validating environment..."

if [ "$BUILD_ONLY" = false ]; then
    require_upload_credentials
else
    print_status "Build-only mode: skipping Fastlane credential check"
fi

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    exit 1
fi

print_success "Flutter and Xcode are available"
print_status "Release dart-define: ENV=$RELEASE_ENV (Firebase project $RELEASE_PROJECT_ID)"

# Step 2: Environment Setup (Optimized)
print_status "Step 2: Setting up environment..."

if [ "$FAST_MODE" = true ]; then
    print_status "Fast mode enabled - skipping clean"
fi

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
CURRENT_CERT=$(xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep CODE_SIGN_IDENTITY | head -1 | cut -d'=' -f2 | xargs)
CURRENT_TEAM=$(xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep DEVELOPMENT_TEAM | head -1 | cut -d'=' -f2 | xargs)

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

# Single source of truth after bump: pubspec + Flutter --build-name/--build-number.
# Info.plist must keep $(FLUTTER_BUILD_NUMBER) / $(FLUTTER_BUILD_NAME) — do not hardcode.
print_status "Incrementing build number..."
fastlane run increment_build_number xcodeproj:"ios/Runner.xcodeproj"

NEW_BUILD=$(cd ios && xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep CURRENT_PROJECT_VERSION | head -1 | cut -d'=' -f2 | xargs)
MARKETING_VERSION=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$MARKETING_VERSION" ] || [ -z "$NEW_BUILD" ]; then
    print_error "Could not resolve marketing version ($MARKETING_VERSION) or build number ($NEW_BUILD)"
    exit 1
fi

sed -i '' -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${MARKETING_VERSION}+${NEW_BUILD}/" pubspec.yaml
print_success "Synced pubspec.yaml to version: ${MARKETING_VERSION}+${NEW_BUILD}"

print_status "Building IPA with ENV=$RELEASE_ENV, ${MARKETING_VERSION}+${NEW_BUILD}"
flutter build ipa --release \
    --build-name="$MARKETING_VERSION" \
    --build-number="$NEW_BUILD" \
    --dart-define=ENV="$RELEASE_ENV"

print_success "iOS IPA build completed successfully (${MARKETING_VERSION}+${NEW_BUILD}, ENV=$RELEASE_ENV)"

# Step 5: Validate IPA
print_status "Step 5: Validating IPA file..."

IPA_PATH="$(resolve_ipa_path "")"
IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
print_success "IPA file found: $IPA_PATH ($IPA_SIZE)"

print_warning "Before uploading: install this build on a device and confirm startup logs show:"
echo "         env=$RELEASE_ENV … project=$RELEASE_PROJECT_ID"
echo "         (Release builds with ENV=staging crash in main.dart.)"
echo ""

if [ "$BUILD_ONLY" = true ]; then
    print_success "Build-only complete — skipped upload."
    echo ""
    print_status "After device launch OK, upload THIS same IPA (do not rebuild):"
    echo "  $0 --upload-only \"$IPA_PATH\""
    echo "  # or open the archive in Xcode Organizer → Distribute App → App Store Connect"
    echo "  # Archive: build/ios/archive/Runner.xcarchive"
    exit 0
fi

# Step 6: Upload to TestFlight (same IPA just built — full pipeline)
upload_ipa "$IPA_PATH"
