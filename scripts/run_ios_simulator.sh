#!/bin/bash
# Script to run Flutter app on iOS simulator with proper code signing disabled
set -e

cd "$(dirname "$0")/.."

# Get the first available iOS simulator
SIMULATOR_ID=$(flutter devices | grep -i "simulator" | head -1 | awk '{print $5}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iOS simulator found. Please start a simulator first."
    exit 1
fi

echo "📱 Running on simulator: $SIMULATOR_ID"
echo ""

# Run Flutter with explicit simulator
flutter run -d "$SIMULATOR_ID"

