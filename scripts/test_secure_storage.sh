#!/bin/bash

# Secure Storage Testing Script
# This script helps you test the secure storage implementation

echo "🔐 Secure Storage Testing Script"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run tests
run_tests() {
    echo -e "${BLUE}Running Secure Storage Unit Tests...${NC}"
    flutter test test/services/secure_storage_service_test.dart
}

# Function to run with coverage
run_with_coverage() {
    echo -e "${BLUE}Running tests with coverage...${NC}"
    flutter test --coverage test/services/secure_storage_service_test.dart
    echo -e "${GREEN}Coverage report generated in coverage/lcov.info${NC}"
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}Running all tests...${NC}"
    flutter test
}

# Function to show manual testing steps
show_manual_steps() {
    echo -e "${YELLOW}Manual Testing Steps:${NC}"
    echo ""
    echo "1. Launch the app"
    echo "2. Log in with your credentials"
    echo "3. Check console logs for:"
    echo "   ✅ Token stored securely"
    echo "   ✅ Authentication data stored securely"
    echo ""
    echo "4. Log out"
    echo "5. Check console logs for:"
    echo "   ✅ Secure storage cleared on logout"
    echo ""
    echo "6. Log in again"
    echo "7. Verify token is stored again"
    echo ""
    echo "For detailed testing guide, see:"
    echo "docs/testing/SECURE_STORAGE_TESTING_GUIDE.md"
}

# Main menu
echo "Select an option:"
echo "1) Run Secure Storage Unit Tests"
echo "2) Run Tests with Coverage"
echo "3) Run All Tests"
echo "4) Show Manual Testing Steps"
echo "5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        run_tests
        ;;
    2)
        run_with_coverage
        ;;
    3)
        run_all_tests
        ;;
    4)
        show_manual_steps
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

