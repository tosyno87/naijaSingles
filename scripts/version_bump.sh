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

# Update pubspec.yaml
sed -i '' "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml

# Update iOS Info.plist
sed -i '' "s/<key>CFBundleShortVersionString<\/key>.*/<key>CFBundleShortVersionString<\/key>\n\t<string>$MAJOR.$MINOR.$PATCH<\/string>/" ios/Runner/Info.plist
sed -i '' "s/<key>CFBundleVersion<\/key>.*/<key>CFBundleVersion<\/key>\n\t<string>$BUILD_NUMBER<\/string>/" ios/Runner/Info.plist

print_status "✅ Version updated to $NEW_VERSION"
print_status "📱 Version: $MAJOR.$MINOR.$PATCH"
print_status "🔢 Build: $BUILD_NUMBER"

# Commit version bump
git add pubspec.yaml ios/Runner/Info.plist
git commit -m "Bump version to $NEW_VERSION"

print_status "🎉 Version bump complete!"
