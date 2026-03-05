import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class StagingFirebaseOptions {
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
        return ios;
      default:
        throw UnsupportedError(
          'StagingFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxaaVmF_L9T7LXlA7k02Um90wBgfV8hxU',
    appId: '1:957937877432:web:fd76ec53f77ab833268f4d',
    messagingSenderId: '957937877432',
    projectId: 'naijasingles-staging',
    authDomain: 'naijasingles-staging.firebaseapp.com',
    storageBucket: 'naijasingles-staging.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlkoLcV-QC8XmIdEHhC2eu0MHAs34Ma_g',
    appId: '1:957937877432:android:674c7897fa636804268f4d',
    messagingSenderId: '957937877432',
    projectId: 'naijasingles-staging',
    storageBucket: 'naijasingles-staging.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDlkoLcV-QC8XmIdEHhC2eu0MHAs34Ma_g',
    appId: '1:957937877432:ios:235d48e63ac9be6b268f4d',
    messagingSenderId: '957937877432',
    projectId: 'naijasingles-staging',
    storageBucket: 'naijasingles-staging.firebasestorage.app',
    iosBundleId: 'com.app.naijasingles.staging',
  );
}
