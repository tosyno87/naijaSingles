# 📋 Feature Development Plan - Afropeep Improvements

## 🎯 Overview
This document outlines the prioritized approach to implementing all requested changes following best practices and GitFlow workflow.

---

## 📊 Issue Categorization & Prioritization

### 🔴 **CRITICAL (Fix First - Blocks Core Functionality)**
1. **"I cannot take a photo when setting up my profile - Failed"**
   - Priority: P0 (Critical bug blocking user onboarding)
   - Type: Bug Fix
   - Branch: `fix/profile-photo-upload`
   - Impact: Users cannot complete profile setup

2. **"After setting up my profile, my PP is not showing"**
   - Priority: P0 (Critical bug - profile picture not displaying)
   - Type: Bug Fix
   - Branch: `fix/profile-picture-display`
   - Impact: Core feature broken, poor UX

3. **"I signed with an account that does not exist"**
   - Priority: P0 (Authentication security issue)
   - Type: Bug Fix / Security
   - Branch: `fix/auth-validation`
   - Impact: Security risk, poor error handling

### 🟠 **HIGH (Core Features Missing)**
4. **"I should not be able to skip a required field"** ⭐ (Highlighted)
   - Priority: P1 (Data validation issue)
   - Type: Bug Fix / Validation
   - Branch: `fix/required-field-validation`
   - Impact: Data quality, user experience

5. **"When registering, there shouldn't be a skip button"**
   - Priority: P1 (UX improvement)
   - Type: Feature Change
   - Branch: `fix/registration-skip-button`
   - Impact: Completes onboarding flow

6. **"I don't see a forgot password link"**
   - Priority: P1 (Core authentication feature)
   - Type: Feature Addition
   - Branch: `feature/forgot-password`
   - Impact: User account recovery

### 🟡 **MEDIUM (User Experience Improvements)**
7. **"I cannot RSVP an event"**
   - Priority: P2 (Feature broken)
   - Type: Bug Fix
   - Branch: `fix/event-rsvp`
   - Impact: Core feature not working

8. **"There should be a section to see the event I RSVP to"**
   - Priority: P2 (Feature addition)
   - Type: Feature Addition
   - Branch: `feature/my-rsvp-events`
   - Impact: User experience enhancement

9. **"I cannot click on people's profile"**
   - Priority: P2 (Navigation issue)
   - Type: Bug Fix
   - Branch: `fix/profile-navigation`
   - Impact: Core user interaction broken

### 🟢 **LOW (Polish & Cleanup)**
10. **"Login sign not properly written"**
    - Priority: P3 (UI text fix)
    - Type: Bug Fix / Copy
    - Branch: `fix/login-text`
    - Impact: Minor UX improvement

11. **"Search country feature when registering an account"**
    - Priority: P3 (UX enhancement)
    - Type: Feature Addition
    - Branch: `feature/country-search`
    - Impact: Registration UX improvement

12. **"Take out Tribe selection feature"**
    - Priority: P3 (Feature removal)
    - Type: Feature Removal
    - Branch: `refactor/remove-tribe-selection`
    - Impact: Code cleanup, simplification

---

## 🚀 Recommended Development Approach

### **Phase 1: Critical Bug Fixes (Week 1)**
Fix blocking issues that prevent users from using core features.

**Tasks:**
1. ✅ Fix profile photo upload failure
2. ✅ Fix profile picture not displaying after upload
3. ✅ Fix authentication validation (signing with non-existent account)

**Branch Strategy:**
- Create: `fix/critical-profile-issues` (combines photo upload + display)
- Create: `fix/auth-validation`
- Merge to `main` after testing

**Testing:**
- Test photo upload on iPhone Simulator
- Test profile picture display across app
- Test authentication error handling

---

### **Phase 2: Core Feature Fixes (Week 2)**
Fix validation and missing core features.

**Tasks:**
1. ✅ Implement required field validation (no skip on required fields)
2. ✅ Remove skip button from registration flow
3. ✅ Add forgot password functionality

**Branch Strategy:**
- Create: `fix/registration-validation` (combines validation + skip button)
- Create: `feature/forgot-password`
- Merge to `main` after testing

---

### **Phase 3: Feature Improvements (Week 3)**
Fix broken features and add requested functionality.

**Tasks:**
1. ✅ Fix RSVP functionality
2. ✅ Add "My RSVP Events" section
3. ✅ Fix profile navigation (click on profiles)

**Branch Strategy:**
- Create: `fix/event-rsvp`
- Create: `feature/my-rsvp-events`
- Create: `fix/profile-navigation`

---

### **Phase 4: Polish & Cleanup (Week 4)**
Minor fixes and feature removals.

**Tasks:**
1. ✅ Fix login text/UI
2. ✅ Add country search in registration
3. ✅ Remove Tribe selection feature

**Branch Strategy:**
- Create: `fix/login-ui-text`
- Create: `feature/country-search`
- Create: `refactor/remove-tribe-selection`

---

## 📝 Development Workflow (Per Issue)

Following `.cursorrules` standard routine:

### **Step 1: Check Current Status**
```bash
git checkout main
git pull origin main
git status
```

### **Step 2: Create Feature/Fix Branch**
```bash
# For bug fixes
git checkout -b fix/issue-description

# For features
git checkout -b feature/feature-name

# For refactoring
git checkout -b refactor/refactor-name
```

### **Step 3: Pre-Development Checks**
```bash
flutter pub get
flutter analyze
flutter test
```

### **Step 4: Development**
- Make changes following Flutter best practices
- Use Material 3 components
- Replace `print()` with `log()`
- Write tests as you develop

### **Step 5: Test Locally**
```bash
./scripts/test_ios.sh
# Test on iPhone Simulator
# Use hot reload (r) to see changes instantly
```

### **Step 6: Pre-Commit Validation**
```bash
dart format lib/ test/
flutter analyze
flutter test
git diff  # Review changes
```

### **Step 7: Commit with Convention**
```bash
git add .
git commit -m "fix: resolve profile photo upload failure"
# or
git commit -m "feat: add forgot password functionality"
```

### **Step 8: Push & Create PR**
```bash
git push origin fix/issue-description
# Create PR with:
# - Clear title
# - Description of changes
# - Testing steps
# - Screenshots (for UI changes)
```

---

## 🎯 Implementation Order (Recommended)

### **Week 1: Critical Fixes**
```
Day 1-2: fix/critical-profile-issues (photo upload + display)
Day 3: fix/auth-validation
Day 4: Testing & PR review
Day 5: Merge & deploy
```

### **Week 2: Core Features**
```
Day 1-2: fix/registration-validation
Day 3-4: feature/forgot-password
Day 5: Testing & PR review
```

### **Week 3: Feature Improvements**
```
Day 1: fix/event-rsvp
Day 2-3: feature/my-rsvp-events
Day 4: fix/profile-navigation
Day 5: Testing & PR review
```

### **Week 4: Polish**
```
Day 1: fix/login-ui-text
Day 2: feature/country-search
Day 3: refactor/remove-tribe-selection
Day 4-5: Testing & final PRs
```

---

## 📋 Task Breakdown Template

For each issue, create a task list:

### Example: Profile Photo Upload Fix
- [ ] Investigate photo upload error (check logs, permissions)
- [ ] Fix image picker configuration
- [ ] Fix upload to Firebase Storage
- [ ] Fix profile picture display after upload
- [ ] Add error handling and user feedback
- [ ] Write unit tests
- [ ] Test on iPhone Simulator
- [ ] Test on physical device
- [ ] Create PR with screenshots
- [ ] Address review comments

---

## ✅ Quality Checklist (Per Feature)

Before creating PR:
- [ ] Code follows Flutter best practices
- [ ] Uses Material 3 design (`useMaterial3: true`)
- [ ] All `print()` replaced with `log()`
- [ ] Error handling implemented
- [ ] User-facing error messages provided
- [ ] Tests written and passing
- [ ] Tested locally on iPhone Simulator
- [ ] Code formatted (`dart format`)
- [ ] Code analyzed (`flutter analyze`)
- [ ] No breaking changes (or documented)
- [ ] Screenshots included (for UI changes)
- [ ] Documentation updated if needed

---

## 🚨 Risk Assessment

### **High Risk Changes**
- Authentication fixes (security implications)
- Profile photo upload (file permissions, storage)
- Required field validation (data integrity)

### **Medium Risk Changes**
- Event RSVP functionality (data consistency)
- Profile navigation (user flow)

### **Low Risk Changes**
- UI text fixes
- Feature removals (Tribe selection)
- UX enhancements (country search)

---

## 📱 Testing Strategy

### **Local Testing (Before PR)**
```bash
# Run on iPhone Simulator
./scripts/test_ios.sh

# Test each feature:
1. Photo upload → Test capture, pick from gallery, upload
2. Profile display → Verify photo shows after upload
3. Authentication → Test error cases
4. Validation → Test all required fields
5. Navigation → Test all profile clicks
```

### **Manual Testing Checklist**
- [ ] Happy path (expected user flow)
- [ ] Error cases (invalid input, network errors)
- [ ] Edge cases (empty data, permissions denied)
- [ ] UI responsiveness (different screen sizes)
- [ ] Hot reload works correctly

---

## 🎯 Success Metrics

After each phase:
- ✅ All critical bugs fixed
- ✅ All tests passing
- ✅ Code review approved
- ✅ Tested on iPhone Simulator
- ✅ No regressions in existing features

---

## 📚 Next Steps

1. **Start with Phase 1, Task 1**: Fix profile photo upload
2. Follow the development workflow from `.cursorrules`
3. Test each fix locally before committing
4. Create PRs with clear descriptions
5. Get approval before merging

**Ready to start? Let's begin with the first critical fix: Profile Photo Upload!** 🚀

