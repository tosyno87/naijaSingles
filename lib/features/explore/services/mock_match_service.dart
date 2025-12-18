import 'match_service.dart';

/// A mock implementation of MatchService for testing purposes
class MockMatchService extends MatchService {
  // Override the checkForMatch method to always return true
  @override
  Future<bool> checkForMatch(String currentUserId, String likedUserId) async {
    // Always return true for guaranteed matches during testing
    return true;
  }

  // Override the createMessageThread method to return a mock thread ID
  @override
  Future<String> createMessageThread(
      String currentUserId, String matchedUserId,) async {
    // For testing, just return a mock thread ID
    return 'mock_thread_${currentUserId}_$matchedUserId';
  }

  // Override the markAsMatched method to do nothing
  @override
  Future<void> markAsMatched(String currentUserId, String matchedUserId) async {
    // Do nothing for testing
    return;
  }

  // Override the saveLike method to do nothing
  @override
  Future<void> saveLike(String currentUserId, String likedUserId) async {
    // Do nothing for testing
    return;
  }
}
