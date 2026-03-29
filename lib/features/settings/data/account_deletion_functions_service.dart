import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../common/utils/app_logger.dart';

/// Callable Cloud Functions for backend-driven account deletion.
///
/// - **Direct**: [deleteAccountDirect] with active ID token (no OTP challenge).
/// - Legacy OTP callables remain available for rollback/testing paths.
///
/// All callables must be deployed in [callableRegion] for the active Firebase project.
class AccountDeletionFunctionsService {
  AccountDeletionFunctionsService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(
              app: (auth ?? FirebaseAuth.instance).app,
              region: callableRegion,
            );

  static const String callableRegion = 'us-central1';

  final FirebaseFunctions _functions;

  void _logInvoke(String callableName) {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData.map((p) => p.providerId).join(', ');
    final projectId = Firebase.app().options.projectId;
    AppLogger.debug(
      'AccountDeletionFunctions: httpsCallable("$callableName") '
      'region=$callableRegion project=$projectId '
      'uid=${user?.uid ?? "none"} providers=${providers ?? "none"}',
    );
  }

  /// Sends a one-time code to the account email on file.
  Future<Map<String, dynamic>> startDeletionEmailOtp({
    Map<String, String>? clientMeta,
  }) async {
    _logInvoke('startDeletionOtp');
    final callable = _functions.httpsCallable('startDeletionOtp');
    final result = await callable.call<Map<String, dynamic>>({
      'channel': 'email',
      if (clientMeta != null && clientMeta.isNotEmpty) 'clientMeta': clientMeta,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<void> confirmDeletionOtp({
    required String code,
    required String reason,
    String? customReason,
    Map<String, String>? clientMeta,
  }) async {
    _logInvoke('confirmDeletionOtp');
    final callable = _functions.httpsCallable('confirmDeletionOtp');
    await callable.call<Map<String, dynamic>>({
      'code': code,
      'reason': reason,
      if (customReason != null && customReason.isNotEmpty)
        'customReason': customReason,
      if (clientMeta != null && clientMeta.isNotEmpty) 'clientMeta': clientMeta,
    });
  }

  /// After phone re-verification, pass [idToken] from [User.getIdToken] (refresh recommended).
  Future<void> confirmDeletionAfterPhoneProof({
    required String idToken,
    required String reason,
    String? customReason,
    Map<String, String>? clientMeta,
  }) async {
    _logInvoke('confirmDeletionAfterPhoneProof');
    final callable = _functions.httpsCallable('confirmDeletionAfterPhoneProof');
    await callable.call<Map<String, dynamic>>({
      'idToken': idToken,
      'reason': reason,
      if (customReason != null && customReason.isNotEmpty)
        'customReason': customReason,
      if (clientMeta != null && clientMeta.isNotEmpty) 'clientMeta': clientMeta,
    });
  }

  /// Direct delete path: verify active session token on backend and delete.
  Future<void> deleteAccountDirect({
    required String idToken,
    required String reason,
    String? customReason,
    Map<String, String>? clientMeta,
  }) async {
    _logInvoke('deleteAccountDirect');
    final callable = _functions.httpsCallable('deleteAccountDirect');
    await callable.call<Map<String, dynamic>>({
      'idToken': idToken,
      'reason': reason,
      if (customReason != null && customReason.isNotEmpty)
        'customReason': customReason,
      if (clientMeta != null && clientMeta.isNotEmpty) 'clientMeta': clientMeta,
    });
  }
}
