# GitHub Actions Workflows

Complete guide to the GitHub Actions CI/CD workflows for AfroPeep.

## Overview

This document covers the consolidated GitHub Actions workflows, their purpose, triggers, and how they work together.

## Workflow Structure

```
.github/workflows/
├── ci.yml                    # Main CI (quality gates + SonarQube)
├── production.yml            # Production deployments
├── staging.yml               # Staging deployments
└── feature-development.yml   # Feature branch checks
```

## Workflows

### 1. CI - Quality Gates & SonarQube (`ci.yml`)

**Purpose:** Main continuous integration workflow with comprehensive quality checks.

**Triggers:**
- Push/PR to `main`, `develop`, `feature/*`

**Jobs:**
1. **Code Quality Analysis**
   - Static analysis (`flutter analyze`)
   - Code formatting check
   - Analysis report generation

2. **SonarQube Analysis** (PR/main/develop only)
   - Code quality analysis
   - Security vulnerability detection
   - Coverage reporting
   - Quality gate enforcement

3. **Security Analysis**
   - Secrets detection
   - Environment configuration validation
   - Dependency vulnerability scanning

4. **Unit Tests with Coverage**
   - Run unit tests
   - Generate coverage report
   - Check coverage threshold (70%)
   - Upload to Codecov

5. **Build Validation**
   - Build Android APK
   - Verify build succeeds

6. **Quality Gate Summary**
   - Generate summary of all checks
   - Display results in GitHub Actions

### 2. Production Deployment (`production.yml`)

**Purpose:** Deploy to production App Store.

**Triggers:**
- Push/PR to `main`, `release/*`

**Jobs:**
1. **Tests**
   - Run Flutter analyzer
   - Run tests with coverage
   - Upload coverage to Codecov

2. **Build and Deploy**
   - Setup Xcode and code signing
   - Auto-increment build number
   - Build iOS app
   - Deploy to App Store Connect

3. **Security Scan** (PR only)
   - Run security audit
   - Check for outdated packages

### 3. Staging Deployment (`staging.yml`)

**Purpose:** Deploy to staging environment.

**Triggers:**
- Push/PR to `develop`

**Jobs:**
1. **Test and Build**
   - Run Flutter analyzer
   - Run tests
   - Build staging web app
   - Deploy to Firebase hosting (staging)

2. **Security Scan** (PR only)
   - Run security audit

### 4. Feature Development (`feature-development.yml`)

**Purpose:** Quick checks for feature branches.

**Triggers:**
- Push/PR to `develop`, `feature/*`, `fix/*`

**Jobs:**
1. **Tests and Analysis**
   - Run Flutter analyzer
   - Run tests with coverage
   - Check code formatting
   - Upload coverage to Codecov

2. **Build Check** (PR only)
   - iOS build verification (no signing)

## Configuration

### Flutter Version
All workflows use **Flutter 3.35.5** (standardized across all workflows).

### Required Secrets

#### For CI Workflow:
- `SONAR_TOKEN` - SonarCloud authentication token

#### For Production Workflow:
- `FIREBASE_WEB_API_KEY_PROD`
- `FIREBASE_ANDROID_API_KEY_PROD`
- `FIREBASE_IOS_API_KEY_PROD`
- `FIREBASE_PROJECT_ID_PROD`
- `FIREBASE_MESSAGING_SENDER_ID_PROD`
- `FIREBASE_STORAGE_BUCKET_PROD`
- `FIREBASE_AUTH_DOMAIN_PROD`
- `FIREBASE_IOS_CLIENT_ID_PROD`
- `GOOGLE_MAPS_API_KEY_PROD`
- `APPSTORE_API_KEY_ID`
- `APPSTORE_API_ISSUER_ID`
- `APPSTORE_API_PRIVATE_KEY`
- `MATCH_PASSWORD`
- `MATCH_GIT_URL`
- `PAT_TOKEN`
- `CODECOV_TOKEN`

## Workflow History

### Consolidation Summary

**Before:**
- ❌ 12 workflows (many redundant)
- ❌ Tests disabled in multiple workflows
- ❌ Inconsistent Flutter versions
- ❌ No SonarQube integration
- ❌ Broken workflows

**After:**
- ✅ 4 focused workflows
- ✅ Tests enabled and working
- ✅ Consistent Flutter 3.35.5
- ✅ SonarQube integrated
- ✅ All workflows functional

### Removed Workflows

The following redundant/broken workflows were removed:
- `code_quality.yml` (consolidated into `ci.yml`)
- `flutter_tests.yml` (consolidated into `ci.yml`)
- `flutter.yml` (too simple, broken)
- `flutter-ci.yml` (broken, redundant)
- `build_and_deploy.yml` (consolidated into `production.yml`)
- `comprehensive_tests.yml` (broken test paths, consolidated into `ci.yml`)
- `ios_deploy.yml` (consolidated into `production.yml`)
- `quality_gates.yml` (consolidated into `ci.yml`)

## Quality Gates

### Code Quality Standards
- **Coverage Threshold:** 70% (warning, not blocking)
- **Static Analysis:** Must pass (warnings allowed)
- **Security:** No secrets in code (blocking)
- **Build:** Must compile successfully (blocking)
- **SonarQube:** Quality gate must pass (on PRs/main)

## Monitoring

### View Workflow Runs
1. Go to repository > Actions tab
2. See all workflow runs and status
3. Click on a run to see detailed logs

### View SonarQube Results
1. Go to [SonarCloud.io](https://sonarcloud.io)
2. Navigate to your project
3. View code quality metrics
4. Check quality gate status

### View Coverage Reports
1. Go to [Codecov.io](https://codecov.io) (if configured)
2. View coverage trends
3. See coverage reports in PR comments

## Troubleshooting

### Workflow Not Running?
- Check workflow triggers match your branch
- Verify workflow file syntax is correct
- Check GitHub Actions is enabled for the repository

### Tests Failing?
- Check Flutter version matches (3.35.5)
- Verify dependencies in `pubspec.lock`
- Review test logs for specific errors

### SonarQube Not Running?
- Check `SONAR_TOKEN` secret is set
- Verify workflow triggers (PRs/main/develop only)
- Check SonarCloud project exists

### Build Failures?
- Check Xcode version compatibility
- Verify signing certificates (for production)
- Review build logs for specific errors

## Best Practices

1. **Always test locally** before pushing
2. **Review PR checks** before merging
3. **Monitor quality gates** in SonarCloud
4. **Keep secrets secure** - never commit them
5. **Update Flutter version** consistently across all workflows

## Next Steps

1. ✅ Add required secrets to GitHub
2. ✅ Configure SonarCloud (see `docs/SONARCLOUD_SETUP.md`)
3. ✅ Test workflows with a PR
4. ✅ Monitor workflow runs and quality gates

---

**For detailed SonarCloud setup:** See `docs/SONARCLOUD_SETUP.md`  
**For workflow details:** See `.github/README.md`

