# Secure Storage Testing Guide

Comprehensive testing guide for the SecureStorageService implementation in AfroPeep.

## Table of Contents
1. [Testing Overview](#testing-overview)
2. [Unit Tests](#unit-tests)
3. [Integration Tests](#integration-tests)
4. [Manual Testing](#manual-testing)
5. [Device-Specific Testing](#device-specific-testing)
6. [Security Verification](#security-verification)

## Testing Overview

### Important: Unit Test Limitations

The `flutter_secure_storage` package requires platform channels (iOS Keychain, Android KeyStore) which are **not available in unit test environments**.

**What This Means:**
- ✅ Unit tests can verify API structure and method signatures
- ✅ Unit tests can check error handling logic
- ❌ Unit tests **cannot** test actual read/write operations
- ❌ Unit tests will return `false` for write operations
- ❌ Unit tests will return `null` for read operations

**Solution:** Use Integration Tests or Manual Testing for full functionality testing.

## Unit Tests

### Running Unit Tests

```bash
# Run all secure storage tests
flutter test test/services/secure_storage_service_test.dart

# Run with coverage
flutter test --coverage test/services/secure_storage_service_test.dart

# Run specific test group
flutter test test/services/secure_storage_service_test.dart --name "Authentication Token Operations"
```

### Test Coverage

The unit tests cover:
- ✅ Initialization
- ⚠️ Write/Read operations (skipped - requires platform channels)
- ⚠️ Delete operations (skipped)
- ⚠️ Read all operations (skipped)
- ⚠️ Contains key operations (skipped)
- ✅ Authentication token operations (API structure)
- ✅ User ID operations (API structure)
- ✅ Error handling structure

### Current Test Status

Tests that are skipped (expected):
- Write/Read operations
- Delete operations  
- Read all operations
- Contains key operations
- All convenience methods (auth token, user ID, etc.)

Tests that pass:
- Initialization
- API structure verification
- Error handling structure

## Integration Tests

### Testing Authentication Flow

Create an integration test to verify secure storage works with the authentication flow:

```dart
// integration_test/secure_storage_auth_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naijasingles/services/secure_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Secure Storage Authentication Integration', () {
    late SecureStorageService secureStorage;

    setUp(() async {
      secureStorage = SecureStorageService();
      await secureStorage.initialize();
    });

    tearDown(() async {
      await secureStorage.clearAuthData();
    });

    testWidgets('should store token after successful authentication', (tester) async {
      // These will work in integration tests
      await secureStorage.storeAuthToken('test_token');
      final token = await secureStorage.getAuthToken();
      expect(token, equals('test_token'));
    });

    testWidgets('should clear storage on logout', (tester) async {
      await secureStorage.storeAuthToken('test_token');
      await secureStorage.storeUserId('test_user');
      
      await secureStorage.clearAuthData();
      
      expect(await secureStorage.getAuthToken(), isNull);
      expect(await secureStorage.getUserId(), isNull);
    });
  });
}
```

Run with:
```bash
flutter test integration_test/secure_storage_auth_test.dart
```

## Manual Testing

### Prerequisites

1. **Run the app in debug mode** to see console logs:
   ```bash
   flutter run
   ```

2. **Keep the terminal/console open** to see log messages

3. **Have a test account** ready (phone number, email, or Google account)

### Test 1: Verify Secure Storage Initialization

**What to do:**
1. Launch the app
2. Watch the console logs when the app starts

**What to look for:**
```
🔐 Secure storage service initialized successfully
```

**Expected Result:**
- ✅ You see the initialization message
- ✅ No errors about secure storage

### Test 2: Token Storage After Login

**What to do:**
1. Open the app
2. Log in using any method (phone, email, Google)
3. Complete the authentication flow
4. Watch the console logs

**What to look for:**
```
✅ Token stored securely
✅ Secure data written for key: auth_token
✅ Secure data written for key: user_id
```

**Expected Result:**
- ✅ You see "Token stored securely" after successful login
- ✅ App navigates to home screen
- ✅ No error messages

### Test 3: Verify Token Persistence

**What to do:**
1. After logging in, note that you're on the home screen
2. **Completely close the app** (swipe it away from recent apps)
3. **Reopen the app**
4. Watch what happens

**Expected Result:**
- ✅ App should remember you're logged in (if Firebase Auth persists)
- ✅ You should go directly to home screen (not login screen)
- ✅ No errors in console

### Test 4: Logout Clears Secure Storage

**What to do:**
1. Make sure you're logged in
2. Navigate to Settings/Profile
3. Find and tap "Logout" or "Sign Out"
4. Confirm the logout action
5. Watch the console logs

**What to look for:**
```
✅ Secure storage cleared on logout
✅ All secure data deleted
```

**Expected Result:**
- ✅ You see "Secure storage cleared" message
- ✅ App navigates back to login/welcome screen
- ✅ User is signed out
- ✅ No errors

### Test 5: Multiple Login/Logout Cycles

**What to do:**
1. Log in → Check logs for "Token stored securely"
2. Log out → Check logs for "Secure storage cleared"
3. Log in again → Check logs for "Token stored securely"
4. Log out again → Check logs for "Secure storage cleared"
5. Repeat 2-3 more times

**Expected Result:**
- ✅ Each login stores a new token
- ✅ Each logout clears storage
- ✅ No data leakage between sessions
- ✅ No errors accumulate

## Device-Specific Testing

### iOS Testing

#### Test Keychain Access
1. Install app on iOS device/simulator
2. Log in
3. Use Xcode to inspect Keychain (if accessible)

**Expected Result:**
- Data stored in iOS Keychain
- Encrypted and protected

#### Test App Uninstall
1. Log in to app
2. Store some data in secure storage
3. Uninstall app
4. Reinstall app

**Expected Result:**
- Secure storage data is cleared (iOS Keychain data is app-specific)
- User needs to log in again

### Android Testing

#### Test Encrypted SharedPreferences
1. Install app on Android device/emulator
2. Log in
3. Data stored in encrypted SharedPreferences

**Expected Result:**
- Data stored in encrypted SharedPreferences
- Not readable as plain text

#### Test App Uninstall
1. Log in to app
2. Store some data in secure storage
3. Uninstall app
4. Reinstall app

**Expected Result:**
- Secure storage data is cleared
- User needs to log in again

## Security Verification

### 1. Verify Encryption

**iOS:**
- Data stored in Keychain is automatically encrypted
- Uses hardware-backed encryption when available

**Android:**
- Data stored in EncryptedSharedPreferences
- Uses AES encryption with Android KeyStore

### 2. Test Data Persistence

**Steps:**
1. Log in and store data
2. Force close app
3. Reopen app

**Expected Result:**
- Data persists across app restarts
- User remains authenticated (if Firebase Auth persists)

### 3. Test Data Isolation

**Steps:**
1. Install app on device
2. Log in as User A
3. Log out
4. Log in as User B

**Expected Result:**
- User A's data is completely cleared
- User B's data is stored separately
- No data leakage between users

## Console Log Reference

### Initialization
```
🔐 Secure storage service initialized successfully
```

### After Login
```
✅ Token stored securely
✅ Secure data written for key: auth_token
✅ Secure data written for key: user_id
```

### During Logout
```
✅ Secure storage cleared on logout
✅ All secure data deleted
```

### Errors (Should NOT see these)
```
❌ Error writing secure data
❌ Error reading secure data
❌ Secure storage initialization error
```

## Testing Checklist

- [ ] **Initialization Test**
  - [ ] App starts without errors
  - [ ] See "Secure storage service initialized" message

- [ ] **Login Test**
  - [ ] Can log in successfully
  - [ ] See "Token stored securely" message

- [ ] **Persistence Test**
  - [ ] Close and reopen app
  - [ ] User remains logged in (if Firebase Auth persists)

- [ ] **Logout Test**
  - [ ] Can log out successfully
  - [ ] See "Secure storage cleared" message

- [ ] **Multiple Sessions Test**
  - [ ] Can log in multiple times
  - [ ] Can log out multiple times
  - [ ] No errors accumulate

## Troubleshooting

### Problem: Don't see "Token stored securely" message
- Make sure you complete the full login flow
- Check console filter settings
- Run in debug mode: `flutter run --debug`

### Problem: See error messages
- Check that `flutter_secure_storage` is installed: `flutter pub get`
- Verify you're on a device/emulator (not just unit tests)

### Problem: Storage not clearing on logout
- Check the logout flow is calling `clearAuthData()`
- Verify you're using the updated logout code

## Running All Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/secure_storage_service_test.dart
```

---

**Last Updated:** Current  
**Status:** Comprehensive testing guide with unit, integration, and manual testing instructions

