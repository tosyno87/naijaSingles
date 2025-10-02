# GitHub Actions Workflows

## Available Workflows

### 1. **iOS TestFlight Deploy** (`ios_deploy.yml`)
**Purpose:** Deploy iOS app to TestFlight or App Store Connect

**Trigger:**
- Manual: Go to Actions → iOS TestFlight Deploy → Run workflow
- Automatic: Push a version tag like `v1.0.0`

**Required Secrets:**
```
IOS_CERTIFICATES_P12          # Base64 encoded .p12 certificate
IOS_CERTIFICATES_PASSWORD     # Password for .p12 certificate
IOS_PROVISIONING_PROFILE      # Base64 encoded provisioning profile
APPLE_ID                      # Your Apple ID email
APPLE_PASSWORD               # App-specific password
APPLE_TEAM_ID                # Team ID (M7HY7333KT)
APP_STORE_CONNECT_API_KEY    # Optional: API key for automation
```

**Setup Instructions:**
1. Export certificates from Keychain:
   ```bash
   # Export from Keychain Access
   # File → Export Items → Select certificate → .p12 format
   
   # Convert to base64
   base64 -i Certificates.p12 | pbcopy
   ```

2. Export provisioning profile:
   ```bash
   # Find in: ~/Library/MobileDevice/Provisioning Profiles/
   base64 -i profile.mobileprovision | pbcopy
   ```

3. Add secrets to GitHub:
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add each secret

### 2. **Build and Deploy** (`build_and_deploy.yml`)
**Purpose:** Build both iOS and Android on version tags

**Trigger:**
- Push tags like `v1.0.0`
- Manual trigger

**Features:**
- Builds Android APK and AAB
- Builds iOS archive (currently skipped due to CI compatibility)
- Uploads artifacts for download

### 3. **Flutter Tests** (`flutter_tests.yml`)
**Purpose:** Run tests on every push/PR

**Trigger:**
- Push to main/develop/feature branches
- Pull requests

### 4. **Code Quality** (`code_quality.yml`)
**Purpose:** Check code quality and standards

**Trigger:**
- Push to main/develop branches
- Pull requests

### 5. **Comprehensive Tests** (`comprehensive_tests.yml`)
**Purpose:** Full test suite with coverage

**Trigger:**
- Push to main branch
- Manual trigger

## Deployment Process

### **TestFlight Deployment (Recommended)**

#### Option A: Using GitHub Actions (Automated)
```bash
# 1. Commit and push your changes
git add .
git commit -m "Ready for TestFlight"
git push

# 2. Create a version tag
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions will automatically:
#    ✓ Run tests
#    ✓ Build iOS app
#    ✓ Upload to TestFlight
```

#### Option B: Manual Trigger
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "iOS TestFlight Deploy"
4. Click "Run workflow"
5. Choose environment (testflight/appstore)
6. Click "Run workflow" button

#### Option C: Local Fastlane (If CI fails)
```bash
# Fix Pods issue first
cd ios
rm -rf Pods Podfile.lock build
pod install --repo-update
cd ..

# Deploy via Fastlane
cd fastlane
bundle exec fastlane ios testflight_deploy
```

### **Production Deployment**

```bash
# 1. Update version in pubspec.yaml
version: 1.0.0+1

# 2. Test thoroughly
flutter test
flutter test integration_test/

# 3. Create release tag
git tag v1.0.0
git push origin v1.0.0

# 4. Manual App Store submission
#    GitHub Actions will build and upload
#    Then manually submit in App Store Connect
```

## Troubleshooting

### Pods Manifest.lock Error
```bash
cd ios
rm -rf Pods Podfile.lock build
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### Code Signing Issues
```bash
# Verify certificates in Keychain
security find-identity -v -p codesigning

# Check provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Re-export and update GitHub secrets if needed
```

### Build Fails in CI
1. Check workflow logs in GitHub Actions
2. Verify all secrets are set correctly
3. Ensure Flutter version matches local
4. Try running locally first

### TestFlight Upload Fails
1. Verify Apple ID credentials
2. Check App Store Connect API key
3. Ensure app-specific password is valid
4. Verify team ID matches Appfile

## Best Practices

1. **Always test locally first**
   ```bash
   flutter test
   flutter build ios --release
   ```

2. **Use semantic versioning**
   - v1.0.0 - Major release
   - v1.1.0 - New features
   - v1.0.1 - Bug fixes

3. **Tag releases properly**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

4. **Monitor deployments**
   - Check GitHub Actions status
   - Verify in App Store Connect
   - Test on TestFlight devices

5. **Keep secrets secure**
   - Never commit certificates
   - Use GitHub Secrets only
   - Rotate passwords regularly

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Review Fastlane output
3. Check Apple Developer Portal status
4. Verify all prerequisites are met

