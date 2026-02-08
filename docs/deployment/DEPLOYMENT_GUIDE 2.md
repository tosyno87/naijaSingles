# 🚀 NaijaSingles Deployment Guide

## 🎯 **Overview**

This guide covers the complete deployment pipeline for NaijaSingles - the African diaspora dating app. The deployment process integrates comprehensive testing, automated CI/CD, and multi-platform deployment using Fastlane.

---

## 🛠 **Prerequisites**

### **Required Tools**
```bash
# Install Fastlane
gem install fastlane

# Install Flutter (if not already installed)
# https://docs.flutter.dev/get-started/install

# Verify installation
fastlane --version
flutter --version
```

### **Required Accounts**
- ✅ **Apple Developer Account** (for iOS)
- ✅ **Google Play Console Account** (for Android)
- ✅ **GitHub Account** (for CI/CD)

---

## 🔧 **Setup Instructions**

### **1. iOS Setup**

#### **App Store Connect**
1. Create app in App Store Connect
2. Set bundle identifier: `com.naijasingles.app`
3. Configure app metadata for African diaspora market

#### **Fastlane iOS Setup**
```bash
# Navigate to iOS directory
cd ios

# Initialize Fastlane (if not already done)
fastlane init

# Configure Appfile with your details
# Update team_id in fastlane/Fastfile
```

#### **Required Environment Variables**
```bash
# Add to GitHub Secrets or .env file
FASTLANE_APPLE_ID="your-apple-id@example.com"
FASTLANE_PASSWORD="your-apple-password"
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"
```

### **2. Android Setup**

#### **Google Play Console**
1. Create app in Google Play Console
2. Set package name: `com.naijasingles.app`
3. Configure app metadata for African diaspora market

#### **Fastlane Android Setup**
```bash
# Navigate to Android directory
cd android

# Initialize Fastlane (if not already done)
fastlane init

# Configure Appfile with your details
```

#### **Required Environment Variables**
```bash
# Add to GitHub Secrets or .env file
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="path/to/service-account.json"
```

---

## 🚀 **Deployment Commands**

### **Testing Commands**
```bash
# Run comprehensive test suite
fastlane test

# Run specific test categories
flutter test test/cultural/          # Cultural sensitivity tests
flutter test test/security/          # Security & privacy tests
flutter test test/performance/       # Performance tests
flutter test test/accessibility/     # Accessibility tests
```

### **Beta Deployment**
```bash
# Deploy to both TestFlight and Google Play Internal Testing
fastlane beta

# Deploy to iOS TestFlight only
fastlane ios testflight

# Deploy to Android Internal Testing only
fastlane android internal_testing
```

### **Production Deployment**
```bash
# Deploy to both App Store and Google Play Store
fastlane deploy

# Deploy to iOS App Store only
fastlane ios deploy

# Deploy to Android Google Play Store only
fastlane android deploy
```

---

## 🔄 **Automated CI/CD Pipeline**

### **GitHub Actions Integration**

The CI/CD pipeline automatically:

1. **Runs Tests** (119+ tests across 7 categories)
   - Unit Tests (50+ tests)
   - Integration Tests (25+ tests)
   - Cultural Sensitivity Tests (10 tests)
   - Security & Privacy Tests (12 tests)
   - Performance Tests (10 tests)
   - Accessibility Tests (12 tests)

2. **Builds Apps**
   - iOS build for TestFlight/App Store
   - Android build for Internal Testing/Play Store

3. **Deploys to Beta** (when tests pass)
   - Uploads to TestFlight
   - Uploads to Google Play Internal Testing

### **Pipeline Triggers**
- ✅ **Push to main**: Runs tests + deploys to beta
- ✅ **Pull Request**: Runs tests only
- ✅ **Daily Schedule**: Runs tests at 2 AM UTC
- ✅ **Manual Trigger**: Available via GitHub Actions

---

## 📱 **Platform-Specific Deployment**

### **iOS Deployment**

#### **TestFlight Deployment**
```bash
fastlane ios testflight
```

**What happens:**
1. Increments build number
2. Builds iOS app
3. Uploads to TestFlight
4. Sends notification

#### **App Store Deployment**
```bash
fastlane ios deploy
```

**What happens:**
1. Runs comprehensive tests
2. Increments build number
3. Builds iOS app
4. Uploads to App Store Connect
5. Sends notification

### **Android Deployment**

#### **Internal Testing Deployment**
```bash
fastlane android internal_testing
```

**What happens:**
1. Builds release APK
2. Uploads to Google Play Internal Testing
3. Sends notification

#### **Google Play Store Deployment**
```bash
fastlane android deploy
```

**What happens:**
1. Runs comprehensive tests
2. Builds release AAB
3. Uploads to Google Play Store
4. Sends notification

---

## 🌍 **Diaspora-Specific Deployment Considerations**

### **App Store Optimization**

#### **iOS App Store**
- **App Name**: "NaijaSingles - African Diaspora Dating"
- **Keywords**: African dating, Nigerian singles, diaspora community, cultural dating
- **Description**: Highlight cultural matching and diaspora community features
- **Screenshots**: Show diversity and cultural elements

#### **Google Play Store**
- **App Title**: "NaijaSingles - African Diaspora Dating"
- **Short Description**: "Connect with Africans in America and worldwide"
- **Keywords**: African dating, Nigerian singles, diaspora community
- **Description**: Emphasize cultural compatibility and professional networking

### **Target Markets**
- **Primary**: US (Atlanta, DC, NYC, Houston, Chicago, LA, Boston, Minneapolis)
- **Secondary**: Canada (Toronto, Vancouver, Montreal)
- **Future**: UK, France, Germany (European diaspora)

---

## 🔒 **Security & Compliance**

### **Data Protection**
- ✅ **GDPR Compliance**: European users
- ✅ **CCPA Compliance**: California users
- ✅ **PIPEDA Compliance**: Canadian users
- ✅ **Data Encryption**: At rest and in transit

### **Age Verification**
- ✅ **18+ Enforcement**: Age verification system
- ✅ **Content Moderation**: Cultural sensitivity filtering
- ✅ **Privacy Controls**: Granular user settings

---

## 📊 **Monitoring & Analytics**

### **Deployment Monitoring**
- **GitHub Actions**: Test results and deployment status
- **Fastlane**: Build and upload progress
- **App Store Connect**: iOS deployment status
- **Google Play Console**: Android deployment status

### **User Analytics**
- **Firebase Analytics**: User engagement and cultural feature usage
- **Crashlytics**: App stability and performance
- **Performance Monitoring**: Response times and scalability

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **iOS Deployment Issues**
```bash
# Certificate issues
fastlane match development
fastlane match appstore

# Provisioning profile issues
fastlane match nuke development
fastlane match nuke appstore
```

#### **Android Deployment Issues**
```bash
# Service account issues
# Verify GOOGLE_PLAY_SERVICE_ACCOUNT_JSON path
# Check service account permissions in Google Play Console

# Build issues
flutter clean
flutter pub get
flutter build apk --release
```

#### **Test Failures**
```bash
# Run tests locally
flutter test --coverage

# Check specific test categories
flutter test test/cultural/
flutter test test/security/
```

---

## 🎯 **Deployment Checklist**

### **Pre-Deployment**
- ✅ All tests passing (119+ tests)
- ✅ Cultural sensitivity validated
- ✅ Security compliance verified
- ✅ Performance benchmarks met
- ✅ Accessibility standards confirmed

### **Beta Deployment**
- ✅ TestFlight configured
- ✅ Google Play Internal Testing configured
- ✅ Beta user recruitment ready
- ✅ Feedback collection system active

### **Production Deployment**
- ✅ App Store metadata complete
- ✅ Google Play Store metadata complete
- ✅ Marketing materials ready
- ✅ Customer support prepared
- ✅ Analytics monitoring active

---

## 📞 **Support**

### **Fastlane Documentation**
- [Fastlane iOS Guide](https://docs.fastlane.tools/getting-started/ios/)
- [Fastlane Android Guide](https://docs.fastlane.tools/getting-started/android/)

### **Flutter Deployment**
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)

### **GitHub Actions**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## 🎉 **Ready to Deploy!**

Your NaijaSingles app is now ready for:

1. **Automated Testing**: 119+ comprehensive tests
2. **Beta Deployment**: TestFlight + Google Play Internal Testing
3. **Production Deployment**: App Store + Google Play Store
4. **Continuous Integration**: Automated CI/CD pipeline
5. **African Diaspora Community**: Cultural sensitivity validated

**Connect African diaspora communities worldwide! 🌍❤️**

---

**Last Updated**: September 2025
**Version**: 1.0.0
**Target Market**: African Diaspora (US & International)