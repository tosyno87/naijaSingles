import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up Firebase for testing environment
class FirebaseTestSetup {
  static bool _initialized = false;

  /// Initialize Firebase for testing
  static Future<void> setupFirebase() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup method channel mocks
    setupFirebaseCoreMocks();
    setupFirebaseAuthMocks();
    setupFirestoreMocks();

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
          storageBucket: 'test-storage-bucket',
        ),
      );
      _initialized = true;
    } catch (e) {
      // Firebase already initialized
      _initialized = true;
    }
  }

  /// Setup Firebase Core mocks
  static void setupFirebaseCoreMocks() {
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'messagingSenderId': 'test-sender-id',
                'projectId': 'test-project-id',
                'storageBucket': 'test-storage-bucket',
              },
              'pluginConstants': {},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
            'options': methodCall.arguments['options'],
            'pluginConstants': {},
          };
        default:
          return null;
      }
    });
  }

  /// Setup Firebase Auth mocks
  static void setupFirebaseAuthMocks() {
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Auth#registerIdTokenListener':
          return {
            'nextWrappedValue': null,
            'error': null,
          };
        case 'Auth#registerAuthStateListener':
          return {
            'nextWrappedValue': null,
            'error': null,
          };
        case 'Auth#signInWithCredential':
          return {
            'user': {
              'uid': 'test-uid',
              'email': 'test@example.com',
              'displayName': 'Test User',
            },
          };
        case 'Auth#signInWithEmailAndPassword':
          return {
            'user': {
              'uid': 'test-uid',
              'email': methodCall.arguments['email'],
              'displayName': 'Test User',
            },
          };
        case 'Auth#verifyPhoneNumber':
          return null;
        case 'Auth#currentUser':
          return null;
        default:
          return null;
      }
    });
  }

  /// Setup Firestore mocks
  static void setupFirestoreMocks() {
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firestore#settings':
          return null;
        case 'Query#snapshots':
          return {
            'paths': [],
            'documents': [],
            'documentChanges': [],
            'metadata': {
              'hasPendingWrites': false,
              'isFromCache': false,
            },
          };
        case 'DocumentReference#snapshots':
          return {
            'path': methodCall.arguments['path'],
            'data': {},
            'metadata': {
              'hasPendingWrites': false,
              'isFromCache': false,
            },
          };
        case 'DocumentReference#set':
        case 'DocumentReference#update':
        case 'DocumentReference#delete':
          return null;
        case 'Query#get':
          return {
            'paths': [],
            'documents': [],
            'metadata': {
              'hasPendingWrites': false,
              'isFromCache': false,
            },
          };
        case 'DocumentReference#get':
          return {
            'path': methodCall.arguments['path'],
            'data': null,
            'metadata': {
              'hasPendingWrites': false,
              'isFromCache': false,
            },
          };
        default:
          return null;
      }
    });
  }

  /// Cleanup Firebase test setup
  static void cleanup() {
    const MethodChannel('plugins.flutter.io/firebase_core')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/firebase_auth')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/cloud_firestore')
        .setMockMethodCallHandler(null);
  }
}
