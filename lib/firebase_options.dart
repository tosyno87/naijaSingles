import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kDebugMode, TargetPlatform, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
    appId: '1:888697307756:web:95ea92b8c7288e31704e49',
    messagingSenderId: '888697307756',
    projectId: 'naijasingles-74a75',
    authDomain: 'naijasingles-74a75.firebaseapp.com',
    storageBucket: 'naijasingles-74a75.appspot.com',
  );

  // Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBX7hxCR3XPWOShZu-vundYxocvQj_zH48',
    appId: '1:888697307756:android:a62a339c4079bebc704e49',
    messagingSenderId: '888697307756',
    projectId: 'naijasingles-74a75',
    storageBucket: 'naijasingles-74a75.appspot.com',
  );

  // iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
    appId: '1:888697307756:ios:95ea92b8c7288e31704e49',
    messagingSenderId: '888697307756',
    projectId: 'naijasingles-74a75',
    storageBucket: 'naijasingles-74a75.appspot.com',
    iosClientId: '888697307756-abcdefg.apps.googleusercontent.com',
    iosBundleId: 'com.app.naijasingles',
  );

  // macOS configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
    appId: '1:888697307756:ios:95ea92b8c7288e31704e49',
    messagingSenderId: '888697307756',
    projectId: 'naijasingles-74a75',
    storageBucket: 'naijasingles-74a75.appspot.com',
    iosClientId: '888697307756-abcdefg.apps.googleusercontent.com',
    iosBundleId: 'com.app.naijasingles',
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
