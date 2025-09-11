#!/bin/bash

# iOS Build and Archive Script
# Usage: ./scripts/build_ios.sh

set -e  # Exit on any error

echo "🚀 Starting iOS Build Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Step 1: Clean and get dependencies
print_status "Step 1: Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Step 2: Update iOS pods
print_status "Step 2: Updating iOS pods..."
cd ios
pod install --repo-update
cd ..

# Step 3: Build iOS archive
print_status "Step 3: Building iOS archive..."
cd ios

# Create archive using xcodebuild
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath Runner.xcarchive \
    archive

if [ $? -eq 0 ]; then
    print_status "✅ Archive created successfully!"
else
    print_error "❌ Archive creation failed!"
    exit 1
fi

# Step 4: Export IPA
print_status "Step 4: Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath Runner.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ExportOptions.plist

if [ $? -eq 0 ]; then
    print_status "✅ IPA exported successfully!"
    print_status "📱 IPA location: ios/build/Runner.ipa"
else
    print_error "❌ IPA export failed!"
    exit 1
fi

cd ..

print_status "🎉 Build process completed successfully!"
print_status "📋 Next steps:"
print_status "   1. Open Xcode Organizer: open ios/Runner.xcarchive"
print_status "   2. Click 'Distribute App' → 'App Store Connect' → 'Upload'"
print_status "   3. Or use: ./scripts/upload_ios.sh"
