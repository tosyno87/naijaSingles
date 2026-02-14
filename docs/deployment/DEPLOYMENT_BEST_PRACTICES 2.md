# NaijaSingles Deployment Best Practices

## 🚀 Standardized TestFlight Deployment Process

### **Why We Use altool Instead of Fastlane**
- ✅ **More reliable authentication** - Direct Apple tool
- ✅ **Better compatibility** with newer Xcode versions
- ✅ **Simpler error handling** - Clear success/failure messages
- ✅ **Industry standard** - Apple's official upload tool
- ✅ **Faster uploads** - No Fastlane overhead

## Pre-Deployment Checklist ✅

### 1. Environment Validation
```bash
# Check Flutter environment
flutter doctor

# Verify Xcode setup
xcodebuild -version

# Check available certificates
security find-identity -v -p codesigning
```

### 2. App Icons Validation
```bash
# Check for transparency in app icons
cd ios/Runner/Assets.xcassets/AppIcon.appiconset
for file in *.png; do
  if identify -format "%A" "$file" | grep -q "True"; then
    echo "WARNING: $file has transparency"
    convert "$file" -background white -alpha remove -alpha off "$file"
  fi
done
```

### 3. Clean Environment Setup
```bash
# Always start with clean reset
flutter clean
flutter pub get

# Handle CocoaPods compatibility issues
cd ios && pod install --repo-update
```

### 4. Code Signing Verification
```bash
# Verify correct certificate is being used
cd ios && xcodebuild -showBuildSettings -project Runner.xcodeproj -target Runner | grep -E "(CODE_SIGN_IDENTITY|DEVELOPMENT_TEAM)"
```

### 5. Authentication Setup
```bash
# Ensure .env file exists with App-Specific Password
echo "FASTLANE_USERNAME=\"bbtnd_tosin@yahoo.com\"" > .env
echo "FASTLANE_PASSWORD=\"your_app_specific_password\"" >> .env
```

## 🎯 Standardized Deployment Commands

### **Primary Method: altool Upload (Recommended)**
```bash
# Complete deployment process (with smart clean)
./scripts/deploy_testflight.sh

# Fast deployment (skip clean for quicker builds)
./scripts/deploy_testflight.sh --fast
```

### **Manual Upload (Backup Method)**
```bash
# Build and upload manually
flutter build ios --release
source .env && xcrun altool --upload-app --type ios --file "build/ios/Runner.ipa" --username "$FASTLANE_USERNAME" --password "$FASTLANE_PASSWORD"
```

## 🔧 Common Issues & Solutions

### CocoaPods Compatibility Issues
- **Symptom**: "Unable to find compatibility version string for object version `70`"
- **Solution**: Use `flutter build ios` which handles CocoaPods automatically
- **Prevention**: Always use Flutter's build process instead of direct pod install

### Code Signing Conflicts
- **Symptom**: "Runner has conflicting provisioning settings"
- **Solution**: Ensure CODE_SIGN_STYLE matches CODE_SIGN_IDENTITY
- **Fix**: Use Automatic signing with Apple Distribution certificate

### App Icon Transparency
- **Symptom**: "Invalid large app icon. The large app icon can't be transparent"
- **Solution**: Use ImageMagick to remove alpha channels
- **Prevention**: Always validate icons before deployment

### Authentication Failures
- **Symptom**: "Invalid username and password combination"
- **Solution**: Generate new App-Specific Password from Apple ID settings
- **Best Practice**: Use altool instead of Fastlane for uploads

### Fastlane Session Issues
- **Symptom**: Fastlane authentication fails but altool works
- **Solution**: Clear sessions with `rm -rf ~/.fastlane/session`
- **Alternative**: Use altool directly for uploads

## 📊 Build Management

### Current Status
- **App Version**: 1.0.0+23 (synchronized)
- **Build Number**: 23 (uploaded to TestFlight)
- **Bundle ID**: com.app.naijasingles
- **Team ID**: M7HY7333KT
- **Last Upload**: Build 23 (Delivery UUID: 6c47f305-c72b-4285-b9ef-c23415d3221e)

### Version Management Best Practices
- **Semantic Versioning**: Use MAJOR.MINOR.PATCH format (1.0.0)
- **Build Increment**: Always increment for new uploads
- **Consistency**: Keep pubspec.yaml and Info.plist in sync

## 📁 File Locations & Structure
```
├── build/ios/Runner.ipa                    # Generated IPA file
├── ios/Runner/Assets.xcassets/AppIcon.appiconset/  # App icons
├── fastlane/Fastfile                       # Fastlane configuration
├── scripts/deploy_testflight.sh            # Deployment script
├── .env                                    # Environment variables
└── DEPLOYMENT_BEST_PRACTICES.md           # This documentation
```

## 🎯 Deployment Workflow Summary

1. **Environment Check** → Verify Flutter, Xcode, certificates
2. **Clean Setup** → flutter clean, pub get, pod install
3. **Code Signing** → Verify Apple Distribution certificate
4. **Build Process** → flutter build ios --release
5. **Upload** → altool --upload-app (recommended method)
6. **Verification** → Check App Store Connect for processing status

## 📱 Post-Deployment Steps

1. **Monitor Processing** → Check App Store Connect (5-15 minutes)
2. **Add Testers** → Configure TestFlight groups
3. **Release Notes** → Add build description
4. **Distribution** → Send to internal/external testers
