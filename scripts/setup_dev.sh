#!/bin/bash

# Development Environment Setup Script
# Usage: ./scripts/setup_dev.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header "AFROPEEP DEVELOPMENT SETUP"

# Check Flutter installation
print_status "Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_status "✅ Flutter installed: $FLUTTER_VERSION"
else
    print_error "❌ Flutter not installed. Please install Flutter first."
    exit 1
fi

# Check Xcode installation
print_status "Checking Xcode installation..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_status "✅ Xcode installed: $XCODE_VERSION"
else
    print_error "❌ Xcode not installed. Please install Xcode from App Store."
    exit 1
fi

# Check CocoaPods installation
print_status "Checking CocoaPods installation..."
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    print_status "✅ CocoaPods installed: $POD_VERSION"
else
    print_warning "⚠️  CocoaPods not installed. Installing..."
    sudo gem install cocoapods
fi

# Check Apple Developer account
print_status "Checking Apple Developer account..."
if security find-identity -v -p codesigning | grep -q "Apple Development"; then
    print_status "✅ Apple Developer certificates found"
else
    print_warning "⚠️  No Apple Developer certificates found"
    print_status "Please ensure you're signed into Xcode with your Apple Developer account"
fi

# Install dependencies
print_status "Installing Flutter dependencies..."
flutter pub get

print_status "Installing iOS dependencies..."
cd ios
pod install
cd ..

# Run Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

print_header "SETUP COMPLETE"
print_status "🎉 Development environment is ready!"
print_status "📋 Next steps:"
print_status "   1. Run: flutter run -d ios"
print_status "   2. Or deploy: ./scripts/deploy.sh"
print_status "   3. Check DEPLOYMENT.md for detailed instructions"
