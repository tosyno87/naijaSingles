# Afropeep Branch Strategy & Environment Management

## Current State Analysis

### 🔍 **Current Branch Structure**
```
main (production-ready)
├── feature/incremental-enhancements (current) ⭐
├── feature/new-features-clean
├── feature/communities-hub-redesign
├── feature/database-schema-routes-overhaul
└── fix-critical-issues
```

### 📊 **Current Version**
- **App Version:** `1.0.0+1` (ready for first release)
- **Firebase Project:** `naijasingles-74a75` (current)
- **Multiple Firebase Projects:** 8 projects exist (needs cleanup)

---

## 🎯 **Recommended Strategy**

### **1. Branch Strategy: GitFlow + Semantic Versioning**

#### **Branch Types:**
```
main                    # Production releases (v1.0.0, v1.1.0)
├── develop            # Integration branch (nightly builds)
├── release/v1.0.0     # Release preparation
├── hotfix/v1.0.1      # Critical fixes
└── feature/xxx        # Feature development
```

#### **Branch Naming Convention:**
```bash
# Features
feature/chat-enhancements
feature/group-management
feature/onboarding-redesign

# Releases
release/v1.0.0
release/v1.1.0

# Hotfixes
hotfix/v1.0.1-critical-bug
hotfix/v1.0.2-security-patch

# Environment-specific
develop
staging
production
```

### **2. Firebase Environment Strategy**

#### **Environment Structure:**
```
Firebase Projects:
├── afropeep-dev       # Development (feature branches)
├── afropeep-staging   # Staging (release branches)
└── afropeep-prod      # Production (main branch)
```

#### **Environment Mapping:**
```yaml
Development:
  - Branch: feature/*, develop
  - Firebase: afropeep-dev
  - Purpose: Feature development, testing
  - Data: Test data, mock users

Staging:
  - Branch: release/*, staging
  - Firebase: afropeep-staging
  - Purpose: Pre-production testing
  - Data: Production-like data, limited users

Production:
  - Branch: main
  - Firebase: afropeep-prod
  - Purpose: Live app
  - Data: Real users, production data
```

---

## 🚀 **Implementation Plan**

### **Phase 1: Clean Up Current State**

#### **1.1 Merge Current Feature to Main**
```bash
# Current: feature/incremental-enhancements
# Action: Merge to main for v1.0.0 release

git checkout main
git pull origin main
git merge feature/incremental-enhancements
git push origin main

# Tag the release
git tag -a v1.0.0 -m "Release v1.0.0 - Initial Afropeep release"
git push origin v1.0.0
```

#### **1.2 Clean Up Old Branches**
```bash
# Delete merged feature branches
git branch -d feature/incremental-enhancements
git push origin --delete feature/incremental-enhancements

# Keep only active branches
git branch -a | grep -E "(feature|release|hotfix)" | head -10
```

#### **1.3 Firebase Project Cleanup**
```bash
# Keep only these projects:
# - afropeep-dev (create)
# - afropeep-staging (create) 
# - afropeep-prod (rename current)

# Archive/delete old projects:
# - afromingle-b7e92
# - afropeep-82c8c
# - afropeep-d699a
# - afrosingles-2e533
# - naijasingles-c6735
# - tinder-afro-clone
```

### **Phase 2: Set Up Environments**

#### **2.1 Create Firebase Projects**
```bash
# Development
firebase projects:create afropeep-dev
firebase use afropeep-dev

# Staging  
firebase projects:create afropeep-staging
firebase use afropeep-staging

# Production (rename current)
firebase projects:create afropeep-prod
firebase use afropeep-prod
```

#### **2.2 Environment Configuration**
```dart
// lib/config/environment.dart
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static const Environment _environment = Environment.development;
  
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'afropeep-dev';
      case Environment.staging:
        return 'afropeep-staging';
      case Environment.production:
        return 'afropeep-prod';
    }
  }
  
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://api-dev.afropeep.com';
      case Environment.staging:
        return 'https://api-staging.afropeep.com';
      case Environment.production:
        return 'https://api.afropeep.com';
    }
  }
}
```

#### **2.3 GitHub Actions Environment Matrix**
```yaml
# .github/workflows/deploy.yml
strategy:
  matrix:
    environment: [development, staging, production]
    include:
      - environment: development
        firebase_project: afropeep-dev
        branch: develop
      - environment: staging
        firebase_project: afropeep-staging
        branch: staging
      - environment: production
        firebase_project: afropeep-prod
        branch: main
```

### **Phase 3: Implement GitFlow**

#### **3.1 Create Develop Branch**
```bash
# Create develop branch from main
git checkout main
git checkout -b develop
git push origin develop

# Set develop as default branch for new features
git checkout develop
```

#### **3.2 Update GitHub Actions**
```yaml
# .github/workflows/ci.yml
on:
  push:
    branches: [main, develop, 'release/*', 'hotfix/*']
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        branch: [main, develop]
    
  deploy:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: macos-latest
    steps:
      - name: Deploy to Production
        run: |
          firebase use afropeep-prod
          firebase deploy
```

#### **3.3 Release Process**
```bash
# 1. Create release branch
git checkout develop
git checkout -b release/v1.1.0

# 2. Update version
# Edit pubspec.yaml: version: 1.1.0+1

# 3. Test and fix issues
flutter test
flutter test integration_test/

# 4. Merge to main
git checkout main
git merge release/v1.1.0
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin main v1.1.0

# 5. Merge back to develop
git checkout develop
git merge release/v1.1.0
git push origin develop

# 6. Delete release branch
git branch -d release/v1.1.0
git push origin --delete release/v1.1.0
```

---

## 📋 **Immediate Action Plan**

### **Option A: Quick Release (Recommended)**
```bash
# 1. Merge current feature to main
git checkout main
git merge feature/incremental-enhancements
git push origin main

# 2. Tag and deploy v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0 - Initial Afropeep release"
git push origin v1.0.0

# 3. Set up GitHub secrets and deploy
# (See previous deployment guide)
```

### **Option B: Full Environment Setup**
```bash
# 1. Set up Firebase environments first
# 2. Implement branch strategy
# 3. Then merge and deploy
```

---

## 🎯 **Best Practices**

### **Version Management**
```yaml
# Semantic Versioning: MAJOR.MINOR.PATCH+BUILD
version: 1.0.0+1    # First release
version: 1.0.1+2    # Bug fix
version: 1.1.0+3    # New feature
version: 2.0.0+4    # Breaking change
```

### **Branch Protection Rules**
```yaml
# GitHub Settings → Branches → Add rule
Branch: main
- Require pull request reviews
- Require status checks to pass
- Require branches to be up to date
- Restrict pushes to main
```

### **Environment Variables**
```bash
# .env.development
FIREBASE_PROJECT_ID=afropeep-dev
API_BASE_URL=https://api-dev.afropeep.com
DEBUG_MODE=true

# .env.staging
FIREBASE_PROJECT_ID=afropeep-staging
API_BASE_URL=https://api-staging.afropeep.com
DEBUG_MODE=false

# .env.production
FIREBASE_PROJECT_ID=afropeep-prod
API_BASE_URL=https://api.afropeep.com
DEBUG_MODE=false
```

### **Deployment Strategy**
```yaml
Development:
  - Auto-deploy on push to develop
  - Firebase: afropeep-dev
  - Purpose: Feature testing

Staging:
  - Auto-deploy on push to release/*
  - Firebase: afropeep-staging
  - Purpose: Pre-production testing

Production:
  - Manual deploy on merge to main
  - Firebase: afropeep-prod
  - Purpose: Live app
```

---

## 🔧 **Commands to Execute**

### **Immediate (Today)**
```bash
# 1. Merge to main
git checkout main
git pull origin main
git merge feature/incremental-enhancements
git push origin main

# 2. Tag release
git tag -a v1.0.0 -m "Release v1.0.0 - Initial Afropeep release"
git push origin v1.0.0

# 3. Set up GitHub secrets (see previous guide)
# 4. Deploy via GitHub Actions
```

### **Next Week (Environment Setup)**
```bash
# 1. Create Firebase projects
firebase projects:create afropeep-dev
firebase projects:create afropeep-staging
firebase projects:create afropeep-prod

# 2. Set up branch strategy
git checkout -b develop
git push origin develop

# 3. Update CI/CD workflows
# 4. Test environment deployments
```

---

## 📊 **Benefits of This Strategy**

### **✅ Advantages**
- **Clear separation** of environments
- **Safe deployments** with staging
- **Version control** with semantic versioning
- **Team collaboration** with GitFlow
- **Automated testing** per environment
- **Rollback capability** with tags

### **⚠️ Considerations**
- **Initial setup** requires time
- **Firebase project** management overhead
- **Team training** on GitFlow
- **CI/CD complexity** increases

---

## 🎯 **Recommendation**

**For immediate deployment:** Use Option A (Quick Release)
1. Merge to main
2. Tag v1.0.0
3. Deploy via GitHub Actions
4. Set up environments later

**For long-term:** Implement full environment strategy
1. Set up Firebase environments
2. Implement GitFlow
3. Update CI/CD workflows
4. Train team on process

---

**✨ Key Takeaway:** Merge to main first for v1.0.0 release, then implement proper environment strategy for future releases.
