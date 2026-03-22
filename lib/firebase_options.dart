import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;

import 'config/secure_config.dart';
import 'firebase_options_next_production.dart';
import 'firebase_options_staging.dart';

/// Build with --dart-define=ENV=production for prod, otherwise defaults to staging.
const String _env = String.fromEnvironment('ENV', defaultValue: 'staging');
const String productionProjectId = 'naijasingles-74a75';
const String nextProductionEnvironment = 'next-production';
bool get isProduction => _env == 'production';
bool get isNextProduction => _env == nextProductionEnvironment;
String get currentEnvironment => _env;

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!isProduction && !isNextProduction) {
      return StagingFirebaseOptions.currentPlatform;
    }
    if (isNextProduction) {
      return NextProductionFirebaseOptions.currentPlatform;
    }
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
  static FirebaseOptions get web {
    try {
      return FirebaseOptions(
        apiKey: SecureConfig.firebaseWebApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:web:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        authDomain: SecureConfig.firebaseAuthDomain,
        storageBucket: SecureConfig.firebaseStorageBucket,
      );
    } on Object {
      // Fallback to production values
      return const FirebaseOptions(
        apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
        appId: '1:888697307756:web:95ea92b8c7288e31704e49',
        messagingSenderId: '888697307756',
        projectId: productionProjectId,
        authDomain: 'naijasingles-74a75.firebaseapp.com',
        storageBucket: 'naijasingles-74a75.appspot.com',
      );
    }
  }

  // Android configuration
  static FirebaseOptions get android {
    try {
      return FirebaseOptions(
        apiKey: SecureConfig.firebaseAndroidApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:android:a62a339c4079bebc704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
      );
    } on Object {
      // Fallback to production values
      return const FirebaseOptions(
        apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
        appId: '1:888697307756:android:a62a339c4079bebc704e49',
        messagingSenderId: '888697307756',
        projectId: productionProjectId,
        storageBucket: 'naijasingles-74a75.appspot.com',
      );
    }
  }

  // iOS configuration
  // Using hardcoded values from GoogleService-Info.plist for production
  // Falls back to SecureConfig in development if .env is available
  static FirebaseOptions get ios {
    try {
      // Try to use SecureConfig if available (development with .env)
      return FirebaseOptions(
        apiKey: SecureConfig.firebaseIosApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:ios:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
        iosClientId: SecureConfig.firebaseIosClientId,
        iosBundleId: SecureConfig.firebaseIosBundleId,
      );
    } on Object {
      // Fallback to hardcoded production values from GoogleService-Info.plist
      // These values are safe to include in the app bundle
      return const FirebaseOptions(
        apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
        appId: '1:888697307756:ios:95ea92b8c7288e31704e49',
        messagingSenderId: '888697307756',
        projectId: productionProjectId,
        storageBucket: 'naijasingles-74a75.appspot.com',
        iosClientId:
            '888697307756-c0gm1rhh6f0dd7fh8f3geqbn12ctmmho.apps.googleusercontent.com',
        iosBundleId: 'com.app.naijasingles',
      );
    }
  }

  // macOS configuration
  static FirebaseOptions get macos {
    try {
      return FirebaseOptions(
        apiKey: SecureConfig.firebaseIosApiKey,
        appId:
            '1:${SecureConfig.firebaseMessagingSenderId}:ios:95ea92b8c7288e31704e49',
        messagingSenderId: SecureConfig.firebaseMessagingSenderId,
        projectId: SecureConfig.firebaseProjectId,
        storageBucket: SecureConfig.firebaseStorageBucket,
        iosClientId: SecureConfig.firebaseIosClientId,
        iosBundleId: SecureConfig.firebaseIosBundleId,
      );
    } on Object {
      // Fallback to production values (same as iOS)
      return const FirebaseOptions(
        apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
        appId: '1:888697307756:ios:95ea92b8c7288e31704e49',
        messagingSenderId: '888697307756',
        projectId: productionProjectId,
        storageBucket: 'naijasingles-74a75.appspot.com',
        iosClientId:
            '888697307756-c0gm1rhh6f0dd7fh8f3geqbn12ctmmho.apps.googleusercontent.com',
        iosBundleId: 'com.app.naijasingles',
      );
    }
  }
}

/// Helper class to connect to Firebase emulators in development
class FirebaseEmulators {
  /// Connect to Firebase emulators if in debug mode
  static void connectToEmulators() {
    // Disable emulator connections for production
    // ignore: dead_code
    if (false) {
      // Changed from kDebugMode to false to disable emulators
      try {
        FirebaseFirestore.instance.settings = const Settings(
          host: 'localhost:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );

        unawaited(FirebaseAuth.instance.useAuthEmulator('localhost', 9099));

        unawaited(
          FirebaseStorage.instance.useStorageEmulator('localhost', 9199),
        );

        debugPrint('🔥 Connected to Firebase emulators');
      } on Object catch (e) {
        debugPrint('❌ Failed to connect to Firebase emulators: $e');
      }
    }
  }
}
