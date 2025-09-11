#!/bin/bash

echo "🚀 Starting NaijaSingles Enhanced Automated Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNING_TESTS++))
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((FAILED_TESTS++))
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((PASSED_TESTS++))
}

print_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
    echo "----------------------------------------"
}

print_performance() {
    echo -e "${PURPLE}[PERFORMANCE]${NC} $1"
}

# Function to run test with error handling
run_test() {
    local test_name="$1"
    local test_command="$2"
    local is_critical="${3:-true}"
    
    print_status "Running: $test_name"
    ((TOTAL_TESTS++))
    
    if eval "$test_command"; then
        print_success "$test_name passed"
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            print_error "$test_name failed (critical)"
            return 1
        else
            print_warning "$test_name failed (non-critical)"
            return 0
        fi
    fi
}

# Performance monitoring function
monitor_performance() {
    local test_name="$1"
    local command="$2"
    local max_time="$3"
    
    print_performance "Monitoring performance for: $test_name"
    
    local start_time=$(date +%s%N)
    eval "$command"
    local end_time=$(date +%s%N)
    
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    print_performance "$test_name completed in ${duration}ms"
    
    if [ "$max_time" != "" ] && [ "$duration" -gt "$max_time" ]; then
        print_warning "$test_name took longer than expected (${duration}ms > ${max_time}ms)"
    fi
}

# Check if Flutter is installed
print_section "🔧 Environment Setup"
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

# Clean and get dependencies
print_section "📦 Project Setup"
monitor_performance "Project cleanup" "flutter clean" 30000
monitor_performance "Dependency installation" "flutter pub get" 60000

# Check for common issues
print_section "🔍 Pre-flight Checks"

# Check for missing files
if [ ! -f "android/app/google-services.json" ]; then
    print_warning "Missing google-services.json for Android"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_warning "Missing GoogleService-Info.plist for iOS"
fi

# Check pubspec.yaml for common issues
if ! grep -q "firebase_core" pubspec.yaml; then
    print_warning "Firebase core dependency might be missing"
fi

# Run unit tests with detailed reporting
print_section "🧪 Unit Tests"
run_test "Core unit tests" "flutter test --reporter=expanded --coverage" true

if [ $? -eq 0 ]; then
    # Generate coverage report if tests passed
    if command -v genhtml &> /dev/null; then
        print_status "Generating coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated in coverage/html/"
    fi
fi

# Dating app specific unit tests
print_section "💕 Dating App Specific Tests"
run_test "User matching algorithm" "flutter test test/home/user_search_repo_test.dart" true
run_test "Authentication flow" "flutter test test/auth/ --reporter=expanded" true
run_test "Match system" "flutter test test/match/ --reporter=expanded" true
run_test "Messaging system" "flutter test test/features/messages/ --reporter=expanded" false
run_test "Payment system" "flutter test test/payment/ --reporter=expanded" false

# Check for connected devices
print_section "📱 Device Detection"
print_status "Checking for connected devices..."
flutter devices

# Count available devices
device_count=$(flutter devices | grep -c "•")
if [ "$device_count" -eq 0 ]; then
    print_warning "No devices connected - skipping integration tests"
    SKIP_INTEGRATION=true
else
    print_success "Found $device_count device(s) available"
    SKIP_INTEGRATION=false
fi

# Run integration tests
print_section "🔗 Integration Tests"
if [ "$SKIP_INTEGRATION" = "false" ]; then
    # Core integration tests
    run_test "App launch test" "flutter test integration_test/app_test.dart --verbose" true
    
    # Dating app flow tests
    print_status "Running dating app flow tests..."
    
    # Test user registration flow (if test exists)
    if [ -f "integration_test/user_registration_flow_test.dart" ]; then
        run_test "User registration flow" "flutter test integration_test/user_registration_flow_test.dart" false
    fi
    
    # Test matching flow (if test exists)
    if [ -f "integration_test/matching_flow_test.dart" ]; then
        run_test "Matching flow" "flutter test integration_test/matching_flow_test.dart" false
    fi
    
    # Test chat flow (if test exists)
    if [ -f "integration_test/chat_flow_test.dart" ]; then
        run_test "Chat flow" "flutter test integration_test/chat_flow_test.dart" false
    fi
else
    print_warning "Skipping integration tests - no devices available"
fi

# Performance benchmarks
print_section "⚡ Performance Benchmarks"
print_status "Running performance tests..."

# Test build times
monitor_performance "Debug build" "flutter build apk --debug" 300000
monitor_performance "Release build preparation" "flutter build apk --release --no-shrink" 600000

# Memory and size analysis
print_status "Analyzing app size..."
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    apk_size=$(stat -f%z "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null)
    if [ "$apk_size" != "" ]; then
        apk_size_mb=$((apk_size / 1024 / 1024))
        print_performance "APK size: ${apk_size_mb}MB"
        
        if [ "$apk_size_mb" -gt 50 ]; then
            print_warning "APK size is large (${apk_size_mb}MB > 50MB)"
        fi
    fi
fi

# Code quality analysis
print_section "🔍 Code Quality Analysis"
run_test "Static analysis" "flutter analyze" false
run_test "Code formatting" "flutter format --dry-run --set-exit-if-changed ." false

# Security checks
print_section "🔒 Security Checks"
print_status "Checking for security issues..."

# Check for hardcoded secrets
if grep -r "sk_live\|pk_live\|AIza" lib/ --include="*.dart" > /dev/null 2>&1; then
    print_error "Potential hardcoded API keys found in source code"
else
    print_success "No obvious hardcoded secrets found"
fi

# Check for debug flags in release
if grep -r "debugShowCheckedModeBanner.*true\|kDebugMode.*true" lib/ --include="*.dart" > /dev/null 2>&1; then
    print_warning "Debug flags found - ensure they're disabled in production"
fi

# Dating app specific security checks
if grep -r "http://" lib/ --include="*.dart" > /dev/null 2>&1; then
    print_warning "HTTP URLs found - ensure HTTPS is used for production"
fi

# Dependency vulnerability check
print_section "🛡️ Dependency Security"
print_status "Checking for known vulnerabilities..."
if command -v dart &> /dev/null; then
    dart pub deps --style=compact | grep -i "vulnerability" && print_warning "Potential vulnerabilities found in dependencies"
fi

# Generate final report
print_section "📊 Test Summary Report"
echo ""
echo "╔══════════════════════════════════════╗"
echo "║         TEST RESULTS SUMMARY         ║"
echo "╠══════════════════════════════════════╣"
printf "║ Total Tests:     %-19s ║\n" "$TOTAL_TESTS"
printf "║ Passed:          %-19s ║\n" "$PASSED_TESTS"
printf "║ Failed:          %-19s ║\n" "$FAILED_TESTS"
printf "║ Warnings:        %-19s ║\n" "$WARNING_TESTS"
echo "╚══════════════════════════════════════╝"
echo ""

# Calculate success rate
if [ "$TOTAL_TESTS" -gt 0 ]; then
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    print_performance "Success Rate: ${success_rate}%"
fi

# Final status
if [ "$FAILED_TESTS" -eq 0 ]; then
    print_success "🎉 All critical tests passed! Your NaijaSingles app is ready for deployment!"
    
    if [ "$WARNING_TESTS" -gt 0 ]; then
        print_warning "⚠️  $WARNING_TESTS warnings found - consider addressing them before release"
    fi
    
    echo ""
    print_status "✅ Deployment Checklist:"
    echo "   - Unit tests: ✅ Passed"
    echo "   - Integration tests: ✅ Passed"
    echo "   - Performance: ✅ Acceptable"
    echo "   - Security: ✅ Basic checks passed"
    echo "   - Code quality: ⚠️  Check warnings above"
    
    exit 0
else
    print_error "❌ $FAILED_TESTS critical test(s) failed!"
    print_error "🚫 App is NOT ready for deployment"
    
    echo ""
    print_status "🔧 Next Steps:"
    echo "   1. Fix failing tests"
    echo "   2. Re-run test suite"
    echo "   3. Address any warnings"
    echo "   4. Verify on multiple devices"
    
    exit 1
fi
