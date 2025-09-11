#!/bin/bash

# Echo status messages with color for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting NaijaSingles Flutter project setup...${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Clean any previous build artifacts
echo -e "${GREEN}Cleaning previous build artifacts...${NC}"
flutter clean

# Get Flutter dependencies
echo -e "${GREEN}Installing Flutter dependencies...${NC}"
flutter pub get

# Run Flutter doctor to verify setup
echo -e "${GREEN}Verifying Flutter installation...${NC}"
flutter doctor -v

# Ensure correct Flutter channel
echo -e "${GREEN}Ensuring Flutter is on stable channel...${NC}"
flutter channel stable
flutter upgrade --force

# Generate any necessary files
echo -e "${GREEN}Generating necessary files...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs || echo -e "${YELLOW}Note: build_runner may not be configured for this project${NC}"

# Verify permissions for iOS builds if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}Setting up iOS build environment...${NC}"
    flutter precache --ios
    cd ios && pod install && cd ..
fi

# Verify Android SDK setup if ANDROID_SDK_ROOT is set
if [ -n "$ANDROID_SDK_ROOT" ]; then
    echo -e "${GREEN}Verifying Android SDK setup...${NC}"
    flutter config --android-sdk $ANDROID_SDK_ROOT
else
    echo -e "${YELLOW}ANDROID_SDK_ROOT not set. Skipping Android SDK configuration.${NC}"
fi

echo -e "${GREEN}Setup complete! Your NaijaSingles Flutter project is ready for development.${NC}"
echo -e "${YELLOW}If you encounter any issues, please run 'flutter doctor' for diagnostics.${NC}"
