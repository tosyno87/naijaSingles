# 🔄 GitHub Actions Workflows for AfroPeep - Explained

## Overview

You have **multiple GitHub Actions workflows** configured. Here's what each does and when they trigger:

---

## 📋 Workflows Breakdown

### 1. **iOS TestFlight Deploy** (`ios_deploy.yml`) ⭐ **This is what runs when you create a tag**

**Triggers:**
- ✅ **Version tags** (like `v1.0.1`) - **AUTOMATIC**
- ✅ Manual trigger via GitHub UI

**What it does:**
1. ✅ **Checkout code** - Gets your code
2. ✅ **Setup Flutter** (v3.32.3)
3. ✅ **Install dependencies** (`flutter pub get`)
4. ✅ **Setup Ruby for Fastlane**
5. ✅ **Install CocoaPods** (iOS dependencies)
6. ✅ **Clean Flutter build**
7. ✅ **Run tests** (`flutter test`)
8. ✅ **Import Apple certificates** (from GitHub Secrets)
9. ✅ **Install provisioning profile** (from GitHub Secrets)
10. ✅ **Deploy to TestFlight** (via Fastlane)
    - Builds iOS app
    - Increments build number automatically
    - Uploads to TestFlight
    - Skips waiting for processing (uploads asynchronously)
    - Skips submission (doesn't submit for App Review)

**Duration:** ~15-30 minutes  
**Result:** App appears in TestFlight for beta testing

---

### 2. **Production Deployment** (`production.yml`) ⚠️ **Currently running in your screenshot**

**Triggers:**
- ✅ Pushes to `main` branch
- ✅ Pushes to `release/*` branches
- ✅ Pull requests to `main`

**What it does:**
1. ✅ **Run Tests** (on Ubuntu)
2. ✅ **Build and Deploy Production** (on macOS)
   - Creates `.env` file with production Firebase keys
   - Auto-increments build number from App Store Connect
   - Sets up code signing with Fastlane Match
   - Builds iOS app
   - **Deploys directly to App Store Connect** (not just TestFlight)
   - Uses App Store Connect API for upload

**Duration:** ~20-40 minutes  
**Result:** Build uploaded to App Store Connect (ready for App Review submission)

**Note:** This is more comprehensive and goes directly to App Store Connect (for production release).

---

### 3. **Build and Deploy** (`build_and_deploy.yml`)

**Triggers:**
- ✅ Version tags (`v*`)
- ✅ Manual trigger

**What it does:**
- Builds Android APK and AAB
- iOS build is currently skipped (commented out)
- Uploads artifacts for download

---

### 4. **Other Workflows** (Quality Checks)

- **Flutter Tests** (`flutter_tests.yml`) - Runs on every push/PR
- **Code Quality** (`code_quality.yml`) - Linting and formatting
- **Quality Gates** (`quality_gates.yml`) - Comprehensive quality checks
- **Comprehensive Tests** (`comprehensive_tests.yml`) - Full test suite
- **Feature Development** (`feature-development.yml`) - Runs on feature branches

---

## 🎯 What Happens When You Create Tag `v1.0.1`

### Immediate Actions:

1. **Tag Push Detected**
   ```
   git push origin v1.0.1
   ```

2. **Workflows Triggered:**
   - ✅ **`ios_deploy.yml`** - TestFlight deployment (PRIMARY)
   - ✅ **`build_and_deploy.yml`** - Android builds (if enabled)

3. **`ios_deploy.yml` Pipeline Execution:**
   ```
   Step 1: Checkout code
   Step 2: Setup Flutter 3.32.3
   Step 3: Install dependencies
   Step 4: Setup Ruby & Fastlane
   Step 5: Install CocoaPods
   Step 6: Clean build
   Step 7: Run tests (flutter test)
   Step 8: Import certificates (from GitHub Secrets)
   Step 9: Install provisioning profile
   Step 10: Fastlane ios testflight_deploy
      ├─ Clean Flutter project
      ├─ Increment build number (automatically)
      ├─ Build iOS app (Release, App Store signing)
      └─ Upload to TestFlight
   ```

4. **Fastlane `testflight_deploy` Lane:**
   - Cleans Flutter project
   - Increments build number in Xcode project
   - Builds iOS app with App Store signing
   - Uploads IPA to TestFlight
   - **Does NOT wait** for processing (asynchronous)
   - **Does NOT submit** for App Review (just uploads)

---

## ⏱️ Timeline

```
Time 0:00 - Tag pushed
Time 0:02 - Workflow starts
Time 0:05 - Setup complete
Time 0:10 - Dependencies installed
Time 0:15 - Tests pass
Time 0:20 - Build starts
Time 0:25 - Build complete
Time 0:30 - Upload starts
Time 0:35 - Upload complete ✅

Then:
+5-15 min - Build appears in App Store Connect (processing)
+15-30 min - Build ready in TestFlight
```

---

## 🔍 What You'll See

### In GitHub Actions:
```
✅ All checks passing
✅ iOS TestFlight Deploy workflow running
✅ Steps completing one by one
✅ "Deploy to TestFlight" step shows upload progress
```

### In App Store Connect:
```
1. Build appears with "Processing" status (5-15 min)
2. Status changes to "Ready to Submit"
3. Build available in TestFlight
4. Can distribute to testers
```

---

## 🎓 Key Differences: `ios_deploy.yml` vs `production.yml`

| Feature | `ios_deploy.yml` | `production.yml` |
|---------|------------------|------------------|
| **Trigger** | Version tags (`v*`) | Pushes to `main` |
| **Purpose** | TestFlight (beta) | Production release |
| **Build Number** | Auto-incremented by Fastlane | Fetched from App Store Connect API |
| **Code Signing** | Uses GitHub Secrets (P12) | Uses Fastlane Match (best practice) |
| **Upload Target** | TestFlight only | App Store Connect (can submit for review) |
| **Complexity** | Simpler, faster | More comprehensive |
| **Use Case** | Beta testing | Production release |

---

## 💡 Why Two Workflows?

**`ios_deploy.yml` (Tag-triggered):**
- ✅ Simpler and faster
- ✅ Perfect for TestFlight beta releases
- ✅ Triggers on version tags (controlled releases)

**`production.yml` (Main branch-triggered):**
- ✅ More robust (uses Fastlane Match)
- ✅ Auto-increments from App Store Connect
- ✅ Can submit for App Review
- ✅ Better for production releases

---

## 🚀 Best Practice Workflow

**For TestFlight (Beta Testing):**
1. Merge PR to `main`
2. Create version tag (`v1.0.1`)
3. `ios_deploy.yml` triggers automatically
4. App uploads to TestFlight
5. Distribute to testers

**For Production (App Store):**
1. Merge PR to `main`
2. `production.yml` triggers automatically
3. App uploads to App Store Connect
4. Manually submit for App Review in App Store Connect

---

## 📊 Current Status

**What's Running Now:**
- `production.yml` - "Build and Deploy Production" job
- This was triggered by the merge to `main` branch
- It's deploying to App Store Connect (not just TestFlight)

**What Will Happen When I Create Tag:**
- `ios_deploy.yml` - "iOS TestFlight Deploy" will trigger
- This will be a separate deployment specifically for TestFlight
- It will run in parallel or after the current production build completes

---

## ✅ Next Steps

After I create the tag `v1.0.1`:

1. ✅ **`ios_deploy.yml` workflow triggers automatically**
2. ✅ **Runs all steps** (tests, build, upload)
3. ✅ **Uploads to TestFlight** (via Fastlane)
4. ✅ **Build appears in App Store Connect** (5-15 min processing)
5. ✅ **Ready for TestFlight distribution**

**Monitoring:**
- Watch workflow: https://github.com/tosyno87/naijaSingles/actions
- Check TestFlight: https://appstoreconnect.apple.com → TestFlight

---

**Ready to create the tag?** Let me know and I'll do it! 🚀



