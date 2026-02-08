# Afropeep - Deployment and Branch Strategy

## Overview
This document outlines our deployment strategy and branch management workflow for the Afropeep dating app.

## Branch Strategy (GitFlow-inspired)

### Branch Types

#### 🌳 **main** - Production Branch
- **Purpose**: Live production environment
- **Protection**: Required PR reviews, no direct pushes
- **Deployment**: Manual or critical hotfix deployments only
- **Who can merge**: Senior developers + review approval

#### 🔄 **develop** - Staging Branch  
- **Purpose**: Staging environment for testing
- **Protection**: Optional PR reviews
- **Deployment**: Auto-deployed via GitHub Actions
- **Who can merge**: Developers + automatic CI approval

#### 🚀 **release/\*** - Release Branches
- **Purpose**: Production releases
- **Protection**: Required PR reviews
- **Deployment**: Auto-deployed to production via GitHub Actions
- **Format**: `release/1.0.0`, `release/1.1.0`, etc.

#### 🔧 **feature/\*** - Feature Branches
- **Purpose**: New features and bug fixes
- **Protection**: None (development only)
- **Target**: Merge to `develop`
- **Format**: `feature/user-profile`, `feature/group-chat`, etc.

#### 🛠️ **hotfix/\*** - Hotfix Branches
- **Purpose**: Critical production fixes
- **Protection**: Required PR reviews
- **Target**: Merge to `main` and `develop`
- **Format**: `hotfix/critical-bug-fix`

## Environment Configuration

### Environments

#### 🟢 **Production** (`FLAVOR=production`)
- Firebase Project: `naijasingles-prod2`
- Domain: `naijasingles.com`
- Features: Full analytics, crash reporting, all production features
- Security: Strict password requirements, short session timeout

#### 🟡 **Staging** (`FLAVOR=staging`)
- Firebase Project: `naijasingles-staging` (when created)
- Domain: `staging.naijasingles.com`
- Features: Alpha version, enhanced debugging
- Security: Relaxed for testing

#### 🔵 **Development** (`FLAVOR=dev`)
- Firebase Project: `naijasingles-dev` or emulator
- Domain: `localhost:8080`
- Features: Full debugging, experimental features
- Security: Very relaxed for development

### Environment Variables

| Variable | Production | Staging | Development |
|----------|------------|---------|-------------|
| `FLAVOR` | `production` | `staging` | `dev` |
| `FIREBASE_PROJECT_ID` | `naijasingles-prod2` | `naijasingles-staging` | `naijasingles-dev` |
| `APP_NAME_POSTFIX` | `` | ` (Alpha)` | ` (Dev)` |

## Development Workflow

### Creating Features

1. **Start from develop**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature
   ```

2. **Make your changes**:
   - Write code
   - Add tests
   - Update documentation

3. **Create pull request**:
   - Target: `develop`
   - Include tests and screenshots
   - Reference any related issues

4. **Review and merge**:
   - Wait for CI checks to pass
   - Get required approvals
   - Merge to `develop`

5. **Test in staging**:
   - Changes auto-deploy to staging
   - Test functionality and performance
   - Gather stakeholder feedback

### Creating Releases

1. **Create release branch**:
   ```bash
   git checkout develop
   git checkout -b release/1.1.0
   git push -u origin release/1.1.0
   ```

2. **Production testing**:
   - Test in staging environment
   - Fix any release-blocking bugs
   - Update version numbers in `pubspec.yaml`

3. **Deploy to production**:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   git push origin release/1.1.0
   ```

4. **CI/CD handles deployment**:
   - GitHub Actions detects tag/release branch
   - Runs tests and builds
   - Deploys to Firebase Hosting automatically

5. **Merge back to develop and main**:
   ```bash
   git checkout develop
   git merge release/1.1.0
   git checkout main
   git merge release/1.1.0
   ```

### Hotfixes

1. **Create hotfix branch from main**:
   ```bash
   git checkout main
   git checkout -b hotfix/critical-fix
   ```

2. **Make minimal fix**:
   - Only fix the critical issue
   - Test thoroughly
   - Update version patch

3. **Deploy immediately**:
   ```bash
   git checkout main
   git merge hotfix/critical-fix
   git tag v1.0.1
   git push origin main v1.0.1
   ```

4. **Merge to develop**:
   ```bash
   git checkout develop  
   git merge hotfix/critical-fix
   git push origin develop
   ```

## CI/CD Pipeline

### GitHub Actions Workflows

#### Production Workflow (`.github/workflows/production.yml`)
- **Triggers**: Push to `release/*`, PR to `release/*`
- **Steps**:
  1. Run tests and security scans
  2. Build Flutter web app with production flavor
  3. Deploy to Firebase Hosting (`naijasingles-prod2`)
  4. Create deployment record

#### Staging Workflow (`.github/workflows/staging.yml`)
- **Triggers**: Push to `develop`, PR to `develop`
- **Steps**:
  1. Run tests and security scans
  2. Build Flutter web app with staging flavor
  3. Deploy to Firebase Hosting (staging project)
  4. Create deployment record

### Required Secrets

Configure these in GitHub repo settings:

#### For Production:
- `GOOGLE_SERVICE_ACCOUNT_PROD`: Service account JSON for production Firebase
- `FIREBASE_TOKEN_PROD`: Firebase CI token for production
- `FIREBASE_PROJECT_ID_PROD`: Production Firebase project ID
- `GH_TOKEN`: GitHub token for deployment records

#### For Staging:
- `GOOGLE_SERVICE_ACCOUNT_STAGING`: Service account JSON for staging Firebase
- `FIREBASE_TOKEN_STAGING`: Firebase CI token for staging  
- `FIREBASE_PROJECT_ID_STAGING`: Staging Firebase project ID

#### Optional:
- `CODECOV_TOKEN`: For test coverage reports
- `GOOGLE_SERVICE_ACCOUNT_PROD`: For Google Cloud deployment

## Firebase Configuration

### Environment-specific Firebase Projects

Currently configured:
- **Production**: `naijasingles-prod2` 
- **Development**: Uses Firebase emulator or `naijasingles-dev`

### To set up staging:
1. Create new Firebase project: `naijasingles-staging`
2. Configure firebase.json with targets:
   ```json
   {
     "projects": {
       "default": "naijasingles-dev",
       "staging": "naijasingles-staging", 
       "production": "naijasingles-prod2"
     }
   }
   ```
3. Update GitHub secrets with staging project credentials

## Building for Different Environments

### Local Development
```bash
# Development (default)
flutter run -d chrome

# Staging
flutter run -d chrome --dart-define=FLAVOR=staging --dart-define=FIREBASE_PROJECT_ID=naijasingles-staging

# Production (be careful!)
flutter run -d chrome --dart-define=FLAVOR=production --dart-define=FIREBASE_PROJECT_ID=naijasingles-prod2
```

### Building for Deployment
```bash
# Production build
flutter build web --release --dart-define=FLAVOR=production --dart-define=FIREBASE_PROJECT_ID=naijasingles-prod2

# Staging build  
flutter build web --release --dart-define=FLAVOR=staging --dart-define=FIREBASE_PROJECT_ID=naijasingles-staging
```

## FAQ

### Q: Which branch should I work from?
**A**: Generally `develop` for features, `main` only for hotfixes.

### Q: How do I test my changes?
**A**: Create PR to `develop` → auto-deploys to staging → test there before release.

### Q: How do I deploy to production?
**A**: Create `release/X.Y.Z` branch → deploy automatically via CI/CD.

### Q: What if I need to fix a critical production bug?
**A**: Create hotfix branch from `main` → merge to both `main` and `develop`.

### Q: How do I know which environment I'm working in?
**A**: Check the app title bar - production shows "Afropeep", staging shows "Afropeep (Alpha)".

### Q: Can I deploy manually?
**A**: Yes, but CI/CD is preferred for consistency and traceability.

## Emergency Procedures

### Production Incident Response
1. **Assess severity**: Is it user-facing and blocking?
2. **Create hotfix**: Branch from `main`, fix minimally
3. **Test quickly**: Verify fix works
4. **Deploy immediately**: Push hotfix, create patch version
5. **Communicate**: Notify users if needed
6. **Post-mortem**: Document what happened for improvement

### Rollback Procedure
1. **Identify last stable version**: Check Git tags
2. **Create rollback branch**: From known stable tag
3. **Quick verification**: Test critical paths
4. **Deploy rollback**: Push rollback branch
5. **Investigate root cause**: Fix the underlying issue

## Best Practices

### Do:
- ✅ Work off `develop` for features
- ✅ Write tests for new functionality  
- ✅ Use descriptive branch and commit messages
- ✅ Test in staging before production
- ✅ Keep releases small and focused
- ✅ Document breaking changes

### Don't:
- ❌ Push directly to `main` without PR
- ❌ Deploy untested changes to production
- ❌ Mix multiple features in one release
- ❌ Skip security review for production changes
- ❌ Leave broken builds unrepaired

## Support

- **Technical Issues**: Create GitHub issue
- **Urgent Production**: Tag @frontend-team in Discord/Slack
- **Environment Questions**: Check this doc first, then ask
- **CI/CD Problems**: Check GitHub Actions logs, then escalate

---

*Last updated: $(date)*
*Next review: Monthly or before major releases*
