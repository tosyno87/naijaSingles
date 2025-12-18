#!/bin/bash

# 🚀 Quick iOS Testing Script - Run from Cursor
# Tests changes locally on iPhone Simulator without pushing to repo

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📱 Testing Afropeep on iPhone Simulator${NC}"
echo "========================================"
echo ""

# 1. Get dependencies
echo -e "${GREEN}📦 Getting dependencies...${NC}"
flutter pub get

# 2. Format code
echo -e "${GREEN}📝 Formatting code...${NC}"
dart format lib/ test/ || true

# 3. Analyze (non-blocking)
echo -e "${GREEN}🔍 Analyzing code...${NC}"
flutter analyze --no-fatal-infos || echo -e "${YELLOW}⚠️  Code analysis found issues (continuing)${NC}"

# 4. Run tests (non-blocking)
echo -e "${GREEN}🧪 Running tests...${NC}"
flutter test || echo -e "${YELLOW}⚠️  Some tests failed (continuing)${NC}"

# 5. Launch iOS Simulator if not running
echo -e "${GREEN}📱 Checking iOS Simulator...${NC}"

# Find first available iOS simulator device ID
IOS_SIMULATOR=$(flutter devices | grep "iPhone.*simulator" | head -1 | awk -F '•' '{print $2}' | xargs)

if [ -z "$IOS_SIMULATOR" ]; then
    echo "No iOS simulator found. Starting default simulator..."
    open -a Simulator
    sleep 5
    # Try to get simulator ID again
    IOS_SIMULATOR=$(flutter devices | grep "iPhone" | grep "simulator" | head -1 | awk -F '•' '{print $2}' | xargs)
fi

if [ -z "$IOS_SIMULATOR" ]; then
    # Fallback: try to use "ios" device type (Flutter will auto-select)
    echo "Using default iOS device selector..."
    IOS_SIMULATOR="ios"
fi

echo "Using iOS Simulator: $IOS_SIMULATOR"

# 6. Run app on iOS Simulator
echo ""
echo -e "${GREEN}🚀 Starting app on iPhone Simulator...${NC}"
echo -e "${YELLOW}💡 Hot Reload Commands:${NC}"
echo "   Press 'r' = Hot reload (apply changes instantly)"
echo "   Press 'R' = Hot restart (full app restart)"
echo "   Press 'q' = Quit"
echo ""
echo -e "${YELLOW}⚠️  Note: If you see code signing errors, open ios/Runner.xcworkspace in Xcode once to configure automatic signing.${NC}"
echo ""

# Try running with explicit simulator destination
flutter run -d "$IOS_SIMULATOR" --device-id="$IOS_SIMULATOR" || {
    echo ""
    echo -e "${YELLOW}⚠️  Build failed. Trying alternative approach...${NC}"
    echo -e "${YELLOW}💡 If code signing fails, please:${NC}"
    echo "   1. Open ios/Runner.xcworkspace in Xcode"
    echo "   2. Select Runner target → Signing & Capabilities"
    echo "   3. Enable 'Automatically manage signing'"
    echo "   4. Select your Team (M7HY7333KT)"
    echo "   5. Try running this script again"
    echo ""
    exit 1
}

echo ""
echo -e "${GREEN}✅ Testing complete!${NC}"

