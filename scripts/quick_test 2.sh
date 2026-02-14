#!/bin/bash

# ⚡ Quick Test - Fast local testing without prompts
# Usage: ./scripts/quick_test.sh [device]
# Examples:
#   ./scripts/quick_test.sh ios          # iPhone Simulator
#   ./scripts/quick_test.sh android      # Android Emulator
#   ./scripts/quick_test.sh chrome       # Chrome browser
#   ./scripts/quick_test.sh              # Auto-detect first available

set -e

DEVICE=${1:-"ios"}  # Default to iOS if not specified

echo "⚡ Quick Test - Running on $DEVICE..."
echo ""

# Get dependencies
flutter pub get

# Format code
echo "📝 Formatting code..."
dart format lib/ test/ --set-exit-if-changed || true

# Analyze (non-blocking)
echo "🔍 Analyzing code..."
flutter analyze --no-fatal-infos || true

# Run tests (non-blocking)
echo "🧪 Running tests..."
flutter test || echo "⚠️  Some tests failed (continuing)"

# Run app
echo ""
echo "🚀 Starting app on $DEVICE..."
echo "💡 Press 'r' for hot reload, 'R' for hot restart, 'q' to quit"
echo ""

flutter run -d "$DEVICE"

