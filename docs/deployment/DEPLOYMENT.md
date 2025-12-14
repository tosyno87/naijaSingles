# 🚀 Afropeep iOS Deployment Guide

This guide explains how to deploy Afropeep to the App Store efficiently.

## 📋 Prerequisites

- ✅ Apple Developer Account ($99/year)
- ✅ Xcode installed
- ✅ Flutter SDK installed
- ✅ CocoaPods installed

## 🛠️ Quick Deployment (Recommended)

### Option 1: One-Command Deployment
```bash
./scripts/deploy.sh
```

### Option 2: Step-by-Step
```bash
# 1. Build the app
./scripts/build_ios.sh

# 2. Upload to App Store Connect
./scripts/upload_ios.sh
```

## 📱 Manual Steps After Scripts

1. **Complete Upload in Xcode Organizer**
   - Select your archive
   - Click "Distribute App" → "App Store Connect" → "Upload"

2. **Submit for Review in App Store Connect**
   - Wait 5-10 minutes for processing
   - Go to App Store Connect
   - Find your new build
   - Click "Submit for Review"
   - Paste the appeal message

## 🔧 Advanced Deployment (Fastlane)

### Install Fastlane
```bash
gem install fastlane
```

### Deploy to App Store
```bash
fastlane ios deploy
```

### Deploy to TestFlight
```bash
fastlane ios testflight
```

## 📊 Version Management

### Bump Version
```bash
# Patch version (1.0.0 → 1.0.1)
./scripts/version_bump.sh patch

# Minor version (1.0.0 → 1.1.0)
./scripts/version_bump.sh minor

# Major version (1.0.0 → 2.0.0)
./scripts/version_bump.sh major
```

## 🚨 Troubleshooting

### Code Signing Issues
- **Problem**: "Failed to codesign"
- **Solution**: Use `xcodebuild` instead of `flutter build ios --release`

### Upload Failures
- **Problem**: altool authentication error
- **Solution**: Use Xcode Organizer instead

### Build Failures
- **Problem**: Pod installation errors
- **Solution**: Run `cd ios && pod install --repo-update`

## 📝 Appeal Message Template

```
🎯 ADDRESSING 4.3.0 DESIGN: SPAM CONCERNS

This app serves a unique underserved market with culturally-specific features not found in generic dating apps:

✅ CULTURAL COMMUNITY PLATFORM:
- African diaspora community hub (2.1+ million in US)
- Cultural event discovery and creation
- Community groups by country/profession/interest
- Cultural learning and language exchange programs

✅ UNIQUE FEATURES NOT AVAILABLE ELSEWHERE:
- Cultural compatibility matching based on heritage
- Family integration options for relationship approval
- Professional networking for diaspora members
- Cultural authenticity verification system
- Heritage-based connections and traditions

✅ EDUCATIONAL & COMMUNITY VALUE:
- Learn about different African cultures and languages
- Share cultural traditions and customs
- Professional mentorship within diaspora community
- Cultural event planning and celebration

✅ NAVIGATION REDESIGN:
- "Communities" tab emphasizes community over dating
- "Connect" tab for relationships (dating/friendship)
- Events-focused community building
- Cultural celebration and learning focus

This is a cultural community platform that includes relationship features, not a generic dating app. It serves the African diaspora with unique cultural features specifically designed for their community needs and values.

The app addresses a real gap in the market for culturally-aware community platforms serving the growing African diaspora population in the US.
```

## 🎯 Success Metrics

- **Build Time**: ~5-10 minutes
- **Upload Time**: ~5-10 minutes
- **Review Time**: 24-48 hours
- **Success Rate**: 30-40% for appeals

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section
2. Review Xcode console logs
3. Verify Apple Developer account status
4. Ensure all certificates are valid
