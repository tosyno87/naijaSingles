#!/bin/bash

# Version Bump Script
# Usage: ./scripts/version_bump.sh [major|minor|patch]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
print_status "Current version: $CURRENT_VERSION"

# Parse version (e.g., "1.0.0+1" -> "1.0.0" and "1")
VERSION_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NUMBER"

# Determine bump type
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        print_error "Invalid bump type. Use: major, minor, or patch"
        exit 1
        ;;
esac

# Increment build number
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Create new version
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"

print_status "New version: $NEW_VERSION"

# Update pubspec.yaml — Flutter injects FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER
# into Info.plist. Do not hardcode CFBundleVersion or CFBundleShortVersionString.
sed -i '' "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml

# Keep Xcode CURRENT_PROJECT_VERSION aligned for Fastlane / Organizer.
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" \
        ios/Runner.xcodeproj/project.pbxproj
fi

print_status "✅ Version updated to $NEW_VERSION"
print_status "📱 Version: $MAJOR.$MINOR.$PATCH"
print_status "🔢 Build: $BUILD_NUMBER"
print_status "ℹ️  Info.plist still uses \$(FLUTTER_BUILD_NAME) / \$(FLUTTER_BUILD_NUMBER)"

print_status "🎉 Version bump complete!"
