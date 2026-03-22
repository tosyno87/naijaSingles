import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/secure_storage_service.dart';

/// One-time cutover guard that can force a single re-login after migration.
///
/// Enable by passing:
///   --dart-define=FORCE_RELOGIN_AFTER_MIGRATION=true
///   --dart-define=AUTH_MIGRATION_CUTOVER_EPOCH=`<integer>`
///
/// The epoch is persisted locally so each device only enforces sign-out once.
class MigrationSessionGuard {
  MigrationSessionGuard._();

  static const String _cutoverMarkerKey = 'auth_migration_cutover_epoch';
  static const bool _forceReLoginAfterMigration = bool.fromEnvironment(
    'FORCE_RELOGIN_AFTER_MIGRATION',
  );
  static const int _cutoverEpoch = int.fromEnvironment(
    'AUTH_MIGRATION_CUTOVER_EPOCH',
  );

  static Future<void> enforceIfRequired({
    required FirebaseAuth auth,
    required SecureStorageService storage,
  }) async {
    if (!_forceReLoginAfterMigration || _cutoverEpoch <= 0) {
      return;
    }

    final storedEpochRaw = await storage.read(_cutoverMarkerKey);
    final storedEpoch = int.tryParse(storedEpochRaw ?? '');
    if (storedEpoch == _cutoverEpoch) {
      if (kDebugMode) {
        log('MigrationSessionGuard: cutover already processed for this device');
      }
      return;
    }

    final user = auth.currentUser;
    if (user != null) {
      log(
        'MigrationSessionGuard: forcing one-time sign-out for cutover '
        '(uid=${user.uid}, cutover=$_cutoverEpoch)',
      );
      try {
        await auth.signOut();
      } on Object catch (e) {
        log('MigrationSessionGuard: Firebase signOut failed: $e');
      }
      await storage.clearAuthData();
    } else {
      log(
        'MigrationSessionGuard: no active session, recording cutover marker '
        '(cutover=$_cutoverEpoch)',
      );
    }

    await storage.write(_cutoverMarkerKey, _cutoverEpoch.toString());
  }
}
