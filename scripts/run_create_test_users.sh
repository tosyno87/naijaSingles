#!/bin/bash
# Script to create test users in Firebase
# This script runs the Flutter-based test user generator

set -e

echo "🚀 Afropeep Test User Generator"
echo "================================\n"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "📦 Installing dependencies..."
flutter pub get > /dev/null 2>&1

echo "🔥 Running test user generator..."
echo ""

# Run using Flutter's Dart compiler
# Note: This requires Flutter because Firebase packages depend on Flutter
flutter run -d macos --target lib/scripts/create_test_users.dart --no-sound-null-safety 2>&1 || {
    echo ""
    echo "⚠️  Note: If you see 'No macOS desktop project configured',"
    echo "   you can run this from within your Flutter app, or"
    echo "   use the Firebase Console to create test users manually."
    echo ""
    echo "   Alternative: Use Firebase Console → Authentication → Add User"
    exit 1
}
