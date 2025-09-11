#!/bin/bash

echo "🚀 Starting NaijaSingles Automated Tests..."

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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean and get dependencies
print_status "Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# Run unit tests
print_status "Running unit tests..."
flutter test --reporter=expanded

if [ $? -ne 0 ]; then
    print_error "Unit tests failed!"
    exit 1
fi

# Check for connected devices
print_status "Checking for connected devices..."
flutter devices

# Run integration tests on connected device/emulator
print_status "Running integration tests..."
flutter test integration_test/app_test.dart --verbose

if [ $? -ne 0 ]; then
    print_error "Integration tests failed!"
    exit 1
fi

# Run code analysis
print_status "Running code analysis..."
flutter analyze

if [ $? -ne 0 ]; then
    print_warning "Code analysis found issues (not blocking)"
fi

# Check for formatting issues
print_status "Checking code formatting..."
flutter format --dry-run --set-exit-if-changed .

if [ $? -ne 0 ]; then
    print_warning "Code formatting issues found (not blocking)"
fi

print_status "✅ All tests completed successfully!"
print_status "📊 Test Summary:"
echo "   - Unit tests: ✅ Passed"
echo "   - Integration tests: ✅ Passed"
echo "   - Code analysis: ⚠️  Check warnings above"
echo "   - Code formatting: ⚠️  Check warnings above"

echo ""
print_status "🎉 Your NaijaSingles app is ready for testing!"
