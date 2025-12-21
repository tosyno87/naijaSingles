# SonarCloud Setup Guide

Complete guide for setting up and configuring SonarCloud for AfroPeep.

## Overview

SonarCloud provides automated code quality analysis, security vulnerability detection, and code coverage reporting integrated with GitHub Actions.

## Configuration Summary

### Project Configuration (`sonar-project.properties`)
✅ **Project Key:** `tosyno87_naijaSingles`  
✅ **Organization:** `tosyno87`  
✅ **Project Name:** `naijaSingles`  
✅ **Version:** `1.0`

### GitHub Actions Workflow (`.github/workflows/ci.yml`)
✅ **SonarQube Action:** `SonarSource/sonarqube-scan-action@v6`  
✅ **Quality Gate Action:** `SonarSource/sonarqube-quality-gate-action@v2`  
✅ **Triggers:** PRs and pushes to `main`/`develop`  
✅ **Build Step:** Added before SonarQube scan  
✅ **Coverage:** Integrated with test coverage reports

## Setup Steps

### 1. Add GitHub Secret

1. **Go to:** Repository Settings > Secrets and variables > Actions
2. **Add Secret:**
   - **Name:** `SONAR_TOKEN`
   - **Value:** Your SonarCloud token (get it from SonarCloud dashboard)

### 2. Get Your SonarCloud Token

1. Go to [SonarCloud.io](https://sonarcloud.io)
2. Log in with your GitHub account
3. Go to **My Account** > **Security**
4. Generate a new token
5. Copy the token and add it to GitHub Secrets

### 3. Configure New Code Definition

**What is "New Code Definition"?**

The **New Code Definition** determines what code SonarQube considers "new" for quality gates and metrics. This is crucial because:
- Quality gates only apply to "new code" by default
- You can set different quality standards for new vs. legacy code
- It helps focus on improving code quality incrementally

**Recommended Setting for AfroPeep:**

**Option 1: Reference Branch (Recommended)**
- **Setting:** `Reference branch: main`
- **What it does:** Any code that differs from `main` is considered "new"
- **Perfect for:** Feature branch development workflow

**How to set:**
1. In SonarCloud, go to **Project Settings > New Code Definition**
2. Select **"Reference branch"**
3. Enter: `main`
4. Save

**Option 2: Number of Days**
- **Setting:** `Number of days: 30`
- **What it does:** Code changed in the last 30 days is considered "new"
- **Good for:** Continuous development

### 4. Organization vs. Project Level

**Organization Level (Recommended First):**
1. Go to **Organization Settings > New Code Definition**
2. Set your preferred default (e.g., `Reference branch: main`)
3. This becomes the default for all new projects

**Project Level (Override if Needed):**
1. Go to **Project Settings > New Code Definition**
2. Select **"Use project-specific definition"**
3. Choose your preferred setting
4. Save

## Quality Gate Settings

Once you've set the new code definition, configure quality gates:

### Recommended Quality Gate for New Code:
- **Coverage:** ≥ 70% (matches your CI threshold)
- **Duplicated Lines:** < 3%
- **Maintainability Rating:** A
- **Reliability Rating:** A
- **Security Rating:** A
- **Code Smells:** < 50

## When SonarQube Runs

- ✅ On pull requests to `main` or `develop`
- ✅ On pushes to `main` or `develop`
- ⏭️ Skipped on feature branches (to save resources)

## What Happens Now

### On Pull Requests:
- ✅ Code quality analysis runs
- ✅ Security vulnerabilities detected
- ✅ Coverage reported
- ✅ Quality gate status shown in PR

### On Main/Develop Pushes:
- ✅ Full analysis runs
- ✅ Quality gates enforced
- ✅ Metrics updated in SonarCloud dashboard

## Workflow Structure

```yaml
sonarqube:
  - Checkout code (full history)
  - Setup Flutter
  - Install dependencies
  - Build (flutter build apk --debug)
  - Run tests with coverage
  - SonarQube Scan
  - Quality Gate Check
```

## Troubleshooting

### SonarQube Not Running?
- ✅ Check `SONAR_TOKEN` secret is set
- ✅ Verify workflow triggers (PRs/main/develop)
- ✅ Check SonarCloud project exists

### Quality Gate Failing?
- ✅ Review issues in SonarCloud dashboard
- ✅ Fix code smells and vulnerabilities
- ✅ Improve test coverage

### Coverage Not Showing?
- ✅ Ensure tests generate `coverage/lcov.info`
- ✅ Check coverage file path in workflow
- ✅ Verify coverage exclusions are correct

### "No new code found"
- **Solution:** Ensure your branch has commits that differ from the reference branch
- Check that the reference branch name matches exactly (case-sensitive)

### "All code is marked as new"
- **Solution:** This is normal for the first analysis. Subsequent analyses will correctly identify new code.

### Quality gates not applying
- **Solution:** Verify new code definition is set correctly
- Check that quality gate conditions reference "new code" metrics

## Files Updated

1. ✅ `sonar-project.properties` - Updated with correct project key
2. ✅ `.github/workflows/ci.yml` - Updated SonarQube integration
3. ✅ Build step added before SonarQube scan

## Additional Resources

- [SonarQube New Code Definition Documentation](https://docs.sonarqube.org/latest/project-administration/defining-new-code/)
- [SonarCloud New Code Definition](https://docs.sonarcloud.io/analysis/new-code/)
- [SonarCloud Getting Started](https://sonarcloud.io/documentation/)

## Next Steps

1. ✅ Add `SONAR_TOKEN` secret to GitHub
2. ✅ Configure new code definition in SonarCloud
3. ✅ Test with a PR or push to main/develop
4. ✅ Review SonarCloud dashboard for results

---

**You're All Set! 🎉**

Once you add the `SONAR_TOKEN` secret, SonarCloud will automatically analyze your code on every PR and push to main/develop.

