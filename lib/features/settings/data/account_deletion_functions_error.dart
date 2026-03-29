import 'package:cloud_functions/cloud_functions.dart';

/// Parses [FirebaseFunctionsException.details] when the server returns a map.
class AccountDeletionFunctionsDetails {
  AccountDeletionFunctionsDetails({
    this.retryAfterSeconds,
    this.attemptsRemaining,
  });

  final int? retryAfterSeconds;
  final int? attemptsRemaining;

  static AccountDeletionFunctionsDetails? fromException(
    FirebaseFunctionsException e,
  ) {
    final raw = e.details;
    if (raw is! Map) {
      return null;
    }
    final map = Map<Object?, Object?>.from(raw);
    int? intVal(Object? key) {
      final v = map[key];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.round();
      }
      return null;
    }

    return AccountDeletionFunctionsDetails(
      retryAfterSeconds: intVal('retryAfterSeconds'),
      attemptsRemaining: intVal('attemptsRemaining'),
    );
  }

  String? userMessageSuffix() {
    final parts = <String>[];
    final retry = retryAfterSeconds;
    if (retry != null && retry > 0) {
      parts.add('Try again in ${retry}s.');
    }
    final left = attemptsRemaining;
    if (left != null) {
      parts.add(
        left == 0
            ? 'No attempts left for this code.'
            : '$left ${left == 1 ? 'attempt' : 'attempts'} left.',
      );
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }
}
