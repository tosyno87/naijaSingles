# Font, Branding & Background Consistency Report

## Issues Found

### 1. Font Inconsistency ⚠️ CRITICAL

**Problem**: Two different fonts are being used across the app:
- **Montserrat**: 1,156 instances (used in theme and most auth screens)
- **Poppins**: 739 instances (used in profile/edit screens and some onboarding)

**Industry Standard**: 
- For social/dating apps: **Inter** or **SF Pro** (system font) are most common
- **Montserrat** is also acceptable and widely used (modern, clean)
- **Poppins** is less common in dating apps

**Current State**:
- Theme defines `GoogleFonts.montserratTextTheme` as default
- But many screens hardcode `GoogleFonts.poppins()` directly

**Recommendation**: Standardize on **Montserrat** throughout the app (already in theme)

---

### 2. Brand Name Inconsistency ⚠️ HIGH PRIORITY

**Found instances of "NaijaSingles" instead of "Afropeep":**

1. `lib/features/onboarding/screens/enhanced_additional_info_screen.dart`
   - Line 43: Comment mentions "NaijaSingles"
   - Line 628: "What brings you to NaijaSingles?"

2. `lib/features/settings/notification_settings_screen.dart`
   - Line 256: "Control when and how you receive notifications from NaijaSingles."

3. `lib/features/settings/language_settings_screen.dart`
   - Line 369: "Select your preferred language for the NaijaSingles app..."

4. `lib/features/settings/help_center_screen.dart`
   - Line 288-289: "support@naijasingles.com"
   - Line 583: "subject=NaijaSingles Support Request"

5. `lib/features/settings/feedback_screen.dart`
   - Line 170: "Help us improve NaijaSingles..."
   - Line 210: "How would you rate your overall experience with NaijaSingles?"
   - Line 668: "...help us improve NaijaSingles."

6. `lib/features/profile/settings_screen.dart`
   - Line 781: "About NaijaSingles"
   - Line 802: "NaijaSingles is a dating app..."
   - Line 811: "© 2024 NaijaSingles. All rights reserved."

7. `lib/features/onboarding/onboarding_main.dart`
   - Line 158: "Please select what brings you to NaijaSingles"
   - Line 227: "Welcome to NaijaSingles!"

8. `lib/features/notifications/modern_notification_settings.dart`
   - Line 245: "Control when and how you receive notifications from NaijaSingles"

**Note**: Package imports (`package:naijasingles/...`) are correct and should NOT be changed.

---

### 3. Background Color Inconsistency ⚠️ MEDIUM PRIORITY

**Problem**: Many screens use `Colors.white` directly instead of `AppColors.backgroundColor`

**Files affected** (218 instances):
- Auth screens: Some use `AppColors.backgroundColor`, others use `Colors.white`
- Onboarding screens: Most use `Colors.white` directly
- Profile screens: Mix of both
- Settings screens: Mix of both

**Recommendation**: Replace all `Colors.white` with `AppColors.backgroundColor` for consistency

---

## Fix Plan

### Phase 1: Replace Poppins with Montserrat
- Replace all `GoogleFonts.poppins()` with `GoogleFonts.montserrat()`
- Update ~739 instances

### Phase 2: Replace "NaijaSingles" with "Afropeep"
- Update user-facing text in 8 files
- Keep package imports unchanged

### Phase 3: Standardize Background Colors
- Replace `Colors.white` with `AppColors.backgroundColor`
- Update ~218 instances

---

## Industry Standards Reference

### Fonts Used by Popular Dating Apps:
- **Tinder**: Custom font (similar to Proxima Nova)
- **Bumble**: System font (SF Pro on iOS, Roboto on Android)
- **Hinge**: System font with custom styling
- **OKCupid**: System font
- **Match**: Custom sans-serif

**Best Practice**: Use system fonts for performance, or a single custom font (like Montserrat) consistently throughout.

### Why Montserrat is Good:
- ✅ Modern, clean, professional
- ✅ Excellent readability at all sizes
- ✅ Supports multiple weights (300-900)
- ✅ Good for both headings and body text
- ✅ Widely used in modern apps

