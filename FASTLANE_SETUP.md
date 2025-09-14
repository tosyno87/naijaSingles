# Fastlane Setup Guide for NaijaSingles

This guide helps you set up and use fastlane for automated deployment of the NaijaSingles app.

## 🚀 Quick Setup

### 1. Install Dependencies
```bash
# Install Ruby (if not already installed)
brew install ruby

# Install fastlane
gem install fastlane

# Install project dependencies
bundle install
```

### 2. Configure Credentials
1. Copy `fastlane/config.example.rb` to `fastlane/config.rb`
2. Fill in your actual credentials:
   - Apple ID and Team ID
   - Google Play Console service account
   - Bundle identifiers

### 3. Verify Configuration
```bash
# Check fastlane setup
fastlane lanes

# Test iOS configuration
fastlane ios testflight --dry_run

# Test Android configuration  
fastlane android internal --dry_run
```

## 📱 Available Commands

### Global Commands
- `fastlane test_suite` - Run Flutter tests
- `fastlane screenshots` - Generate App Store screenshots
- `fastlane beta` - Deploy to beta testing
- `fastlane deploy` - Production deployment

### iOS Commands
- `fastlane ios testflight` - Deploy to TestFlight
- `fastlane ios deploy` - Deploy to App Store

### Android Commands
- `fastlane android internal` - Deploy to Internal Testing
- `fastlane android deploy` - Deploy to Play Store

## 🔧 Configuration Files

### Appfile
- **iOS Bundle ID**: `com.app.naijasingles`
- **Android Package**: `com.app.naijasingles`
- **Team ID**: `M7HY7333KT`

### Fastfile
- Platform-specific lanes for iOS and Android
- Comprehensive error handling
- Build verification and cleanup
- Detailed logging and troubleshooting

## 🛠️ Troubleshooting

### Common Issues

1. **Bundle ID Mismatch**
   - Ensure iOS and Android bundle IDs match Appfile
   - Check Info.plist and build.gradle files

2. **Code Signing Issues**
   - Verify Apple Developer account access
   - Check provisioning profiles
   - Ensure certificates are valid

3. **Google Play API Issues**
   - Verify service account JSON file
   - Check API permissions in Google Play Console
   - Ensure package name matches

4. **Build Failures**
   - Run `flutter clean` before deployment
   - Check Flutter and Dart versions
   - Verify all dependencies are installed

### Debug Commands
```bash
# Check fastlane version
fastlane --version

# List all available lanes
fastlane lanes

# Run with verbose output
fastlane ios testflight --verbose

# Dry run (test without actual deployment)
fastlane ios testflight --dry_run
```

## 📋 Pre-Deployment Checklist

- [ ] Version numbers updated in pubspec.yaml
- [ ] App tested on both iOS and Android
- [ ] Screenshots generated and tested
- [ ] App store metadata verified
- [ ] Code signing certificates valid
- [ ] Google Play Console API configured

## 🎯 Deployment Workflow

### Beta Testing
1. Run tests: `fastlane test_suite`
2. Deploy to beta: `fastlane beta`
3. Test on TestFlight and Play Console

### Production Release
1. Complete beta testing
2. Update version numbers
3. Deploy: `fastlane deploy`
4. Submit for review

## 📚 Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [iOS Deployment Guide](https://docs.fastlane.tools/getting-started/ios/)
- [Android Deployment Guide](https://docs.fastlane.tools/getting-started/android/)
- [Flutter Integration](https://docs.fastlane.tools/getting-started/flutter/)
