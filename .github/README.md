# GitHub Actions for NaijaSingles

This directory contains automated workflows that run tests and checks for the NaijaSingles dating app.

## 🚀 Workflows

### 1. Flutter Tests (`flutter_tests.yml`)
**Triggers:** Every push and pull request to `main` or `develop`

**What it does:**
- ✅ Runs unit tests
- ✅ Performs code analysis
- ✅ Builds iOS app (no signing)
- ✅ Runs integration tests including bio screen single selection test
- ✅ Uploads test results

### 2. Code Quality (`code_quality.yml`)
**Triggers:** Every push and pull request

**What it does:**
- ✅ Checks code formatting
- ✅ Analyzes code for issues
- ✅ Checks for unused dependencies
- ✅ Generates coverage reports
- ✅ Uploads coverage to Codecov

### 3. Build and Deploy (`build_and_deploy.yml`)
**Triggers:** Version tags (v1.0.0) or manual trigger

**What it does:**
- ✅ Builds Android APK and App Bundle
- ✅ Builds iOS app
- ✅ Uploads build artifacts
- ✅ Ready for app store deployment

### 4. Comprehensive Tests (`comprehensive_tests.yml`)
**Triggers:** Push, PR, and daily at 2 AM

**What it does:**
- ✅ Unit tests with coverage
- ✅ Integration tests on iOS simulator
- ✅ Feature-specific tests (bio screen, onboarding)
- ✅ Performance tests
- ✅ Security vulnerability checks
- ✅ Notifications on success/failure

## 📊 Test Coverage

The workflows specifically test:

### Bio Screen Single Selection ✅
- Verifies users can only select one prompt at a time
- Tests prompt selection/deselection logic
- Validates UI behavior

### Onboarding Flow ✅
- Complete user registration process
- Profile setup validation
- Navigation between screens

### Performance Monitoring ✅
- App startup time (target: <10 seconds)
- Memory usage tracking
- UI responsiveness

### Security Checks ✅
- Dependency vulnerability scanning
- Permission analysis
- Code security patterns

## 🔧 Setup Instructions

1. **Commit workflows to your repository:**
   ```bash
   git add .github/
   git commit -m "Add GitHub Actions workflows"
   git push origin main
   ```

2. **View workflows in GitHub:**
   - Go to your repository on GitHub
   - Click the "Actions" tab
   - See workflows running automatically

3. **Configure notifications:**
   - Go to repository Settings > Notifications
   - Enable email/Slack notifications for workflow results

## 📈 Workflow Status

You can add these badges to your main README.md:

```markdown
![Flutter Tests](https://github.com/yourusername/naijaSingles/workflows/Flutter%20Tests/badge.svg)
![Code Quality](https://github.com/yourusername/naijaSingles/workflows/Code%20Quality/badge.svg)
![Build Status](https://github.com/yourusername/naijaSingles/workflows/Build%20and%20Deploy/badge.svg)
```

## 🎯 Benefits

### For Development:
- **Instant feedback** on code changes
- **Prevent bugs** from reaching production
- **Maintain code quality** standards
- **Automated testing** of critical features

### For Team Collaboration:
- **PR validation** before merging
- **Consistent testing** across environments
- **Deployment confidence**
- **Quality gates** for releases

### For Production:
- **Reliable releases** with automated testing
- **Performance monitoring**
- **Security vulnerability detection**
- **Build artifacts** ready for app stores

## 🚨 Troubleshooting

### Common Issues:

1. **Tests failing on GitHub but passing locally:**
   - Check Flutter version consistency
   - Verify dependencies are locked in pubspec.lock
   - Review environment differences

2. **iOS simulator issues:**
   - Workflows use iPhone 15 Pro simulator
   - Adjust device name in workflow if needed

3. **Build failures:**
   - Check Xcode version compatibility
   - Verify signing certificates (for release builds)

### Getting Help:

- Check workflow logs in GitHub Actions tab
- Review test output for specific failures
- Compare with local test results

## 📝 Customization

You can modify workflows by:

1. **Adding new test cases** to `integration_test/app_test.dart`
2. **Changing trigger conditions** in workflow files
3. **Adding deployment targets** (Firebase, App Store, Play Store)
4. **Configuring notifications** (Slack, Discord, email)

---

**Your NaijaSingles app now has enterprise-level automated testing! 🎉**
