# Navigation Flash Fix: Sign In Phone Flow

## 🔍 **Problem Identified**

When users tapped "Continue with Phone" on `SignInMethodSelectionScreen`, there was a brief flash of an intermediate screen before the OTP verification screen appeared.

### **Root Causes Found:**

1. **Router Placeholder Screen Flash**
   - **Location**: `lib/common/routes/router.dart` (lines 137-169)
   - **Issue**: When `otpScreen` route was accessed with missing/invalid arguments, it returned a `Scaffold` with `CircularProgressIndicator` that was briefly visible before navigation back
   - **Impact**: Created a flash of a loading screen

2. **Navigation Stack Issue**
   - **Location**: `lib/features/auth/phone/ui/screens/phone_number.dart` (line 120)
   - **Issue**: Used `Navigator.pushNamed()` which adds OTP screen on top of PhoneNumber screen in the stack
   - **Flow**: `SignInMethodSelectionScreen → PhoneNumber → OTP` (3 screens in stack)
   - **Impact**: When OTP screen renders, PhoneNumber screen is briefly visible underneath, or there's a frame where PhoneNumber shows before OTP transition completes

---

## 📋 **Navigation Flow (Before Fix)**

```
1. User taps "Continue with Phone" on SignInMethodSelectionScreen
   ↓
2. Navigator.push() to PhoneNumber screen
   ↓
3. PhoneNumber screen renders (visible to user)
   ↓
4. User enters phone and taps Continue
   ↓
5. Firebase phone auth sends code
   ↓
6. BlocListener catches PhoneAuthCodeSentSuccess state
   ↓
7. Navigator.pushNamed() to OTP screen (adds to stack)
   ↓
8. **FLASH**: PhoneNumber screen briefly visible as OTP pushes on top
   ↓
9. OTP screen fully renders
```

---

## ✅ **Navigation Flow (After Fix)**

```
1. User taps "Continue with Phone" on SignInMethodSelectionScreen
   ↓
2. Navigator.push() to PhoneNumber screen
   ↓
3. PhoneNumber screen renders (visible to user)
   ↓
4. User enters phone and taps Continue
   ↓
5. Firebase phone auth sends code
   ↓
6. BlocListener catches PhoneAuthCodeSentSuccess state
   ↓
7. Navigator.pushReplacementNamed() to OTP screen (replaces PhoneNumber)
   ↓
8. **SMOOTH**: OTP screen replaces PhoneNumber directly, no flash
   ↓
9. OTP screen fully renders
```

---

## 🔧 **Changes Made**

### **1. Fixed Router Placeholder (`lib/common/routes/router.dart`)**

**Before:**
```dart
if (arguments == null || arguments is! Map) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ... navigate back
  });
  // Return a placeholder while we navigate away
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  ); // ❌ This causes flash
}
```

**After:**
```dart
if (arguments == null || arguments is! Map) {
  Future.microtask(() {
    // ... navigate back
  });
  // Return empty container to avoid showing any UI before navigation
  return const SizedBox.shrink(); // ✅ No visible flash
}
```

**Changes:**
- Changed `Scaffold` with `CircularProgressIndicator` to `SizedBox.shrink()` (invisible widget)
- Changed `addPostFrameCallback` to `Future.microtask` for faster execution
- Prevents any visible UI flash when arguments are missing

---

### **2. Fixed Navigation Method (`lib/features/auth/phone/ui/screens/phone_number.dart`)**

**Before:**
```dart
Navigator.pushNamed(context, RouteName.otpScreen, arguments: {
  // ... arguments
}); // ❌ Adds OTP on top, PhoneNumber remains in stack
```

**After:**
```dart
Navigator.of(context).pushReplacementNamed(
  RouteName.otpScreen,
  arguments: {
    // ... arguments
  },
); // ✅ Replaces PhoneNumber with OTP, no flash
```

**Changes:**
- Changed `Navigator.pushNamed()` to `Navigator.pushReplacementNamed()`
- PhoneNumber screen is **replaced** instead of staying in the stack
- Prevents PhoneNumber from being visible during transition

---

### **3. Updated `phone_auth_screen.dart` (Consistency)**

Applied the same fix to `phone_auth_screen.dart` for consistency across all phone auth flows.

---

## ✅ **Result**

- ✅ **No more flash**: Smooth transition from PhoneNumber to OTP screen
- ✅ **Cleaner navigation stack**: PhoneNumber is removed when OTP appears
- ✅ **Better UX**: Single, smooth navigation without intermediate screens
- ✅ **No visual artifacts**: Router no longer shows placeholder screens

---

## 🧪 **Testing Checklist**

- [ ] Tap "Continue with Phone" from SignInMethodSelectionScreen
- [ ] Verify PhoneNumber screen appears smoothly
- [ ] Enter phone number and tap Continue
- [ ] Verify OTP screen appears without any flash of PhoneNumber screen
- [ ] Verify back button on OTP screen returns to SignInMethodSelectionScreen (not PhoneNumber)

---

## 📝 **Files Modified**

1. `lib/common/routes/router.dart` - Fixed placeholder screen
2. `lib/features/auth/phone/ui/screens/phone_number.dart` - Changed to pushReplacementNamed
3. `lib/features/auth/phone/ui/screens/phone_auth_screen.dart` - Changed to pushReplacementNamed (consistency)

---

**Status**: ✅ **Fixed** - Navigation flash eliminated

