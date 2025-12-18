# NaijaSingles Security & Setup Guide

## 🔒 Security Improvements Implemented

This document outlines the comprehensive security and configuration improvements made to the NaijaSingles Flutter application.

## 📋 Table of Contents

1. [Environment Configuration](#environment-configuration)
2. [Security Measures](#security-measures)
3. [Code Quality & Linting](#code-quality--linting)
4. [Cloud Functions Architecture](#cloud-functions-architecture)
5. [CI/CD Quality Gates](#cicd-quality-gates)
6. [Setup Instructions](#setup-instructions)
7. [Development Guidelines](#development-guidelines)
8. [Deployment Process](#deployment-process)

## 🌍 Environment Configuration

### Secure Configuration Management

All sensitive configuration values have been moved from hardcoded strings to environment variables:

- **Firebase API Keys** - No longer committed to source code
- **Project IDs** - Loaded from environment variables
- **Storage Buckets** - Secured configuration
- **Google Maps API Keys** - Environment-based configuration

### Setup Environment Variables

1. Copy the example environment file:
   ```bash
   cp env.example .env
   ```

2. Fill in your actual values in `.env`:
   ```bash
   # Firebase Configuration
   FIREBASE_WEB_API_KEY=your_actual_web_api_key
   FIREBASE_ANDROID_API_KEY=your_actual_android_api_key
   FIREBASE_IOS_API_KEY=your_actual_ios_api_key
   FIREBASE_PROJECT_ID=your_actual_project_id
   FIREBASE_MESSAGING_SENDER_ID=your_actual_sender_id
   FIREBASE_STORAGE_BUCKET=your_actual_storage_bucket
   FIREBASE_AUTH_DOMAIN=your_actual_auth_domain
   FIREBASE_IOS_CLIENT_ID=your_actual_ios_client_id
   FIREBASE_IOS_BUNDLE_ID=your_actual_ios_bundle_id
   
   # Optional
   GOOGLE_MAPS_API_KEY=your_actual_maps_api_key
   APP_ENVIRONMENT=development
   ```

3. **Never commit the `.env` file** - It's already in `.gitignore`

### Secure Configuration Usage

The app now uses `SecureConfig` class to load configuration:

```dart
// Before (INSECURE)
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
  // ... hardcoded values
);

// After (SECURE)
static FirebaseOptions get web => FirebaseOptions(
  apiKey: SecureConfig.firebaseWebApiKey,
  // ... loaded from environment
);
```

## 🔐 Security Measures

### 1. Secrets Protection
- ✅ All API keys moved to environment variables
- ✅ `.env` file excluded from version control
- ✅ Example configuration provided (`env.example`)
- ✅ Validation of required environment variables

### 2. Git Security
- ✅ Updated `.gitignore` to exclude sensitive files
- ✅ Added `node_modules/` to `.gitignore`
- ✅ Excluded generated files and build artifacts
- ✅ Protected against accidental secret commits

### 3. Static Analysis Security
- ✅ Strengthened linting rules for security best practices
- ✅ Added error handling rules
- ✅ Enabled security-focused lint rules
- ✅ Balanced strictness for CI compatibility

## 🎯 Code Quality & Linting

### Enhanced Analysis Configuration

The `analysis_options.yaml` now includes:

- **Security Rules**: Prevent common security vulnerabilities
- **Error Handling**: Enforce proper error handling patterns
- **Code Consistency**: Maintain consistent code style
- **Performance Rules**: Optimize for better performance
- **CI-Friendly**: Balanced strictness to prevent CI failures

### Key Linting Rules Enabled

```yaml
# Security & Best Practices
avoid_print: true
avoid_web_libraries_in_flutter: true
avoid_catches_without_on_clauses: true
avoid_catching_errors: true
avoid_returning_null_for_future: true

# Code Quality
prefer_const_constructors: true
prefer_final_fields: true
prefer_single_quotes: true
require_trailing_commas: true

# Performance
prefer_for_elements_to_map_fromIterable: true
prefer_spread_collections: true
prefer_contains: true
```

### Running Analysis

```bash
# Check code quality
flutter analyze

# Fix formatting issues
dart format .

# Check for security issues
flutter analyze --no-fatal-infos
```

## 🏗️ Cloud Functions Architecture

### TypeScript Implementation

The Firebase Cloud Functions have been completely refactored:

- **Modular Structure**: Separated into logical handlers
- **Type Safety**: Full TypeScript implementation
- **Error Handling**: Comprehensive error logging and monitoring
- **Testing**: Unit tests for all services
- **Documentation**: Well-documented code with JSDoc

### New Structure

```
functions/
├── src/
│   ├── types/
│   │   └── index.ts              # Type definitions
│   ├── services/
│   │   ├── notificationService.ts # Notification logic
│   │   ├── userService.ts        # User operations
│   │   └── __tests__/            # Service tests
│   ├── handlers/
│   │   ├── matchHandlers.ts      # Match-related functions
│   │   ├── messageHandlers.ts    # Message-related functions
│   │   └── likeHandlers.ts       # Like-related functions
│   └── index.ts                  # Main exports
├── package.json                  # Dependencies & scripts
├── tsconfig.json                 # TypeScript configuration
└── .eslintrc.js                  # ESLint configuration
```

### Key Improvements

1. **Type Safety**: All functions now have proper TypeScript types
2. **Error Handling**: Comprehensive error logging to Firestore
3. **Modularity**: Each feature has its own handler
4. **Testing**: Unit tests for all services
5. **Monitoring**: Error logs for debugging and monitoring

### Running Cloud Functions

```bash
# Install dependencies
cd functions
npm install

# Build TypeScript
npm run build

# Run tests
npm test

# Deploy functions
npm run deploy

# Run locally
npm run serve
```

## 🚀 CI/CD Quality Gates

### Automated Quality Checks

New GitHub Actions workflow (`.github/workflows/quality_gates.yml`) includes:

1. **Code Quality Analysis**
   - Static analysis with Flutter analyze
   - Code formatting checks
   - Security pattern detection

2. **Security Analysis**
   - Secret detection in code
   - Environment configuration validation
   - Dependency vulnerability checks

3. **Unit Tests & Coverage**
   - Automated test execution
   - Coverage reporting (70% threshold)
   - Codecov integration

4. **Build Validation**
   - Android APK build verification
   - Artifact upload for testing

### Quality Gate Requirements

All checks must pass before code can be merged:

- ✅ Code quality analysis passes
- ✅ No secrets detected in code
- ✅ Unit tests pass with >70% coverage
- ✅ Build validation successful
- ✅ Security analysis clean

### Running Quality Gates Locally

```bash
# Run all quality checks
flutter analyze
dart format --set-exit-if-changed .
flutter test --coverage
flutter build apk --release

# Check for secrets
grep -r "AIza[0-9A-Za-z_-]" lib/ || echo "No API keys found"
```

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK 3.32.3 or higher
- Node.js 18 or higher (for Cloud Functions)
- Firebase CLI
- Git

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd naijaSingles
   ```

2. **Setup environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your actual values
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Setup Cloud Functions**
   ```bash
   cd functions
   npm install
   npm run build
   ```

5. **Initialize Firebase**
   ```bash
   firebase login
   firebase use your-project-id
   ```

### Development Workflow

1. **Start development**
   ```bash
   # Terminal 1: Run app
   flutter run
   
   # Terminal 2: Run Firebase emulators
   firebase emulators:start
   ```

2. **Run tests**
   ```bash
   # Flutter tests
   flutter test
   
   # Cloud Functions tests
   cd functions && npm test
   ```

3. **Code quality checks**
   ```bash
   flutter analyze
   dart format .
   ```

## 📝 Development Guidelines

### State Management Standardization

**Recommended Pattern**: BLoC (Business Logic Component)

```dart
// Feature-based folder structure
lib/features/
├── auth/
│   ├── bloc/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   ├── models/
│   └── screens/
├── profile/
│   ├── bloc/
│   ├── models/
│   └── screens/
```

### Code Standards

1. **File Organization**
   - Feature-based folder structure
   - Separate BLoC files for events, states, and logic
   - Consistent naming conventions

2. **Error Handling**
   ```dart
   try {
     final result = await someAsyncOperation();
     emit(SuccessState(result));
   } catch (e) {
     emit(ErrorState(e.toString()));
   }
   ```

3. **Security Best Practices**
   - Never hardcode API keys
   - Use SecureConfig for all configuration
   - Validate user inputs
   - Handle errors gracefully

### Testing Guidelines

1. **Unit Tests**
   - Test all BLoC logic
   - Mock external dependencies
   - Aim for >70% coverage

2. **Integration Tests**
   - Test complete user flows
   - Test Firebase integration
   - Test authentication flows

## 🚀 Deployment Process

### Pre-deployment Checklist

- [ ] All tests passing
- [ ] Code quality checks pass
- [ ] Security analysis clean
- [ ] Environment variables configured
- [ ] Cloud Functions built and tested

### Deployment Steps

1. **Update version numbers**
   ```bash
   # Update pubspec.yaml version
   version: 1.0.1+2
   ```

2. **Build and test**
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

3. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm run deploy
   ```

4. **Deploy to app stores**
   ```bash
   # Using Fastlane (if configured)
   fastlane android deploy
   fastlane ios deploy
   ```

### Monitoring & Maintenance

1. **Monitor error logs**
   - Check Firebase Console for Cloud Function errors
   - Monitor app crashes with Crashlytics
   - Review notification delivery rates

2. **Regular security updates**
   - Update dependencies regularly
   - Review and rotate API keys
   - Audit Firestore security rules

3. **Performance monitoring**
   - Monitor app performance metrics
   - Track user engagement
   - Optimize based on analytics

## 🔍 Troubleshooting

### Common Issues

1. **Environment Configuration**
   ```bash
   # Error: Missing environment variables
   # Solution: Ensure .env file exists and is properly configured
   ```

2. **Cloud Functions Deployment**
   ```bash
   # Error: TypeScript compilation errors
   # Solution: Run npm run build in functions directory
   ```

3. **Linting Errors**
   ```bash
   # Error: Too many linting issues
   # Solution: Run dart format . and fix remaining issues
   ```

### Getting Help

- Check the logs in Firebase Console
- Review the CI/CD pipeline results
- Consult the Flutter and Firebase documentation
- Check the error logs in Firestore `errorLogs` collection

## 📚 Additional Resources

- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Cloud Functions TypeScript Guide](https://firebase.google.com/docs/functions/typescript)

---

## ✅ Security Checklist

- [x] API keys moved to environment variables
- [x] .gitignore updated to exclude secrets
- [x] Static analysis strengthened
- [x] Cloud Functions refactored to TypeScript
- [x] CI/CD quality gates implemented
- [x] Comprehensive documentation created
- [x] Error handling improved
- [x] Testing infrastructure added

**Last Updated**: December 2024
**Version**: 1.0.0
