# GitHub Actions for AfroPeep

This directory contains automated workflows that run tests, quality checks, and deployments for the AfroPeep dating app.

## 🚀 Workflows

### 1. CI - Quality Gates & SonarQube (`ci.yml`) ⭐ **Main CI Workflow**
**Triggers:** Push/PR to `main`, `develop`, `feature/*`

**What it does:**
- ✅ Code quality analysis (static analysis, formatting)
- ✅ **SonarQube analysis** (code quality, security, coverage)
- ✅ Security analysis (secrets detection, vulnerability scanning)
- ✅ Unit tests with coverage (70% threshold)
- ✅ Build validation (Android APK)
- ✅ Quality gate summary

**SonarQube Integration:**
- Runs on PRs and main/develop branches
- Analyzes new code vs. main branch
- Enforces quality gates
- See `docs/SONARQUBE_SETUP.md` for setup

### 2. Production Deployment (`production.yml`)
**Triggers:** Push/PR to `main`, `release/*`

**What it does:**
- ✅ Runs tests with coverage
- ✅ Builds iOS app with code signing
- ✅ Auto-increments build number
- ✅ Deploys to App Store Connect
- ✅ Security scanning

### 3. Staging Deployment (`staging.yml`)
**Triggers:** Push/PR to `develop`

**What it does:**
- ✅ Runs tests and analysis
- ✅ Builds staging web app
- ✅ Deploys to Firebase hosting (staging)
- ✅ Security audit

### 4. Feature Development (`feature-development.yml`)
**Triggers:** Push/PR to `develop`, `feature/*`, `fix/*`

**What it does:**
- ✅ Runs tests and analysis
- ✅ Checks code formatting
- ✅ iOS build verification (PR only)
- ✅ Coverage reporting

## 📊 Quality Gates

### Code Quality Standards
- **Coverage Threshold:** 70% (warning, not blocking)
- **Static Analysis:** Must pass (warnings allowed)
- **Security:** No secrets in code (blocking)
- **Build:** Must compile successfully (blocking)
- **SonarQube:** Quality gate must pass (on PRs/main)

### Test Coverage
- Unit tests for all services and repositories
- Widget tests for critical UI components
- Integration tests for key user flows
- Security tests for authentication and data protection

## 🔧 Setup Instructions

### 1. SonarQube Setup (Required for CI)

1. **Add GitHub Secrets:**
   - Go to repository Settings > Secrets and variables > Actions
   - Add `SONAR_TOKEN`: Your SonarQube/SonarCloud authentication token
   - Add `SONAR_HOST_URL`: `https://sonarcloud.io` (or your SonarQube server)

2. **Configure SonarQube:**
   - Follow `docs/SONARQUBE_SETUP.md`
   - Set "New Code Definition" to `Reference branch: main`
   - Configure quality gates

3. **Project Configuration:**
   - Project key: `afropeep`
   - Configuration file: `sonar-project.properties` (already created)

### 2. Codecov Setup (Optional)

1. **Add GitHub Secret:**
   - Add `CODECOV_TOKEN`: Your Codecov token

2. **View Coverage:**
   - Coverage reports uploaded automatically
   - View at codecov.io or in PR comments

### 3. View Workflows

1. **In GitHub:**
   - Go to repository > Actions tab
   - See all workflow runs and status

2. **In SonarQube:**
   - View code quality metrics
   - Check quality gate status
   - Review security vulnerabilities

## 📈 Workflow Status Badges

Add these to your main `README.md`:

```markdown
![CI](https://github.com/yourusername/naijaSingles/workflows/CI%20-%20Quality%20Gates%20%26%20SonarQube/badge.svg)
![Production](https://github.com/yourusername/naijaSingles/workflows/Production%20Deployment/badge.svg)
```

## 🎯 Benefits

### For Development:
- **Instant feedback** on code changes via PR checks
- **Prevent bugs** with automated quality gates
- **Maintain code quality** with SonarQube analysis
- **Security scanning** to catch vulnerabilities early

### For Team Collaboration:
- **PR validation** before merging
- **Consistent testing** across all environments
- **Quality metrics** visible in PRs
- **Automated quality gates** prevent regressions

### For Production:
- **Reliable releases** with comprehensive testing
- **Automated deployments** to App Store
- **Build number management** automatic
- **Security audits** before deployment

## 🚨 Troubleshooting

### Common Issues:

1. **SonarQube not running:**
   - Check `SONAR_TOKEN` and `SONAR_HOST_URL` secrets are set
   - Verify workflow triggers (runs on PRs/main/develop only)
   - Check SonarQube project exists and is configured

2. **Tests failing on GitHub but passing locally:**
   - Check Flutter version (should be 3.35.5)
   - Verify dependencies in `pubspec.lock`
   - Review environment differences

3. **Coverage below threshold:**
   - This is a warning, not a failure
   - Aim for 70%+ coverage
   - Review coverage report in Codecov

4. **Build failures:**
   - Check Xcode version compatibility
   - Verify signing certificates (for production)
   - Review build logs for specific errors

### Getting Help:

- Check workflow logs in GitHub Actions tab
- Review SonarQube dashboard for quality issues
- Compare with local test results
- See `docs/GITHUB_ACTIONS_CONSOLIDATION.md` for workflow details

## 📝 Workflow Customization

### Adding New Checks:
1. Edit `.github/workflows/ci.yml`
2. Add new job or step
3. Test with a feature branch PR

### Changing Triggers:
1. Edit `on:` section in workflow file
2. Adjust branch patterns as needed

### Adding Notifications:
1. Add notification step to workflow
2. Configure Slack/Discord/email integration

## 📚 Documentation

- **Workflow Details:** `docs/GITHUB_ACTIONS_CONSOLIDATION.md`
- **SonarQube Setup:** `docs/SONARQUBE_SETUP.md`
- **Workflow Audit:** `docs/GITHUB_ACTIONS_AUDIT.md`

---

**Your AfroPeep app now has enterprise-level CI/CD with SonarQube integration! 🎉**
