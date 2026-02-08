# Font, Branding & Background Consistency - Fix Summary

## ✅ Completed Fixes

### 1. Brand Name Consistency ✅
**Status**: **COMPLETE**

All user-facing instances of "NaijaSingles" have been replaced with "Afropeep":

- ✅ `lib/features/onboarding/screens/enhanced_additional_info_screen.dart`
  - Comment updated
  - "What brings you to Afropeep?" heading updated

- ✅ `lib/features/settings/notification_settings_screen.dart`
  - Notification description text updated

- ✅ `lib/features/settings/language_settings_screen.dart`
  - Language selection description updated

- ✅ `lib/features/settings/help_center_screen.dart`
  - Support email: `support@afropeep.com`
  - Email subject: "Afropeep Support Request"

- ✅ `lib/features/settings/feedback_screen.dart`
  - Feedback description updated
  - Rating question updated
  - Success message updated

- ✅ `lib/features/profile/settings_screen.dart`
  - "About Afropeep" section updated
  - App description updated
  - Copyright notice updated

- ✅ `lib/features/onboarding/onboarding_main.dart`
  - Validation message updated
  - Welcome message updated

- ✅ `lib/features/notifications/modern_notification_settings.dart`
  - Notification description updated

**Note**: Package imports (`package:naijasingles/...`) are correct and remain unchanged.

---

## 🔄 Remaining Tasks

### 2. Font Consistency ⚠️ IN PROGRESS
**Status**: **739 instances to replace**

**Issue**: Mix of `GoogleFonts.poppins()` (739 instances) and `GoogleFonts.montserrat()` (1,156 instances)

**Industry Standard**: 
- **Montserrat** is acceptable and already defined in theme
- Most modern dating apps use system fonts (Inter/SF Pro) or a single custom font consistently

**Recommendation**: Replace all `GoogleFonts.poppins()` with `GoogleFonts.montserrat()` for consistency

**Files affected**: 65 files across:
- Profile screens (`edit_profile_screen.dart` - 39 instances)
- Onboarding screens (multiple files)
- Settings screens
- Messages/chat screens
- Groups screens
- Events screens

**Action Required**: Run find-and-replace across codebase:
- Find: `GoogleFonts.poppins`
- Replace: `GoogleFonts.montserrat`

---

### 3. Background Color Consistency ⚠️ PENDING
**Status**: **218 instances to replace**

**Issue**: Mix of `Colors.white` and `AppColors.backgroundColor`

**Current State**:
- Some screens use `AppColors.backgroundColor` ✅
- Many screens use `Colors.white` directly ❌

**Recommendation**: Replace all `Colors.white` background usages with `AppColors.backgroundColor` for consistency and easier theme management

**Files affected**: Many files across:
- Auth screens (some already fixed)
- Onboarding screens
- Profile screens
- Settings screens

**Action Required**: 
- Find: `backgroundColor: Colors.white`
- Replace: `backgroundColor: AppColors.backgroundColor`
- Also check for: `const Color backgroundColor = Colors.white;` declarations

---

## 📊 Impact Assessment

### Brand Name Fixes
- **Impact**: HIGH - Direct user-facing text
- **Files Changed**: 8 files
- **Instances Fixed**: 12+ user-facing text strings
- **Status**: ✅ Complete

### Font Consistency
- **Impact**: MEDIUM-HIGH - Visual consistency
- **Files Affected**: 65 files
- **Instances to Replace**: 739
- **Status**: ⚠️ Needs automated replacement

### Background Consistency  
- **Impact**: MEDIUM - Code consistency and maintainability
- **Files Affected**: Many
- **Instances to Replace**: ~218
- **Status**: ⚠️ Needs systematic replacement

---

## 🎯 Next Steps

### Priority 1: Font Consistency
1. Use IDE find-and-replace (case-sensitive):
   - Find: `GoogleFonts.poppins`
   - Replace: `GoogleFonts.montserrat`
   - Scope: Entire `lib/` directory

2. Verify theme consistency:
   - Ensure `MyThemes` uses Montserrat (already done ✅)
   - Check that no hardcoded font families remain

### Priority 2: Background Consistency
1. Replace hardcoded white backgrounds:
   - Find: `backgroundColor: Colors.white`
   - Replace: `backgroundColor: AppColors.backgroundColor`

2. Remove duplicate color constants:
   - Find: `static const Color backgroundColor = Colors.white;`
   - Replace with: Use `AppColors.backgroundColor` directly

3. Update import statements where needed:
   - Add `import '../../common/constants/app_colors.dart';` if missing

---

## ✅ Verification Checklist

- [x] All "NaijaSingles" → "Afropeep" replacements completed
- [ ] All `GoogleFonts.poppins()` → `GoogleFonts.montserrat()` replacements
- [ ] All `Colors.white` → `AppColors.backgroundColor` replacements
- [ ] Theme uses Montserrat consistently
- [ ] No duplicate color constants in screen files

---

## 📝 Notes

1. **Package imports** (`package:naijasingles/...`) should NOT be changed - these are correct
2. **Email domains**: Changed display text to "afropeep.com" but actual email server may still be "naijasingles.com" - verify with backend team
3. **Font performance**: Using Montserrat consistently is good; system fonts (Inter/SF Pro) would be faster but Montserrat is acceptable
4. **Background colors**: Using `AppColors.backgroundColor` enables easier theme management and potential dark mode support in future

