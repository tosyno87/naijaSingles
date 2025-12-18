# Secure Storage Service Usage Guide

## Overview

The `SecureStorageService` provides secure storage for sensitive data in the Afropeep app. It uses `flutter_secure_storage` which provides:

- **iOS**: Keychain Services (encrypted)
- **Android**: AES encryption with KeyStore
- **Web**: Encrypted localStorage

## When to Use Secure Storage

✅ **Use Secure Storage for:**
- Authentication tokens
- API keys
- User credentials
- Sensitive user preferences
- Biometric authentication data

❌ **Don't use Secure Storage for:**
- Non-sensitive preferences (use `SharedPreferences`)
- Large data (use file storage or database)
- Frequently accessed non-sensitive data

## Basic Usage

### Getting the Service Instance

```dart
final secureStorage = SecureStorageService();
```

### Writing Data

```dart
// Write any key-value pair
await secureStorage.write('my_key', 'my_value');

// Or use convenience methods
await secureStorage.storeAuthToken('token123');
await secureStorage.storeUserId('user123');
```

### Reading Data

```dart
// Read any key
final value = await secureStorage.read('my_key');

// Or use convenience methods
final token = await secureStorage.getAuthToken();
final userId = await secureStorage.getUserId();
```

### Deleting Data

```dart
// Delete a specific key
await secureStorage.delete('my_key');

// Or use convenience methods
await secureStorage.deleteAuthToken();

// Clear all authentication data (useful for logout)
await secureStorage.clearAuthData();
```

## Common Use Cases

### 1. Storing Authentication Tokens

```dart
// After successful login
final secureStorage = SecureStorageService();
await secureStorage.storeAuthToken(firebaseToken);
await secureStorage.storeRefreshToken(refreshToken);
await secureStorage.storeUserId(userId);
```

### 2. Retrieving Authentication Tokens

```dart
final secureStorage = SecureStorageService();
final token = await secureStorage.getAuthToken();
if (token != null) {
  // Use token for API calls
}
```

### 3. Logging Out

```dart
// Clear all authentication data
final secureStorage = SecureStorageService();
await secureStorage.clearAuthData();
```

### 4. Storing API Keys

```dart
final secureStorage = SecureStorageService();
await secureStorage.storeApiKey('your-api-key');
```

### 5. Checking if Data Exists

```dart
final secureStorage = SecureStorageService();
final exists = await secureStorage.containsKey('my_key');
if (exists) {
  // Key exists
}
```

## Integration with Existing Services

### Example: Biometric Auth Service

You can integrate secure storage with the biometric auth service:

```dart
// In BiometricAuthService
final secureStorage = SecureStorageService();

// Store credentials securely
await secureStorage.storeBiometricCredentials(encryptedCredentials);

// Retrieve credentials
final credentials = await secureStorage.getBiometricCredentials();
```

## Error Handling

The service handles errors gracefully and logs them. Always check return values:

```dart
final secureStorage = SecureStorageService();

// Write operation
final success = await secureStorage.write('key', 'value');
if (!success) {
  // Handle error
}

// Read operation
final value = await secureStorage.read('key');
if (value == null) {
  // Value doesn't exist or error occurred
}
```

## Best Practices

1. **Initialize Early**: The service is initialized in `main.dart` during app startup
2. **Use Convenience Methods**: Prefer the convenience methods (`storeAuthToken`, `getAuthToken`, etc.) for common operations
3. **Clear on Logout**: Always call `clearAuthData()` when user logs out
4. **Handle Null Values**: Always check for null when reading data
5. **Don't Store Large Data**: Secure storage is optimized for small key-value pairs

## Security Notes

- Data is encrypted at rest on all platforms
- On iOS, data is stored in the Keychain
- On Android, data is encrypted using AES with KeyStore
- Data is automatically cleared when the app is uninstalled (on most platforms)
- The service uses platform-specific secure storage mechanisms

## Migration from SharedPreferences

If you're currently storing sensitive data in `SharedPreferences`, consider migrating:

```dart
// OLD: Using SharedPreferences (NOT SECURE)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);

// NEW: Using SecureStorageService (SECURE)
final secureStorage = SecureStorageService();
await secureStorage.storeAuthToken(token);
```

