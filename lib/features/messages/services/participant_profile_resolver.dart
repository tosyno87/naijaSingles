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
  ///
  /// Pass [matchedPeerIds] from [loadMatchedPeerIds] when enriching many
  /// threads so each call is an O(1) set lookup instead of a full match scan.
  Future<void> ensureMatchMirrors({
    required String currentUserId,
    required String otherUserId,
    Set<String>? matchedPeerIds,
  }) async {
    if (currentUserId.isEmpty ||
        otherUserId.isEmpty ||
        currentUserId == otherUserId) {
      return;
    }

    try {
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
      final DocumentSnapshot<Map<String, dynamic>> mineSnap = snaps[0];
      final DocumentSnapshot<Map<String, dynamic>> theirsSnap = snaps[1];

      // Both mirrors present — nothing to do (no top-level scan).
      if (mineSnap.exists && theirsSnap.exists) {
        return;
      }

      // One-sided local mirror: repair the opposite without re-scanning matches.
      // Local mirror implies a prior verified write or match creation path.
      if (mineSnap.exists && !theirsSnap.exists) {
        await theirs.set(<String, Object?>{
          'Matches': currentUserId,
          'userId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return;
      }

      final bool matched = matchedPeerIds != null
          ? matchedPeerIds.contains(otherUserId)
          : await _hasTopLevelMatch(currentUserId, otherUserId);
      if (!matched) {
        return;
      }

      final List<Future<void>> writes = <Future<void>>[];
      if (!mineSnap.exists) {
        writes.add(
          mine.set(<String, Object?>{
            'Matches': otherUserId,
            'userId': otherUserId,
            'timestamp': FieldValue.serverTimestamp(),
          }),
        );
      }
      if (!theirsSnap.exists) {
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

  /// Loads peer user IDs from top-level `matches` / `Matches` once per snapshot.
  Future<Set<String>> loadMatchedPeerIds(String currentUserId) async {
    if (currentUserId.isEmpty) {
      return <String>{};
    }

    final Set<String> peers = <String>{};
    try {
      final QuerySnapshot<Map<String, dynamic>> modern = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in modern.docs) {
        final List<String> users =
            List<String>.from(doc.data()['users'] as List? ?? const <String>[]);
        for (final String id in users) {
          if (id.isNotEmpty && id != currentUserId) {
            peers.add(id);
          }
        }
      }

      final QuerySnapshot<Map<String, dynamic>> legacy = await _firestore
          .collection('Matches')
          .where('users', arrayContains: currentUserId)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in legacy.docs) {
        final Map<String, dynamic> data = doc.data();
        final List<String> users =
            List<String>.from(data['users'] as List? ?? const <String>[]);
        for (final String id in users) {
          if (id.isNotEmpty && id != currentUserId) {
            peers.add(id);
          }
        }
        final Object? user1 = data['user1'];
        final Object? user2 = data['user2'];
        if (user1 == currentUserId && user2 is String && user2.isNotEmpty) {
          peers.add(user2);
        } else if (user2 == currentUserId &&
            user1 is String &&
            user1.isNotEmpty) {
          peers.add(user1);
        }
      }
    } on FirebaseException catch (_) {
      return peers;
    }
    return peers;
  }

  /// True when [userId1] and [userId2] appear together in top-level match docs.
  Future<bool> _hasTopLevelMatch(String userId1, String userId2) async {
    final Set<String> peers = await loadMatchedPeerIds(userId1);
    return peers.contains(userId2);
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
