import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      secureStorage = SecureStorageService();
      await secureStorage.initialize();
    });

    tearDown(() async {
      await secureStorage.deleteAll();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final service = SecureStorageService();
        await expectLater(
          service.initialize(),
          completes,
        );
      });

      test('should be idempotent (safe to call multiple times)', () async {
        final service = SecureStorageService();
        await service.initialize();
        await expectLater(
          service.initialize(),
          completes,
        );
      });
    });

    group('Write and Read Operations', () {
      test('should write and read data successfully', () async {
        const key = 'test_key';
        const value = 'test_value';

        final writeResult = await secureStorage.write(key, value);
        expect(writeResult, isTrue);

        final readValue = await secureStorage.read(key);
        expect(readValue, equals(value));
      });

      test('should return null when reading non-existent key', () async {
        const key = 'non_existent_key';

        final value = await secureStorage.read(key);
        expect(value, isNull);
      });

      test('should overwrite existing value', () async {
        const key = 'test_key';
        const value1 = 'value1';
        const value2 = 'value2';

        await secureStorage.write(key, value1);
        await secureStorage.write(key, value2);

        final readValue = await secureStorage.read(key);
        expect(readValue, equals(value2));
      });
    });

    group('Delete Operations', () {
      test('should delete specific key', () async {
        const key = 'test_key';
        const value = 'test_value';

        await secureStorage.write(key, value);
        final deleteResult = await secureStorage.delete(key);
        expect(deleteResult, isTrue);

        final readValue = await secureStorage.read(key);
        expect(readValue, isNull);
      });

      test('should delete all data', () async {
        await secureStorage.write('key1', 'value1');
        await secureStorage.write('key2', 'value2');
        await secureStorage.write('key3', 'value3');

        final deleteResult = await secureStorage.deleteAll();
        expect(deleteResult, isTrue);

        final allData = await secureStorage.readAll();
        expect(allData.isEmpty, isTrue);
      });
    });

    group('Read All Operations', () {
      test('should read all stored data', () async {
        await secureStorage.write('key1', 'value1');
        await secureStorage.write('key2', 'value2');
        await secureStorage.write('key3', 'value3');

        final allData = await secureStorage.readAll();
        expect(allData.length, equals(3));
        expect(allData['key1'], equals('value1'));
        expect(allData['key2'], equals('value2'));
        expect(allData['key3'], equals('value3'));
      });

      test('should return empty map when no data exists', () async {
        final allData = await secureStorage.readAll();
        expect(allData.isEmpty, isTrue);
      });
    });

    group('Contains Key Operations', () {
      test('should return true when key exists', () async {
        const key = 'test_key';
        const value = 'test_value';

        await secureStorage.write(key, value);
        final exists = await secureStorage.containsKey(key);
        expect(exists, isTrue);
      });

      test('should return false when key does not exist', () async {
        const key = 'non_existent_key';

        final exists = await secureStorage.containsKey(key);
        expect(exists, isFalse);
      });
    });

    group('Authentication Token Operations', () {
      test('should store and retrieve auth token', () async {
        const token = 'test_auth_token_12345';

        final storeResult = await secureStorage.storeAuthToken(token);
        expect(storeResult, isTrue);

        final retrievedToken = await secureStorage.getAuthToken();
        expect(retrievedToken, equals(token));
      });

      test('should delete auth token', () async {
        const token = 'test_auth_token_12345';

        await secureStorage.storeAuthToken(token);
        final deleteResult = await secureStorage.deleteAuthToken();
        expect(deleteResult, isTrue);

        final retrievedToken = await secureStorage.getAuthToken();
        expect(retrievedToken, isNull);
      });
    });

    group('User ID Operations', () {
      test('should store and retrieve user ID', () async {
        const userId = 'user_12345';

        final storeResult = await secureStorage.storeUserId(userId);
        expect(storeResult, isTrue);

        final retrievedUserId = await secureStorage.getUserId();
        expect(retrievedUserId, equals(userId));
      });

      test('should delete user ID', () async {
        const userId = 'user_12345';

        await secureStorage.storeUserId(userId);
        final deleteResult = await secureStorage.deleteUserId();
        expect(deleteResult, isTrue);

        final retrievedUserId = await secureStorage.getUserId();
        expect(retrievedUserId, isNull);
      });
    });

    group('Refresh Token Operations', () {
      test('should store and retrieve refresh token', () async {
        const refreshToken = 'refresh_token_12345';

        final storeResult = await secureStorage.storeRefreshToken(refreshToken);
        expect(storeResult, isTrue);

        final retrievedToken = await secureStorage.getRefreshToken();
        expect(retrievedToken, equals(refreshToken));
      });

      test('should delete refresh token', () async {
        const refreshToken = 'refresh_token_12345';

        await secureStorage.storeRefreshToken(refreshToken);
        final deleteResult = await secureStorage.deleteRefreshToken();
        expect(deleteResult, isTrue);

        final retrievedToken = await secureStorage.getRefreshToken();
        expect(retrievedToken, isNull);
      });
    });

    group('API Key Operations', () {
      test('should store and retrieve API key', () async {
        const apiKey = 'api_key_12345';

        final storeResult = await secureStorage.storeApiKey(apiKey);
        expect(storeResult, isTrue);

        final retrievedKey = await secureStorage.getApiKey();
        expect(retrievedKey, equals(apiKey));
      });

      test('should delete API key', () async {
        const apiKey = 'api_key_12345';

        await secureStorage.storeApiKey(apiKey);
        final deleteResult = await secureStorage.deleteApiKey();
        expect(deleteResult, isTrue);

        final retrievedKey = await secureStorage.getApiKey();
        expect(retrievedKey, isNull);
      });
    });

    group('Biometric Credentials Operations', () {
      test('should store and retrieve biometric credentials', () async {
        const credentials = 'encrypted_biometric_credentials';

        final storeResult =
            await secureStorage.storeBiometricCredentials(credentials);
        expect(storeResult, isTrue);

        final retrievedCredentials =
            await secureStorage.getBiometricCredentials();
        expect(retrievedCredentials, equals(credentials));
      });

      test('should delete biometric credentials', () async {
        const credentials = 'encrypted_biometric_credentials';

        await secureStorage.storeBiometricCredentials(credentials);
        final deleteResult = await secureStorage.deleteBiometricCredentials();
        expect(deleteResult, isTrue);

        final retrievedCredentials =
            await secureStorage.getBiometricCredentials();
        expect(retrievedCredentials, isNull);
      });
    });

    group('Clear Auth Data Operations', () {
      test('should clear all authentication data', () async {
        await secureStorage.storeAuthToken('token123');
        await secureStorage.storeRefreshToken('refresh123');
        await secureStorage.storeUserId('user123');
        await secureStorage.storeBiometricCredentials('creds123');

        final clearResult = await secureStorage.clearAuthData();
        expect(clearResult, isTrue);

        expect(await secureStorage.getAuthToken(), isNull);
        expect(await secureStorage.getRefreshToken(), isNull);
        expect(await secureStorage.getUserId(), isNull);
        expect(await secureStorage.getBiometricCredentials(), isNull);
      });
    });

    group('Error Handling', () {
      test('should handle empty string values', () async {
        const key = 'empty_key';
        const value = '';

        final writeResult = await secureStorage.write(key, value);
        expect(writeResult, isTrue);

        final readValue = await secureStorage.read(key);
        expect(readValue, equals(value));
      });

      test('should handle special characters in values', () async {
        const key = 'special_key';
        const value = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

        final writeResult = await secureStorage.write(key, value);
        expect(writeResult, isTrue);

        final readValue = await secureStorage.read(key);
        expect(readValue, equals(value));
      });

      test('should handle long string values', () async {
        const key = 'long_key';
        final value = 'a' * 1000;

        final writeResult = await secureStorage.write(key, value);
        expect(writeResult, isTrue);

        final readValue = await secureStorage.read(key);
        expect(readValue, equals(value));
        expect(readValue?.length, equals(1000));
      });
    });
  });
}
