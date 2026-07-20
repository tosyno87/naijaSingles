import 'package:cloud_firestore/cloud_firestore.dart';

/// Live name + avatar for a chat participant, with thread-cache fallback.
class ParticipantDisplayInfo {
  const ParticipantDisplayInfo({
    required this.userId,
    required this.name,
    required this.fromLiveProfile,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final bool fromLiveProfile;
}

/// Resolves display identity from `users/{uid}`, falling back to thread cache.
class ParticipantProfileResolver {
  ParticipantProfileResolver({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Set<String> _placeholderNames = <String>{
    'phone user',
    'user',
    'unknown user',
    'email user',
    'someone',
  };

  /// True when [name] is empty or a known seed/placeholder label.
  static bool isPlaceholderName(String? name) {
    if (name == null) return true;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    return _placeholderNames.contains(trimmed.toLowerCase());
  }

  /// Prefer live Firestore profile; on missing doc or permission-denied use cache.
  Future<ParticipantDisplayInfo> resolve({
    required String userId,
    String? cachedName,
    String? cachedAvatarUrl,
  }) async {
    final String? usableCache =
        isPlaceholderName(cachedName) ? null : cachedName?.trim();
    final String fallbackName = usableCache ?? 'User';

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final Map<String, dynamic>? data = doc.data();
        final String? liveName = _readName(data);
        final String? liveAvatar = _readFirstPhoto(data);
        final String resolvedName =
            (liveName != null && !isPlaceholderName(liveName))
                ? liveName
                : fallbackName;
        return ParticipantDisplayInfo(
          userId: userId,
          name: resolvedName,
          avatarUrl: liveAvatar ?? cachedAvatarUrl,
          fromLiveProfile: true,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return ParticipantDisplayInfo(
      userId: userId,
      name: fallbackName,
      avatarUrl: cachedAvatarUrl,
      fromLiveProfile: false,
    );
  }

  /// Creates bidirectional `users/{uid}/Matches/{other}` mirrors so
  /// [canReadUserProfile] / [hasLegacyMatchWith] allow live profile reads.
  ///
  /// Only writes after proving a top-level `matches` / legacy `Matches`
  /// document exists for the pair — never invents match state from a chat
  /// thread alone (seeded/forged threads must not gain profile-read access).
  Future<void> ensureMatchMirrors({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty ||
        otherUserId.isEmpty ||
        currentUserId == otherUserId) {
      return;
    }

    try {
      final bool matched = await _hasTopLevelMatch(currentUserId, otherUserId);
      if (!matched) {
        return;
      }

      final DocumentReference<Map<String, dynamic>> mine = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('Matches')
          .doc(otherUserId);
      final DocumentReference<Map<String, dynamic>> theirs = _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('Matches')
          .doc(currentUserId);

      final List<DocumentSnapshot<Map<String, dynamic>>> snaps =
          await Future.wait(<Future<DocumentSnapshot<Map<String, dynamic>>>>[
        mine.get(),
        theirs.get(),
      ]);

      final List<Future<void>> writes = <Future<void>>[];
      if (!snaps[0].exists) {
        writes.add(
          mine.set(<String, Object?>{
            'Matches': otherUserId,
            'userId': otherUserId,
            'timestamp': FieldValue.serverTimestamp(),
          }),
        );
      }
      if (!snaps[1].exists) {
        writes.add(
          theirs.set(<String, Object?>{
            'Matches': currentUserId,
            'userId': currentUserId,
            'timestamp': FieldValue.serverTimestamp(),
          }),
        );
      }
      if (writes.isNotEmpty) {
        await Future.wait(writes);
      }
    } on FirebaseException catch (_) {
      // Best-effort; profile resolve will fall back to thread cache.
    }
  }

  /// True when [userId1] and [userId2] appear together in top-level match docs.
  Future<bool> _hasTopLevelMatch(String userId1, String userId2) async {
    final QuerySnapshot<Map<String, dynamic>> modern = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId1)
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in modern.docs) {
      final List<String> users =
          List<String>.from(doc.data()['users'] as List? ?? const <String>[]);
      if (users.contains(userId2)) {
        return true;
      }
    }

    final QuerySnapshot<Map<String, dynamic>> legacy = await _firestore
        .collection('Matches')
        .where('users', arrayContains: userId1)
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in legacy.docs) {
      final Map<String, dynamic> data = doc.data();
      final List<String> users =
          List<String>.from(data['users'] as List? ?? const <String>[]);
      if (users.contains(userId2)) {
        return true;
      }
      if ((data['user1'] == userId1 && data['user2'] == userId2) ||
          (data['user1'] == userId2 && data['user2'] == userId1)) {
        return true;
      }
    }

    return false;
  }

  /// Updates denormalized thread fields when live values differ from cache.
  Future<void> writeThroughThreadCache({
    required String threadId,
    required String userId,
    required String name,
    String? avatarUrl,
    String? cachedName,
    String? cachedAvatarUrl,
  }) async {
    if (isPlaceholderName(name)) {
      return;
    }

    final bool nameChanged =
        name != cachedName || isPlaceholderName(cachedName);
    final bool avatarChanged = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != cachedAvatarUrl;
    if (!nameChanged && !avatarChanged) {
      return;
    }

    final Map<String, Object?> updates = <String, Object?>{};
    if (nameChanged) {
      updates['userNames.$userId'] = name;
    }
    if (avatarChanged) {
      updates['userAvatars.$userId'] = avatarUrl;
    }

    try {
      await _firestore.collection('chatThreads').doc(threadId).update(updates);
    } on FirebaseException catch (_) {
      // Best-effort cache refresh; UI already shows live values.
    }
  }

  static String? _readName(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final String key in <String>['name', 'UserName', 'displayName']) {
      final Object? raw = data[key];
      if (raw is String && raw.trim().isNotEmpty) {
        final String trimmed = raw.trim();
        if (!isPlaceholderName(trimmed)) {
          return trimmed;
        }
      }
    }
    return null;
  }

  static String? _readFirstPhoto(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final String key in <String>['photos', 'Pictures']) {
      final Object? raw = data[key];
      if (raw is List && raw.isNotEmpty) {
        final Object? first = raw.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }
    return null;
  }

  /// Visible for unit tests.
  static String? readNameForTest(Map<String, dynamic>? data) => _readName(data);

  /// Visible for unit tests.
  static String? readFirstPhotoForTest(Map<String, dynamic>? data) =>
      _readFirstPhoto(data);
}
