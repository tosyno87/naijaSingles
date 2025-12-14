import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kDebugMode, TargetPlatform, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'config/secure_config.dart';

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: SecureConfig.firebaseWebApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:web:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        authDomain: SecureConfig.firebaseAuthDomain,
        storageBucket: SecureConfig.firebaseStorageBucket,
      );

  // Android configuration
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: SecureConfig.firebaseAndroidApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:android:a62a339c4079bebc704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
      );

  // iOS configuration
  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: SecureConfig.firebaseIosApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:ios:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
        iosClientId: SecureConfig.firebaseIosClientId,
        iosBundleId: SecureConfig.firebaseIosBundleId,
      );

  // macOS configuration
  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: SecureConfig.firebaseIosApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:ios:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
        iosClientId: SecureConfig.firebaseIosClientId,
        iosBundleId: SecureConfig.firebaseIosBundleId,
      );
}

/// Helper class to connect to Firebase emulators in development
class FirebaseEmulators {
  /// Connect to Firebase emulators if in debug mode
  static void connectToEmulators() {
    // Disable emulator connections for production
    if (false) {
      // Changed from kDebugMode to false to disable emulators
      try {
        FirebaseFirestore.instance.settings = const Settings(
          host: 'localhost:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );

        FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

        FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

        debugPrint('🔥 Connected to Firebase emulators');
      } catch (e) {
        debugPrint('❌ Failed to connect to Firebase emulators: $e');
      }
    }
  }
}
