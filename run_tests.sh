#!/bin/bash

echo "🧪 NaijaSingles Automated Testing"
echo "================================="

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run the integration tests
echo "🚀 Running automated tests..."
flutter test integration_test/app_test.dart -d chrome --verbose

echo "✅ Tests completed!"
