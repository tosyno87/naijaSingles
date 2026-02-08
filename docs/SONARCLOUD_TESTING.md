# Testing SonarCloud Integration

## Quick Test Options

### Option 1: Fix Git Authentication (Recommended)

The push failed due to missing `workflow` scope. Fix it:

1. **Update your GitHub Personal Access Token:**
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Create a new token with `workflow` scope
   - Or update existing token to include `workflow` scope

2. **Update Git credentials:**
   ```bash
   git remote set-url origin https://YOUR_TOKEN@github.com/tosyno87/naijaSingles.git
   ```
   
   Or use SSH:
   ```bash
   git remote set-url origin git@github.com:tosyno87/naijaSingles.git
   ```

3. **Push again:**
   ```bash
   git push origin feature/secure-storage-implementation
   ```

4. **Create a PR** on GitHub to trigger SonarQube

### Option 2: Test Locally (Without GitHub Actions)

You can test SonarCloud analysis locally:

1. **Install SonarScanner:**
   ```bash
   # macOS
   brew install sonar-scanner
   
   # Or download from: https://docs.sonarcloud.io/advanced-setup/ci-based-analysis/sonarscanner/
   ```

2. **Get your SonarCloud token:**
   - Go to [SonarCloud.io](https://sonarcloud.io)
   - My Account > Security > Generate token

3. **Run analysis locally:**
   ```bash
   export SONAR_TOKEN=your_token_here
   sonar-scanner \
     -Dsonar.projectKey=tosyno87_naijaSingles \
     -Dsonar.organization=tosyno87 \
     -Dsonar.sources=lib \
     -Dsonar.host.url=https://sonarcloud.io
   ```

### Option 3: Manual PR Creation

1. **Push via GitHub Web UI:**
   - Go to your repository on GitHub
   - Use "Upload files" or create PR manually
   - This bypasses the workflow scope issue

2. **Or merge to main/develop:**
   - Merge your feature branch to main/develop
   - This will trigger SonarQube automatically

## Verify SonarCloud Setup

### Before Testing:

1. ✅ **Check `SONAR_TOKEN` secret is set:**
   - Repository Settings > Secrets > Actions
   - Verify `SONAR_TOKEN` exists

2. ✅ **Verify SonarCloud project exists:**
   - Go to [SonarCloud.io](https://sonarcloud.io)
   - Check project `tosyno87_naijaSingles` exists

3. ✅ **Check workflow file:**
   - `.github/workflows/ci.yml` exists
   - SonarQube job is configured correctly

## What to Expect

### When SonarQube Runs:

1. **In GitHub Actions:**
   - You'll see "SonarQube Analysis" job
   - It will checkout code, build, run tests, and scan
   - Results will appear in SonarCloud dashboard

2. **In SonarCloud Dashboard:**
   - Go to your project: https://sonarcloud.io/project/overview?id=tosyno87_naijaSingles
   - See code quality metrics
   - View security vulnerabilities
   - Check coverage reports

3. **In PR Comments:**
   - SonarCloud bot will comment on PR
   - Shows quality gate status
   - Lists new issues found

## Troubleshooting

### "SONAR_TOKEN not found"
- Add the secret in GitHub repository settings
- Verify secret name is exactly `SONAR_TOKEN`

### "Project not found"
- Create project in SonarCloud first
- Verify project key matches: `tosyno87_naijaSingles`

### "Workflow scope error"
- Update your Git credentials with workflow scope
- Or use SSH authentication

### SonarQube job skipped
- Check workflow triggers (only runs on PRs/main/develop)
- Verify branch name matches trigger conditions

## Next Steps

1. Fix Git authentication (add workflow scope)
2. Push branch and create PR
3. Watch GitHub Actions for SonarQube job
4. Check SonarCloud dashboard for results

---

**Once the PR is created, SonarCloud will automatically analyze your code! 🎉**

