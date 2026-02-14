#!/bin/bash

# 🚀 Quick Local Testing Script for Afropeep
# Run this script directly from Cursor to test changes without pushing to repo

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Afropeep - Local Testing${NC}"
echo "=================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Step 1: Get dependencies
echo -e "${GREEN}📦 Step 1: Getting dependencies...${NC}"
flutter pub get

# Step 2: Analyze code
echo ""
echo -e "${GREEN}🔍 Step 2: Analyzing code...${NC}"
flutter analyze --no-fatal-infos || echo -e "${YELLOW}⚠️  Code analysis found issues (continuing anyway)${NC}"

# Step 3: Run tests
echo ""
echo -e "${GREEN}🧪 Step 3: Running tests...${NC}"
flutter test || echo -e "${YELLOW}⚠️  Some tests failed (continuing anyway)${NC}"

# Step 4: List available devices
echo ""
echo -e "${GREEN}📱 Step 4: Available devices:${NC}"
flutter devices

# Step 5: Ask which device to use
echo ""
echo -e "${BLUE}Select device to run on:${NC}"
echo "1) iPhone Simulator (iOS)"
echo "2) Android Emulator (if available)"
echo "3) Physical iOS Device (Tosyno)"
echo "4) macOS Desktop"
echo "5) Chrome (Web)"
echo ""
read -p "Enter choice [1-5] (default: 1): " choice
choice=${choice:-1}

case $choice in
    1)
        DEVICE="ios"
        echo -e "${GREEN}✅ Selected: iPhone Simulator${NC}"
        ;;
    2)
        DEVICE="android"
        echo -e "${GREEN}✅ Selected: Android Emulator${NC}"
        ;;
    3)
        DEVICE="00008140-001420263487801C"
        echo -e "${GREEN}✅ Selected: Physical iOS Device (Tosyno)${NC}"
        ;;
    4)
        DEVICE="macos"
        echo -e "${GREEN}✅ Selected: macOS Desktop${NC}"
        ;;
    5)
        DEVICE="chrome"
        echo -e "${GREEN}✅ Selected: Chrome (Web)${NC}"
        ;;
    *)
        DEVICE="ios"
        echo -e "${GREEN}✅ Default: iPhone Simulator${NC}"
        ;;
esac

# Step 6: Run the app
echo ""
echo -e "${GREEN}🚀 Step 5: Starting app on ${DEVICE}...${NC}"
echo -e "${YELLOW}💡 Tip: Press 'r' in terminal for hot reload, 'R' for hot restart, 'q' to quit${NC}"
echo ""

flutter run -d "$DEVICE" --verbose

echo ""
echo -e "${GREEN}✅ Testing complete!${NC}"

