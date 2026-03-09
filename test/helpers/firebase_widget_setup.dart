// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void _setupFirebaseAuthPigeonMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();

  final channels = [
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
  ];

  for (final channel in channels) {
    messenger.setMockMessageHandler(
      channel,
      (ByteData? message) async =>
          codec.encodeMessage(<Object?>['mock_listener_id']),
    );
  }
}

Future<void> setupFirebaseForWidgetTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  _setupFirebaseAuthPigeonMocks();
  await Firebase.initializeApp();
}
