/// Result of attempting to record a like (and optionally create a match).
enum LikeHandleStatus {
  /// No signed-in user; no write attempted.
  notAuthenticated,

  /// Invalid from/to user id; no write attempted.
  invalidInput,

  /// Users were already matched.
  existingMatch,

  /// A new mutual match was created (or ensured).
  matchCreated,

  /// A new like document was written; no match yet (or match creation failed after write).
  likeRecorded,

  /// Forward like already existed and there was nothing new to do (no mutual completion).
  alreadyLiked,
}

class LikeHandleOutcome {
  const LikeHandleOutcome({
    required this.status,
    this.matchId,
  });

  final LikeHandleStatus status;

  /// Set when [status] is [LikeHandleStatus.existingMatch] or [LikeHandleStatus.matchCreated].
  final String? matchId;
}
