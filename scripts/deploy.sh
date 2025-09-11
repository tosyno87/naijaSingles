#!/bin/bash

# Complete iOS Deployment Script
# Usage: ./scripts/deploy.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_header "AFROPEEP iOS DEPLOYMENT"
print_status "Starting complete deployment process..."

# Step 1: Build
print_header "STEP 1: BUILDING"
./scripts/build_ios.sh

# Step 2: Upload
print_header "STEP 2: UPLOADING"
./scripts/upload_ios.sh

print_header "DEPLOYMENT COMPLETE"
print_status "🎉 Your app has been built and is ready for upload!"
print_status "📱 Next steps:"
print_status "   1. Complete the upload in Xcode Organizer"
print_status "   2. Go to App Store Connect"
print_status "   3. Submit for review with your appeal message"
print_status "   4. Wait for Apple's response (24-48 hours)"

print_status "📋 Appeal message ready to copy from previous conversation"
