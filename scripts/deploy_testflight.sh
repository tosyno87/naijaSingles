#!/bin/bash

# NaijaSingles TestFlight Deployment Script
# Standardized deployment process using altool (Apple's official upload tool)
#
# Usage:
#   ./scripts/deploy_testflight.sh                         # Build + upload
#   ./scripts/deploy_testflight.sh --fast                  # Build + upload (skip clean)
#   ./scripts/deploy_testflight.sh --build-only            # Build IPA only (device-verify first)
#   ./scripts/deploy_testflight.sh --upload-only PATH.ipa  # Upload that exact verified IPA (path required)
#
# After --build-only, upload the SAME artifact with --upload-only PATH.ipa (or Xcode Organizer).
# Do NOT re-run a full deploy: that increments the build number and ships an unverified IPA.
# --upload-only never auto-picks from build/ios/ipa/ (avoids uploading a stale IPA).
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
    echo "Usage: $0 [--fast] [--build-only | --upload-only IPA_PATH]"
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
            if [[ $# -eq 0 || "$1" == -* ]]; then
                print_error "--upload-only requires an explicit IPA path"
                usage
                exit 1
            fi
            UPLOAD_IPA_PATH="$1"
            shift
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

# Flutter shells out to `pod`; rbenv shims fail when the active Ruby lacks the gem.
ensure_ruby_ios_tooling() {
    if pod --version >/dev/null 2>&1; then
        return
    fi
    if [ -x "${HOME}/.rbenv/versions/3.1.4/bin/pod" ]; then
        export RBENV_VERSION=3.1.4
        print_status "Using RBENV_VERSION=3.1.4 so CocoaPods/fastlane shims resolve"
        return
    fi
    print_error "CocoaPods (pod) is not working. Install/fix CocoaPods for the active Ruby."
    exit 1
}

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

absolutize_path() {
    local path="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$path"
    else
        local dir base
        dir="$(cd "$(dirname "$path")" && pwd)"
        base="$(basename "$path")"
        echo "${dir}/${base}"
    fi
}

resolve_explicit_ipa_path() {
    # Prints the absolute IPA path on stdout. Errors go to stderr; returns non-zero
    # on failure (safe under command substitution + set -e).
    local explicit_path="$1"

    if [ -z "$explicit_path" ]; then
        print_error "IPA path is required"
        return 1
    fi
    if [ ! -f "$explicit_path" ]; then
        print_error "IPA not found: $explicit_path"
        return 1
    fi
    case "$explicit_path" in
        *.ipa|*.IPA) ;;
        *)
            print_error "Path must be an .ipa file: $explicit_path"
            return 1
            ;;
    esac

    absolutize_path "$explicit_path"
}

# Post-build only: accept exactly one IPA under build/ios/ipa/. Never pick alphabetically
# among several — that can upload a stale artifact.
find_unique_built_ipa() {
    local ipa_dir="build/ios/ipa"
    local -a ipas=()
    local f

    if [ ! -d "$ipa_dir" ]; then
        print_error "IPA directory not found: $ipa_dir/"
        return 1
    fi

    shopt -s nullglob
    ipas=("$ipa_dir"/*.ipa)
    shopt -u nullglob

    if [ "${#ipas[@]}" -eq 0 ]; then
        print_error "IPA file not found under $ipa_dir/"
        return 1
    fi
    if [ "${#ipas[@]}" -gt 1 ]; then
        print_error "Multiple IPAs under $ipa_dir/ — refusing to guess which to use:"
        for f in "${ipas[@]}"; do
            echo "  - $f" >&2
        done
        print_error "Remove stale IPAs or pass an explicit path to --upload-only"
        return 1
    fi

    absolutize_path "${ipas[0]}"
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

    IPA_PATH="$(resolve_explicit_ipa_path "$UPLOAD_IPA_PATH")"
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
ensure_ruby_ios_tooling
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
# Do not use agvtool/fastlane increment here: both rewrite Info.plist to a literal build.
print_status "Incrementing build number..."
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
CURRENT_BUILD=$(grep -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" | head -1 | sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);/\1/')
if [ -z "$CURRENT_BUILD" ]; then
    print_error "Could not read CURRENT_PROJECT_VERSION from $PBXPROJ"
    exit 1
fi
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"

# Restore Flutter placeholders if a prior agvtool/fastlane run hardcoded them.
# Use sed (not PlistBuddy) so we do not rewrite the whole plist formatting.
if ! grep -q '<string>$(FLUTTER_BUILD_NUMBER)</string>' ios/Runner/Info.plist; then
    sed -i '' '/<key>CFBundleVersion<\/key>/{n;s#<string>[^<]*</string>#<string>$(FLUTTER_BUILD_NUMBER)</string>#;}' \
        ios/Runner/Info.plist
fi
if ! grep -q '<string>$(FLUTTER_BUILD_NAME)</string>' ios/Runner/Info.plist; then
    sed -i '' '/<key>CFBundleShortVersionString<\/key>/{n;s#<string>[^<]*</string>#<string>$(FLUTTER_BUILD_NAME)</string>#;}' \
        ios/Runner/Info.plist
fi

MARKETING_VERSION=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$MARKETING_VERSION" ] || [ -z "$NEW_BUILD" ]; then
    print_error "Could not resolve marketing version ($MARKETING_VERSION) or build number ($NEW_BUILD)"
    exit 1
fi

sed -i '' -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${MARKETING_VERSION}+${NEW_BUILD}/" pubspec.yaml
print_success "Synced pubspec.yaml + Xcode to version: ${MARKETING_VERSION}+${NEW_BUILD}"

print_status "Building IPA with ENV=$RELEASE_ENV, ${MARKETING_VERSION}+${NEW_BUILD}"
set +e
flutter build ipa --release \
    --build-name="$MARKETING_VERSION" \
    --build-number="$NEW_BUILD" \
    --dart-define=ENV="$RELEASE_ENV"
BUILD_EXIT=$?
set -e

ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
set +e
IPA_PATH="$(find_unique_built_ipa)"
FIND_IPA_EXIT=$?
set -e
if [ "$FIND_IPA_EXIT" -ne 0 ] || [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
    print_error "flutter build ipa did not produce a unique IPA under build/ios/ipa/ (exit=$BUILD_EXIT)"
    if [ -d "$ARCHIVE_PATH" ]; then
        print_warning "Archive exists at $ARCHIVE_PATH but App Store export failed or IPA is ambiguous."
        print_warning "Usually missing iOS Distribution cert / App Store profile."
        print_warning "Open in Organizer to export once signing is fixed:"
        echo "  open $ARCHIVE_PATH"
        print_warning "Do not treat this archive as uploaded; device-verify first, then export THAT archive."
    fi
    exit 1
fi
if [ "$BUILD_EXIT" -ne 0 ]; then
    print_error "flutter build ipa exited $BUILD_EXIT"
    exit "$BUILD_EXIT"
fi

print_success "iOS IPA build completed successfully (${MARKETING_VERSION}+${NEW_BUILD}, ENV=$RELEASE_ENV)"

# Step 5: Validate IPA
print_status "Step 5: Validating IPA file..."

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
