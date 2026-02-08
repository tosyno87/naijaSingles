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
  GroupJoinException(this.message, this.type);
  final String message;
  final GroupJoinErrorType type;

  @override
  String toString() => 'GroupJoinException: $message';
}

/// Result class for group join operations
class GroupJoinResult {
  GroupJoinResult._(this.success, this.groupName, this.error);

  factory GroupJoinResult.success(String groupName) =>
      GroupJoinResult._(true, groupName, null);

  factory GroupJoinResult.failure(GroupJoinException error) =>
      GroupJoinResult._(false, null, error);
  final bool success;
  final String? groupName;
  final GroupJoinException? error;
}
