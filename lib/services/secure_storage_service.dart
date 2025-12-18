import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for storing sensitive data
/// Uses flutter_secure_storage which provides:
/// - iOS: Keychain Services
/// - Android: AES encryption with KeyStore
/// - Web: Encrypted localStorage
///
/// Use this service for:
/// - Authentication tokens
/// - API keys
/// - User credentials
/// - Any sensitive user data
///
/// For non-sensitive data, use SharedPreferences instead.
class SecureStorageService {
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  // Configure secure storage with platform-specific options
  late final FlutterSecureStorage _storage;

  // Storage keys - centralized for consistency
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _apiKeyKey = 'api_key';
  static const String _biometricCredentialsKey = 'biometric_credentials';

  /// Initialize the secure storage service
  /// Should be called during app initialization
  Future<void> initialize() async {
    try {
      // Configure secure storage with platform-specific options
      _storage = const FlutterSecureStorage(
        // Android options - use encrypted shared preferences
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        // iOS options - default secure storage (Keychain)
        // Web options - encrypted by default
      );

      if (kDebugMode) {
        log('✅ Secure storage service initialized');
      }
    } catch (e) {
      log('❌ Error initializing secure storage: $e');
      rethrow;
    }
  }

  /// Write secure data
  /// 
  /// [key] - The key to store the data under
  /// [value] - The value to store (must be a String)
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      if (kDebugMode) {
        log('✅ Secure data written for key: $key');
      }
      return true;
    } catch (e) {
      log('❌ Error writing secure data for key $key: $e');
      return false;
    }
  }

  /// Read secure data
  /// 
  /// [key] - The key to read the data from
  /// 
  /// Returns the stored value or null if not found
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (kDebugMode && value != null) {
        log('✅ Secure data read for key: $key');
      }
      return value;
    } catch (e) {
      log('❌ Error reading secure data for key $key: $e');
      return null;
    }
  }

  /// Delete secure data
  /// 
  /// [key] - The key to delete
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> delete(String key) async {
    try {
      await _storage.delete(key: key);
      if (kDebugMode) {
        log('✅ Secure data deleted for key: $key');
      }
      return true;
    } catch (e) {
      log('❌ Error deleting secure data for key $key: $e');
      return false;
    }
  }

  /// Read all secure data
  /// 
  /// Returns a map of all stored key-value pairs
  Future<Map<String, String>> readAll() async {
    try {
      final allData = await _storage.readAll();
      if (kDebugMode) {
        log('✅ Read all secure data: ${allData.length} entries');
      }
      return allData;
    } catch (e) {
      log('❌ Error reading all secure data: $e');
      return {};
    }
  }

  /// Delete all secure data
  /// 
  /// WARNING: This will delete all stored secure data
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> deleteAll() async {
    try {
      await _storage.deleteAll();
      if (kDebugMode) {
        log('✅ All secure data deleted');
      }
      return true;
    } catch (e) {
      log('❌ Error deleting all secure data: $e');
      return false;
    }
  }

  /// Check if a key exists
  /// 
  /// [key] - The key to check
  /// 
  /// Returns true if the key exists, false otherwise
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      log('❌ Error checking if key exists: $key - $e');
      return false;
    }
  }

  // Convenience methods for common use cases

  /// Store authentication token
  Future<bool> storeAuthToken(String token) async {
    return await write(_authTokenKey, token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await read(_authTokenKey);
  }

  /// Delete authentication token
  Future<bool> deleteAuthToken() async {
    return await delete(_authTokenKey);
  }

  /// Store refresh token
  Future<bool> storeRefreshToken(String token) async {
    return await write(_refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await read(_refreshTokenKey);
  }

  /// Delete refresh token
  Future<bool> deleteRefreshToken() async {
    return await delete(_refreshTokenKey);
  }

  /// Store user ID
  Future<bool> storeUserId(String userId) async {
    return await write(_userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await read(_userIdKey);
  }

  /// Delete user ID
  Future<bool> deleteUserId() async {
    return await delete(_userIdKey);
  }

  /// Store API key
  Future<bool> storeApiKey(String apiKey) async {
    return await write(_apiKeyKey, apiKey);
  }

  /// Get API key
  Future<String?> getApiKey() async {
    return await read(_apiKeyKey);
  }

  /// Delete API key
  Future<bool> deleteApiKey() async {
    return await delete(_apiKeyKey);
  }

  /// Store biometric credentials (for future biometric auth integration)
  Future<bool> storeBiometricCredentials(String credentials) async {
    return await write(_biometricCredentialsKey, credentials);
  }

  /// Get biometric credentials
  Future<String?> getBiometricCredentials() async {
    return await read(_biometricCredentialsKey);
  }

  /// Delete biometric credentials
  Future<bool> deleteBiometricCredentials() async {
    return await delete(_biometricCredentialsKey);
  }

  /// Clear all authentication-related data
  /// This is useful when logging out
  Future<bool> clearAuthData() async {
    try {
      await deleteAuthToken();
      await deleteRefreshToken();
      await deleteUserId();
      await deleteBiometricCredentials();
      if (kDebugMode) {
        log('✅ All authentication data cleared');
      }
      return true;
    } catch (e) {
      log('❌ Error clearing authentication data: $e');
      return false;
    }
  }
}

