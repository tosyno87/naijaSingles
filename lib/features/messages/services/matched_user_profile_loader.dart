import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';

/// Loads a matched user's profile for Messages, with thread-cache fallback.
///
/// Firestore may deny reads for private/paused profiles even between matches.
/// When that happens, we still open a limited profile using chat thread data.
class MatchedUserProfileLoader {
  static Future<UserModel> load({
    required FirebaseFirestore firestore,
    required String userId,
    required String fallbackName,
    String? fallbackAvatarUrl,
  }) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return buildFallback(
      userId: userId,
      fallbackName: fallbackName,
      fallbackAvatarUrl: fallbackAvatarUrl,
    );
  }

  static UserModel buildFallback({
    required String userId,
    required String fallbackName,
    String? fallbackAvatarUrl,
  }) =>
      _fallbackUser(
        userId: userId,
        fallbackName: fallbackName,
        fallbackAvatarUrl: fallbackAvatarUrl,
      );

  static UserModel _fallbackUser({
    required String userId,
    required String fallbackName,
    String? fallbackAvatarUrl,
  }) =>
      UserModel(
        id: userId,
        name: fallbackName,
        age: 18,
        imageUrl: fallbackAvatarUrl != null && fallbackAvatarUrl.isNotEmpty
            ? [fallbackAvatarUrl]
            : [],
        editInfo: const {},
      );
}
