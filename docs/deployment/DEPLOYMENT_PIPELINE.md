# Afropeep Deployment Pipeline Guide

## Overview

Your app has **enterprise-level CI/CD** already configured! You can deploy via:
1. **GitHub Actions** (recommended) - Automated, clean environment
2. **Local Fastlane** - Manual control
3. **Xcode** - Last resort

## Current Configuration

### ✅ What's Already Set Up

```
├── .github/workflows/
│   ├── ios_deploy.yml        # NEW: TestFlight automation
│   ├── build_and_deploy.yml  # Build automation
│   ├── flutter_tests.yml     # Test automation
│   └── code_quality.yml      # Quality checks
│
├── fastlane/
│   ├── Fastfile              # iOS/Android deployment
│   ├── Appfile               # App identifiers & credentials
│   └── README.md             # Documentation
│
└── Configuration:
    • Bundle ID: com.app.naijasingles
    • Team ID: M7HY7333KT
    • Apple ID: bbtnd_tosin@yahoo.com
```

## Quick Start: Deploy to TestFlight

### Method 1: GitHub Actions (Recommended) 🚀

**Why use this?**
- Clean environment (no Pods issues)
- Automatic
- Version controlled
- Team-friendly

**Steps:**

1. **One-time setup: Add secrets to GitHub**
   ```bash
   # Go to: https://github.com/YOUR_USERNAME/naijaSingles/settings/secrets/actions
   
   # Add these secrets:
   # - IOS_CERTIFICATES_P12 (see below)
   # - IOS_CERTIFICATES_PASSWORD
   # - IOS_PROVISIONING_PROFILE
   # - APPLE_ID: bbtnd_tosin@yahoo.com
   # - APPLE_PASSWORD (app-specific password from appleid.apple.com)
   # - APPLE_TEAM_ID: M7HY7333KT
   ```

2. **Export certificates (one-time)**
   ```bash
   # Open Keychain Access
   # Find "iPhone Distribution: ..." certificate
   # Right-click → Export → Save as .p12
   
   # Convert to base64 for GitHub secret
   base64 -i Certificates.p12 | pbcopy
   # Paste into GitHub secret: IOS_CERTIFICATES_P12
   ```

3. **Export provisioning profile (one-time)**
   ```bash
   # Download from: https://developer.apple.com/account/resources/profiles/list
   # Or find in: ~/Library/MobileDevice/Provisioning Profiles/
   
   # Convert to base64
   base64 -i profile.mobileprovision | pbcopy
   # Paste into GitHub secret: IOS_PROVISIONING_PROFILE
   ```

4. **Deploy!**
   ```bash
   # Commit your changes
   git add .
   git commit -m "Ready for TestFlight v1.0.0"
   git push
   
   # Create version tag
   git tag v1.0.0
   git push origin v1.0.0
   
   # GitHub Actions will automatically:
   # ✓ Clean install Pods (fixes your current issue!)
   # ✓ Run tests
   # ✓ Build iOS app
   # ✓ Upload to TestFlight
   ```

**Manual trigger (alternative):**
```bash
# Go to GitHub → Actions → "iOS TestFlight Deploy" → Run workflow
```

### Method 2: Local Fastlane 🔧

**When to use:** When you need immediate control or CI is down

**Steps:**

1. **Fix Pods issue** (this is what's blocking you now)
   ```bash
   cd ios
   rm -rf Pods Podfile.lock build
   pod install --repo-update
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Deploy**
   ```bash
   cd fastlane
   bundle exec fastlane ios testflight_deploy
   ```

### Method 3: Xcode 🍎

**When to use:** Last resort, or to debug specific issues

```bash
# 1. Build in Flutter
flutter build ios --release

# 2. Open Xcode
open ios/Runner.xcworkspace

# 3. In Xcode:
#    Product → Archive → Distribute App → TestFlight
```

## Deployment Workflows

### Quick Fix / Hotfix
```bash
# Fast deployment for urgent fixes
git checkout -b hotfix/critical-bug
# ... fix the bug ...
flutter test  # Ensure tests pass
git commit -m "fix: critical bug"
git push origin hotfix/critical-bug

# Create PR, merge, then:
git tag v1.0.1
git push origin v1.0.1
# GitHub Actions deploys automatically
```

### Feature Release
```bash
# Standard release process
git checkout -b feature/new-feature
# ... develop feature ...
flutter test
flutter test integration_test/
git commit -m "feat: new feature"
git push origin feature/new-feature

# Create PR, get reviewed, merge to main
# Then tag and deploy
git checkout main
git pull
git tag v1.1.0
git push origin v1.1.0
```

### Production Release
```bash
# 1. Update version
# Edit pubspec.yaml: version: 1.0.0+1

# 2. Full test suite
flutter test
flutter test integration_test/
flutter analyze

# 3. Tag and push
git tag v1.0.0 -a -m "Release v1.0.0"
git push origin v1.0.0

# 4. GitHub Actions builds and uploads to TestFlight

# 5. Test on TestFlight

# 6. Submit for App Store review manually in App Store Connect
```

## Fixing Your Current Issue

The **"Pods Manifest.lock sync"** error happens when:
- Xcode build cache is stale
- Podfile.lock is out of sync
- DerivedData is corrupted

### Solution Options

**Option A: Use GitHub Actions (easiest)**
```bash
# Push to GitHub and let CI handle it
git add .github/workflows/ios_deploy.yml
git commit -m "Add iOS deployment workflow"
git push

# Trigger deployment
git tag v1.0.0
git push origin v1.0.0
```

**Option B: Clean rebuild locally**
```bash
# Complete clean
cd ios
rm -rf Pods Podfile.lock build
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter pub get

# Try deployment again
cd fastlane
bundle exec fastlane ios testflight_deploy
```

**Option C: Use Xcode directly**
```bash
# Sometimes Xcode handles Pods better
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace

# In Xcode:
# 1. Product → Clean Build Folder (Cmd+Shift+K)
# 2. Close Xcode
# 3. Open again: open ios/Runner.xcworkspace
# 4. Product → Archive
```

## Monitoring & Debugging

### Check Build Status
```bash
# GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/naijaSingles/actions

# Fastlane logs
tail -f ~/Library/Logs/gym/Runner-Runner.log

# Xcode logs
# Window → Devices and Simulators → View Device Logs
```

### Common Issues

#### 1. Code Signing Failed
```bash
# Verify certificates
security find-identity -v -p codesigning

# Check provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Re-download from Apple Developer Portal
```

#### 2. Upload Failed
```bash
# Check App Store Connect status
open https://developer.apple.com/system-status/

# Verify Apple ID credentials
# Generate new app-specific password if needed
open https://appleid.apple.com/account/manage
```

#### 3. Build Timeout
```bash
# Increase timeout in workflow
# Edit .github/workflows/ios_deploy.yml
# Add: timeout-minutes: 60
```

## Best Practices

### 1. Version Management
```yaml
# pubspec.yaml
version: MAJOR.MINOR.PATCH+BUILD
version: 1.0.0+1    # First release
version: 1.0.1+2    # Bug fix
version: 1.1.0+3    # New feature
version: 2.0.0+4    # Breaking change
```

### 2. Git Tagging
```bash
# Always annotate tags
git tag -a v1.0.0 -m "Release notes here"

# Push tags explicitly
git push origin v1.0.0

# List tags
git tag -l
```

### 3. Testing Before Deploy
```bash
# Run full test suite
flutter test --coverage
flutter test integration_test/
flutter analyze

# Build locally first
flutter build ios --release
flutter build appbundle --release
```

### 4. Monitoring
```bash
# After deployment, monitor:
# 1. Crash reports in Firebase Crashlytics
# 2. User feedback in App Store Connect
# 3. Performance metrics in Firebase Performance
# 4. Usage analytics in Firebase Analytics
```

## Rollback Strategy

If something goes wrong:

```bash
# 1. Quick fix and redeploy
git revert <bad-commit>
git push
git tag v1.0.2
git push origin v1.0.2

# 2. Or revert to previous version
# In App Store Connect:
# App Store → Versions → Previous version → Submit for Review
```

## Next Steps

### Immediate (Deploy now)
```bash
# Fix current issue using GitHub Actions
git add .github/workflows/ios_deploy.yml DEPLOYMENT_PIPELINE.md
git commit -m "Add iOS deployment pipeline"
git push

# Set up GitHub secrets (see above)

# Deploy!
git tag v1.0.0
git push origin v1.0.0
```

### Soon (Improve pipeline)
1. Add Android deployment workflow
2. Set up Fastlane Match for certificate management
3. Add automated screenshot generation
4. Set up staging environment
5. Add deployment notifications (Slack/Discord)

### Later (Advanced)
1. Implement blue-green deployments
2. Add A/B testing via Firebase
3. Set up feature flags
4. Add automatic rollback on errors
5. Implement phased rollout

## Support

**Documentation:**
- Fastlane: https://docs.fastlane.tools/
- GitHub Actions: https://docs.github.com/actions
- App Store Connect: https://developer.apple.com/help/app-store-connect/

**Your config files:**
- `.github/workflows/ios_deploy.yml` - Deployment automation
- `fastlane/Fastfile` - Deployment lanes
- `fastlane/Appfile` - App configuration
- `ios/Runner.xcodeproj` - Xcode project

**Quick commands:**
```bash
# Status check
flutter doctor -v
pod --version
fastlane --version

# Clean everything
flutter clean
cd ios && rm -rf Pods Podfile.lock build && cd ..

# Rebuild
flutter pub get
cd ios && pod install && cd ..

# Deploy
cd fastlane && bundle exec fastlane ios testflight_deploy
```

---

**✨ Key Takeaway:** Use GitHub Actions for deployment. It provides a clean environment and avoids the Pods sync issue you're facing locally.

