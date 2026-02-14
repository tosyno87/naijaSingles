# 📚 DevOps Deployment Guide - App Store Connect Testing

## 🎓 Learning Objectives

By the end of this guide, you'll understand:
1. **Git Flow Strategy** - How feature branches integrate with production
2. **Version Management** - Semantic versioning and build numbers
3. **CI/CD Pipeline** - Automated testing, building, and deployment
4. **App Store Connect** - TestFlight distribution workflow
5. **DevOps Best Practices** - Industry-standard deployment patterns

---

## 🏗️ Architecture Overview

### Your Current Setup:
```
┌─────────────────────────────────────────────────┐
│  Feature Branch: fix/critical-profile-issues   │ ← You are here
└───────────────────┬─────────────────────────────┘
                    │
                    │ PR/Merge
                    ▼
┌─────────────────────────────────────────────────┐
│  Main Branch: main                              │ ← Production code
└───────────────────┬─────────────────────────────┘
                    │
                    │ Version Tag (v1.0.1)
                    ▼
┌─────────────────────────────────────────────────┐
│  GitHub Actions CI/CD Pipeline                  │
│  ├─ Run Tests                                   │
│  ├─ Build iOS App                               │
│  └─ Upload to TestFlight                        │
└───────────────────┬─────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│  App Store Connect                              │
│  └─ TestFlight (Beta Testing)                   │
└─────────────────────────────────────────────────┘
```

---

## 📋 Step-by-Step Process

### **STEP 1: Review & Verify Current State**

**Why?** Ensure your code is ready for production. We follow the **"Shift Left"** principle - catch issues early.

**Actions:**
```bash
# Check current branch
git branch --show-current
# Expected: fix/critical-profile-issues

# Verify all changes are committed
git status
# Expected: "working tree clean"

# Review recent commits
git log --oneline -5
```

**✅ Checklist:**
- [ ] All changes committed
- [ ] No uncommitted files
- [ ] Tests pass locally (`flutter test`)
- [ ] Code reviewed (if working in team)

**Learning Point:** Always deploy from a clean state to ensure reproducibility.

---

### **STEP 2: Run Pre-Deployment Checks**

**Why?** Validate code quality before merging. This prevents broken builds in CI.

**Actions:**
```bash
# Run Flutter tests
flutter test

# Check for linting issues
flutter analyze

# Verify iOS build works locally (optional but recommended)
flutter build ios --release --no-codesign
```

**Learning Point:** Local validation reduces CI failures and speeds up feedback loops (DORA metric: MTTR - Mean Time to Recovery).

---

### **STEP 3: Merge Feature Branch to Main**

**Why?** Feature branches are for development. Main branch holds production-ready code. This follows **Git Flow** pattern.

**Option A: Create Pull Request (Recommended for Teams)**
```bash
# Push feature branch to remote
git push origin fix/critical-profile-issues

# Then create PR on GitHub:
# 1. Go to GitHub → Pull Requests → New PR
# 2. Compare: fix/critical-profile-issues → main
# 3. Review changes
# 4. Merge PR
```

**Option B: Direct Merge (For Solo Development)**
```bash
# Switch to main branch
git checkout main

# Pull latest changes (important!)
git pull origin main

# Merge feature branch
git merge fix/critical-profile-issues

# Push to remote
git push origin main
```

**Learning Point:** Git Flow separates development from production, enabling safe experimentation and rollback capabilities.

---

### **STEP 4: Bump Version Numbers**

**Why?** App Store requires unique build numbers. Semantic versioning helps track releases and rollback if needed.

**Current Version Check:**
- `pubspec.yaml`: `version: 1.0.0+1`
- Xcode: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 4`

**Version Strategy:**
```
Format: MAJOR.MINOR.PATCH+BUILD
Example: 1.0.1+5

- MAJOR (1): Breaking changes
- MINOR (0): New features (backward compatible)
- PATCH (1): Bug fixes
- BUILD (+5): Increment for each TestFlight build
```

**Actions:**
```bash
# Update pubspec.yaml
# Change: version: 1.0.0+1
# To:     version: 1.0.1+5  (increment patch + build)

# Fastlane will automatically:
# 1. Update Xcode MARKETING_VERSION to 1.0.1
# 2. Increment CURRENT_PROJECT_VERSION (4 → 5)
```

**Manual Update (if needed):**
```yaml
# pubspec.yaml
version: 1.0.1+5  # Update this
```

**Learning Point:** Semantic versioning enables:
- Clear communication of changes
- Dependency management
- Rollback strategies
- Change tracking

---

### **STEP 5: Commit Version Bump**

**Why?** Version changes should be tracked in git history.

**Actions:**
```bash
# Stage version changes
git add pubspec.yaml

# Commit with conventional commit message
git commit -m "chore: bump version to 1.0.1+5 for TestFlight release"

# Push to main
git push origin main
```

**Learning Point:** Conventional commits enable automated changelog generation and release notes.

---

### **STEP 6: Create Version Tag**

**Why?** Tags trigger automated CI/CD pipelines. They provide immutable snapshots for releases.

**Actions:**
```bash
# Create annotated tag (recommended)
git tag -a v1.0.1 -m "Release v1.0.1 - Critical profile fixes"

# Push tag to remote (triggers CI/CD)
git push origin v1.0.1
```

**What happens next:**
1. GitHub Actions detects the tag push
2. Workflow `ios_deploy.yml` automatically triggers
3. Pipeline runs: Tests → Build → Upload

**Learning Point:** Tag-based deployments enable:
- Immutable releases
- Automated rollbacks
- Clear release history
- CI/CD automation

---

### **STEP 7: Monitor CI/CD Pipeline**

**Why?** Monitoring provides visibility into deployment health. Early failure detection reduces MTTR.

**Where to Monitor:**
1. **GitHub Actions Tab:**
   ```
   GitHub → Actions → "iOS TestFlight Deploy"
   ```

2. **Pipeline Stages:**
   ```
   ✓ Checkout code
   ✓ Setup Flutter
   ✓ Install dependencies
   ✓ Setup Ruby for Fastlane
   ✓ Install CocoaPods
   ✓ Clean Flutter build
   ✓ Run tests
   ✓ Import Apple certificates
   ✓ Install provisioning profile
   ✓ Deploy to TestFlight
   ```

**What to Watch For:**
- ✅ Green checkmarks = Success
- ❌ Red X = Failure (click to see logs)
- ⏳ Yellow circle = In progress

**Learning Point:** Observability (one of the Three Ways of DevOps) enables:
- Rapid problem detection
- Performance monitoring
- Deployment metrics (DORA: Deployment Frequency)

---

### **STEP 8: Verify TestFlight Upload**

**Why?** Confirm successful upload before distributing to testers.

**Where to Check:**
1. **App Store Connect:**
   ```
   https://appstoreconnect.apple.com
   → My Apps → NaijaSingles
   → TestFlight → iOS Builds
   ```

2. **Build Processing:**
   - New build appears (may take 5-15 minutes)
   - Status: "Processing" → "Ready to Submit"
   - Once "Ready", you can distribute

**Learning Point:** TestFlight provides:
- Internal testing (up to 100 users)
- External testing (up to 10,000 users)
- Beta feedback collection
- Crash reporting

---

### **STEP 9: Distribute to TestFlight Testers**

**Why?** Get real-world testing before App Store release.

**Actions in App Store Connect:**
1. Select the build
2. Add to TestFlight group
3. Add internal testers (team members)
4. Or create external test group
5. Submit for Beta App Review (if external)

**Learning Point:** Testing in production-like environment catches:
- Device-specific issues
- Performance problems
- UX improvements
- Real-world usage patterns

---

## 🔧 Troubleshooting Common Issues

### Issue: Pipeline Fails on Tests
**Solution:**
```bash
# Run tests locally first
flutter test

# Fix failing tests
# Commit fixes
git commit -m "fix: resolve failing tests"
git push origin main
```

### Issue: Build Number Conflicts
**Solution:**
```bash
# Check current build number in Xcode
# Increment in pubspec.yaml
version: 1.0.1+6  # Was +5, now +6
```

### Issue: Code Signing Errors
**Solution:**
- Verify GitHub Secrets are set:
  - `IOS_CERTIFICATES_P12`
  - `IOS_CERTIFICATES_PASSWORD`
  - `IOS_PROVISIONING_PROFILE`
- Check certificates haven't expired
- Re-export from Keychain if needed

### Issue: CocoaPods Errors
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock build
pod install --repo-update
cd ..
git add ios/Podfile.lock
git commit -m "chore: update CocoaPods dependencies"
```

---

## 📊 DevOps Best Practices Applied

### 1. **Git Flow Pattern**
- Feature branches for development
- Main branch for production
- Tags for releases

### 2. **Semantic Versioning**
- Clear version numbering
- Trackable changes
- Rollback capability

### 3. **CI/CD Automation**
- Automated testing
- Automated building
- Automated deployment

### 4. **Infrastructure as Code**
- Fastlane configuration
- GitHub Actions workflows
- Version-controlled deployment

### 5. **Observability**
- Pipeline monitoring
- TestFlight analytics
- Crash reporting

---

## 🎯 Key Takeaways for Interviews

1. **Git Flow:** Understand branch strategies (feature → main → tag)
2. **CI/CD:** Automated pipeline reduces human error and speeds deployment
3. **Versioning:** Semantic versioning enables dependency management
4. **Observability:** Monitoring enables rapid problem detection
5. **DORA Metrics:** Deployment frequency, lead time, MTTR, change failure rate

---

## 📚 Additional Resources

- [Git Flow Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Semantic Versioning](https://semver.org/)
- [DORA Metrics](https://www.devops-research.com/research.html)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Ready to deploy?** Follow the steps above! 🚀



