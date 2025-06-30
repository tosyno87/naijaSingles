# NaijaSingles - Unused Code Analysis Report

## Summary
This analysis identifies unused files, imports, and functionalities in the NaijaSingles Flutter project. The project has 850 lint issues, many of which are related to unused imports and deprecated API usage.

## 🚨 Critical Issues

### Unused Imports (High Priority)
The following files have unused imports that should be removed:

1. **lib/common/data/repo/phone_auth_repo.dart**
   - `package:flutter/foundation.dart`

2. **lib/common/routes/router.dart**
   - `package:naijasingles/features/auth/login/login_screen.dart` (duplicate import)
   - `package:naijasingles/features/explore/explore_page.dart`

3. **lib/common/utils/crop_image.dart**
   - `package:easy_localization/easy_localization.dart`

4. **lib/common/widgets/custom_button.dart**
   - `../constants/colors.dart`

5. **lib/features/auth/email_password/ui/screens/email_signup_screen.dart**
   - `../../../../../common/constants/colors.dart`

6. **lib/features/auth/login/login_screen.dart** (Multiple unused imports)
   - `package:firebase_auth/firebase_auth.dart`
   - `package:flutter/services.dart`
   - `package:flutter_bloc/flutter_bloc.dart`
   - `package:google_fonts/google_fonts.dart`
   - `../../../common/data/repo/phone_auth_repo.dart`
   - `../../../common/routes/route_name.dart`
   - `../google_login/google_login_barrel.dart`

## 🗂️ Potentially Unused Files

### Debug/Test Files (Safe to Remove)
These files appear to be for debugging/testing and are not used in production:

1. **lib/check_user_id.dart** - Standalone debug app for checking user IDs
2. **lib/debug_firebase_data.dart** - Firebase data debugging widget
3. **lib/debug_user_search.dart** - User search debugging
4. **lib/test_firestore_access.dart** - Firestore access testing
5. **lib/print_user_id.dart** - User ID printing utility

### Demo/Example Files (Consider Removing)
These appear to be demo implementations that may not be used:

1. **lib/features/onboarding/screens/afrocentric_height_demo.dart**
2. **lib/features/onboarding/screens/height_dropdown_demo.dart**
3. **lib/features/onboarding/screens/height_picker_demo.dart**
4. **lib/features/onboarding/screens/onboarding_demo_screen.dart**
5. **lib/features/onboarding/screens/onboarding_integration_example.dart**
6. **lib/features/match/ui/swipe_integration_example.dart**

### Unused Screen Files
These screens may not be integrated into the main navigation:

1. **lib/features/auth/login/login_screen.dart** - Has unused fields and imports
2. **lib/features/auth/login/login_screen_new.dart** - Alternative login screen
3. **lib/features/onboarding/screens/onboarding_additional_preferences_screen.dart**
4. **lib/features/onboarding/screens/onboarding_preferences_screen.dart**

### Unused BLoC/State Files
These BLoC components may not be connected:

1. **lib/features/auth/auth_status/bloc/authstatus_event.dart**
2. **lib/features/auth/auth_status/bloc/authstatus_state.dart**
3. **lib/features/diary/bloc/diary_event.dart**
4. **lib/features/diary/bloc/diary_state.dart**
5. **lib/features/match/bloc/match_user_event.dart**
6. **lib/features/match/bloc/match_user_state.dart**

### Unused Service Files
1. **lib/features/explore/services/mock_match_service.dart** - Mock service for testing
2. **lib/common/utils/no_internet.dart** - No internet utility (may be unused)

## 📦 Dependency Analysis

### Potentially Unused Dependencies
Based on import analysis, these dependencies might be unused:

1. **agora_rtc_engine** - Commented out in pubspec.yaml but imported in code
2. **agora_uikit** - Commented out in pubspec.yaml
3. **flutter_flushbar** - Only version 0.0.2, might be outdated
4. **device_preview** - Development dependency, check if still needed
5. **bloc_test** - Test dependency, verify usage in tests
6. **mocktail** - Test dependency, verify usage in tests
7. **fake_cloud_firestore** - Test dependency, verify usage in tests
8. **firebase_auth_mocks** - Test dependency, verify usage in tests

## 🎨 Asset Analysis

### Potentially Unused Assets
Some assets in `/assets/images/` may be unused:

1. **assets/images/backgrounds/lagos_skyline.jpg** - 29 bytes (likely placeholder)
2. **assets/images/profiles/male_profile_4.jpg** - 29 bytes (likely placeholder)
3. Multiple profile images that may not be referenced in code

## 🔧 Deprecated API Usage

### High Priority Fixes Needed
The project uses many deprecated APIs that should be updated:

1. **withOpacity()** - Should use `.withValues()` (147+ occurrences)
2. **MaterialStateProperty** - Should use `WidgetStateProperty` (8+ occurrences)
3. **onPopInvoked** - Should use `onPopInvokedWithResult` (4+ occurrences)
4. **Share.share()** - Should use `SharePlus.instance.share()`
5. **updateEmail()** - Should use `verifyBeforeUpdateEmail()`

## 📋 Recommendations

### Immediate Actions (High Priority)
1. **Remove unused imports** - This will clean up 20+ warnings
2. **Delete debug/test files** - Remove files like `check_user_id.dart`, `debug_*.dart`
3. **Remove demo files** - Delete `*_demo.dart` and `*_example.dart` files
4. **Update deprecated APIs** - Focus on `withOpacity()` replacements first

### Medium Priority
1. **Consolidate login screens** - Choose between `login_screen.dart` and `login_screen_new.dart`
2. **Review unused BLoC components** - Remove or integrate unused state management
3. **Clean up asset files** - Remove placeholder/unused images
4. **Review dependencies** - Remove unused packages from pubspec.yaml

### Low Priority
1. **Remove print statements** - Replace with proper logging (100+ occurrences)
2. **Add const constructors** - Performance improvements (200+ suggestions)
3. **Review test coverage** - Ensure test dependencies are actually used

## 🧹 Cleanup Script Suggestions

```bash
# Remove debug files
rm lib/check_user_id.dart
rm lib/debug_firebase_data.dart
rm lib/debug_user_search.dart
rm lib/test_firestore_access.dart
rm lib/print_user_id.dart

# Remove demo files
rm lib/features/onboarding/screens/*_demo.dart
rm lib/features/onboarding/screens/*_example.dart
rm lib/features/match/ui/swipe_integration_example.dart

# Remove unused service files
rm lib/features/explore/services/mock_match_service.dart
```

## 📊 Impact Assessment

- **Files to remove**: ~15-20 files
- **Lint issues to fix**: ~850 issues
- **Unused imports**: ~25+ imports
- **Deprecated API calls**: ~200+ calls
- **Potential size reduction**: ~500KB+ in source code

This cleanup will significantly improve code maintainability, reduce build warnings, and prepare the codebase for future Flutter updates.
