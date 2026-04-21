/// Returned from profile detail when the viewer should update Discover queues.
///
/// [removedFromQueue] is true after a new like or match so the parent can
/// remove this profile from "People Near You" immediately (Back alone uses
/// `null` / [removedFromQueue] false).
class DiscoverProfileDismissResult {
  const DiscoverProfileDismissResult({
    required this.userId,
    required this.removedFromQueue,
    this.wasMatch = false,
    this.wasPass = false,
  });

  final String userId;
  final bool removedFromQueue;
  final bool wasMatch;
  final bool wasPass;
}
