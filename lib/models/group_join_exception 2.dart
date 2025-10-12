/// Custom exception for group join operations
enum GroupJoinErrorType {
  notAuthenticated,
  groupNotFound,
  alreadyMember,
  groupFull,
  groupInactive,
  permissionDenied,
  networkError,
  unknown,
}

class GroupJoinException implements Exception {
  final String message;
  final GroupJoinErrorType type;

  GroupJoinException(this.message, this.type);

  @override
  String toString() => 'GroupJoinException: $message';
}

/// Result class for group join operations
class GroupJoinResult {
  final bool success;
  final String? groupName;
  final GroupJoinException? error;

  GroupJoinResult._(this.success, this.groupName, this.error);

  factory GroupJoinResult.success(String groupName) =>
      GroupJoinResult._(true, groupName, null);

  factory GroupJoinResult.failure(GroupJoinException error) =>
      GroupJoinResult._(false, null, error);
}
