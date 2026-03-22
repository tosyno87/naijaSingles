import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const String _nextProdProjectId = String.fromEnvironment('NEXT_PROD_PROJECT_ID');
const String _nextProdStorageBucket = String.fromEnvironment(
  'NEXT_PROD_STORAGE_BUCKET',
);
const String _nextProdMessagingSenderId = String.fromEnvironment(
  'NEXT_PROD_MESSAGING_SENDER_ID',
);
const String _nextProdAuthDomain = String.fromEnvironment('NEXT_PROD_AUTH_DOMAIN');

const String _nextProdWebApiKey = String.fromEnvironment('NEXT_PROD_WEB_API_KEY');
const String _nextProdWebAppId = String.fromEnvironment('NEXT_PROD_WEB_APP_ID');

const String _nextProdAndroidApiKey = String.fromEnvironment(
  'NEXT_PROD_ANDROID_API_KEY',
);
const String _nextProdAndroidAppId = String.fromEnvironment(
  'NEXT_PROD_ANDROID_APP_ID',
);

const String _nextProdIosApiKey = String.fromEnvironment(
  'NEXT_PROD_IOS_API_KEY',
);
const String _nextProdIosAppId = String.fromEnvironment('NEXT_PROD_IOS_APP_ID');
const String _nextProdIosClientId = String.fromEnvironment(
  'NEXT_PROD_IOS_CLIENT_ID',
);
const String _nextProdIosBundleId = String.fromEnvironment(
  'NEXT_PROD_IOS_BUNDLE_ID',
  defaultValue: 'com.app.naijasingles',
);

String _required(String value, String name) {
  if (value.trim().isEmpty) {
    throw StateError(
      'Missing required --dart-define=$name for ENV=next-production.',
    );
  }
  return value;
}

class NextProductionFirebaseOptions {
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
          'NextProductionFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _required(_nextProdWebApiKey, 'NEXT_PROD_WEB_API_KEY'),
        appId: _required(_nextProdWebAppId, 'NEXT_PROD_WEB_APP_ID'),
        messagingSenderId: _required(
          _nextProdMessagingSenderId,
          'NEXT_PROD_MESSAGING_SENDER_ID',
        ),
        projectId: _required(_nextProdProjectId, 'NEXT_PROD_PROJECT_ID'),
        authDomain: _required(_nextProdAuthDomain, 'NEXT_PROD_AUTH_DOMAIN'),
        storageBucket: _required(
          _nextProdStorageBucket,
          'NEXT_PROD_STORAGE_BUCKET',
        ),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _required(
          _nextProdAndroidApiKey,
          'NEXT_PROD_ANDROID_API_KEY',
        ),
        appId: _required(_nextProdAndroidAppId, 'NEXT_PROD_ANDROID_APP_ID'),
        messagingSenderId: _required(
          _nextProdMessagingSenderId,
          'NEXT_PROD_MESSAGING_SENDER_ID',
        ),
        projectId: _required(_nextProdProjectId, 'NEXT_PROD_PROJECT_ID'),
        storageBucket: _required(
          _nextProdStorageBucket,
          'NEXT_PROD_STORAGE_BUCKET',
        ),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _required(_nextProdIosApiKey, 'NEXT_PROD_IOS_API_KEY'),
        appId: _required(_nextProdIosAppId, 'NEXT_PROD_IOS_APP_ID'),
        messagingSenderId: _required(
          _nextProdMessagingSenderId,
          'NEXT_PROD_MESSAGING_SENDER_ID',
        ),
        projectId: _required(_nextProdProjectId, 'NEXT_PROD_PROJECT_ID'),
        storageBucket: _required(
          _nextProdStorageBucket,
          'NEXT_PROD_STORAGE_BUCKET',
        ),
        iosClientId: _required(_nextProdIosClientId, 'NEXT_PROD_IOS_CLIENT_ID'),
        iosBundleId: _nextProdIosBundleId,
      );
}
