# 🚀 Development Workflow Guide

## 📋 **Branch Strategy**

### **Main Branches**
- **`main`** - Production-ready code with working CI/CD
- **`develop`** - Integration branch for features (optional)

### **Feature Branches**
- **`feature/feature-name`** - New features or enhancements
- **`fix/issue-description`** - Bug fixes
- **`hotfix/critical-fix`** - Critical production fixes

### **Release Branches**
- **`release/version-number`** - Release preparation (e.g., `release/1.1.0`)

## 🔄 **Development Workflow**

### **For New Features:**
```bash
# 1. Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/new-feature-name

# 2. Develop your feature
# ... make changes ...

# 3. Commit with clear messages
git add .
git commit -m "feat: add new feature description"

# 4. Push and create PR
git push origin feature/new-feature-name
# Create PR: feature/new-feature-name → main
```

### **For Bug Fixes:**
```bash
# 1. Create fix branch from main
git checkout main
git pull origin main
git checkout -b fix/bug-description

# 2. Fix the bug
# ... make changes ...

# 3. Commit with clear messages
git add .
git commit -m "fix: resolve bug description"

# 4. Push and create PR
git push origin fix/bug-description
# Create PR: fix/bug-description → main
```

### **For Critical Hotfixes:**
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# 2. Fix the critical issue
# ... make changes ...

# 3. Commit and push
git add .
git commit -m "hotfix: resolve critical production issue"
git push origin hotfix/critical-issue

# 4. Create PR and merge immediately after approval
# Create PR: hotfix/critical-issue → main
```

## 📝 **Commit Message Convention**

Use conventional commits for clear history:

- **`feat:`** - New features
- **`fix:`** - Bug fixes
- **`docs:`** - Documentation changes
- **`style:`** - Code style changes (formatting, etc.)
- **`refactor:`** - Code refactoring
- **`test:`** - Adding or updating tests
- **`chore:`** - Maintenance tasks

**Examples:**
```bash
git commit -m "feat: add user profile editing functionality"
git commit -m "fix: resolve app crash on iOS 17"
git commit -m "docs: update API documentation"
```

## 🚀 **CI/CD Pipeline Behavior**

### **Main Branch (`main`)**
- ✅ **Runs full CI/CD pipeline**
- ✅ **Deploys to App Store Connect**
- ✅ **Requires pull request approval**
- ✅ **Requires all tests to pass**

### **Feature/Fix Branches**
- ✅ **Runs tests and analysis**
- ✅ **Does NOT deploy to App Store**
- ✅ **Validates code quality**
- ❌ **No production deployment**

### **Release Branches**
- ✅ **Runs full CI/CD pipeline**
- ✅ **Deploys to App Store Connect**
- ✅ **Auto-increments build numbers**

## 🔒 **Branch Protection Rules**

### **Main Branch Protection:**
- ✅ **Require pull request reviews before merging**
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- ✅ **Include administrators**

## 📊 **Pull Request Process**

### **Required Information:**
1. **Clear title** describing the change
2. **Description** of what was changed and why
3. **Testing steps** for reviewers
4. **Screenshots** (for UI changes)
5. **Breaking changes** (if any)

### **Review Checklist:**
- [ ] Code follows project conventions
- [ ] Tests pass locally
- [ ] No breaking changes without documentation
- [ ] UI changes include screenshots
- [ ] Documentation updated if needed

## 🎯 **Deployment Strategy**

### **Feature Development:**
1. **Develop on feature branch**
2. **Create PR to main**
3. **Get approval and merge**
4. **CI/CD automatically deploys to App Store Connect**

### **Release Process:**
1. **Create release branch** (e.g., `release/1.1.0`)
2. **Final testing and bug fixes**
3. **Merge to main**
4. **Create GitHub release with tag**
5. **Submit to App Store for review**

## 🚨 **Emergency Hotfix Process**

For critical production issues:

1. **Create hotfix branch from main**
2. **Fix the critical issue**
3. **Create PR with "HOTFIX" label**
4. **Fast-track review and merge**
5. **CI/CD automatically deploys fix**

## 📈 **Quality Gates**

### **Before Merging to Main:**
- ✅ **All tests pass**
- ✅ **Code analysis passes**
- ✅ **At least 1 approval**
- ✅ **No merge conflicts**
- ✅ **Branch is up to date with main**

### **Before App Store Submission:**
- ✅ **Full CI/CD pipeline passes**
- ✅ **App Store validation succeeds**
- ✅ **Build number auto-incremented**
- ✅ **All metadata completed in App Store Connect**

---

**This workflow ensures quality, traceability, and reliable deployments!** 🚀
