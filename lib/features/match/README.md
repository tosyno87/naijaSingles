# Mutual Likes Detection & Match System

This module implements a comprehensive mutual likes detection system that automatically creates matches and chat threads when two users like each other.

## 🎯 Features

- **Mutual Like Detection**: Automatically detects when two users have liked each other
- **Match Creation**: Creates match documents with chat thread integration
- **Real-time Updates**: Uses BLoC pattern for reactive UI updates
- **Backward Compatibility**: Maintains compatibility with existing legacy match system
- **Chat Integration**: Automatically creates chat threads for new matches
- **Match Notifications**: Beautiful animated match dialogs

## 📁 File Structure

```
lib/features/match/
├── bloc/
│   ├── match_bloc.dart          # Main BLoC for match operations
│   ├── match_event.dart         # Match events
│   └── match_state.dart         # Match states
├── models/
│   ├── like_model.dart          # Like data model
│   └── match_model.dart         # Match data model (updated)
├── services/
│   ├── likes_service.dart       # Core likes & match logic
│   └── match_service.dart       # Match service (updated)
├── ui/
│   ├── match_notification_dialog.dart    # Match celebration dialog
│   └── swipe_integration_example.dart    # Integration example
└── README.md                    # This file
```

## 🔥 Firestore Structure

### Likes Collection
```
likes/{userAId}_likes_{userBId}
{
  "from": "userAId",
  "to": "userBId", 
  "timestamp": Timestamp.now()
}
```

### Matches Collection
```
matches/{matchId}
{
  "users": ["userAId", "userBId"],
  "matchedAt": Timestamp.now(),
  "chatThreadId": "auto-generated-id",
  "matchStatus": "matched"
}
```

### Chat Threads Collection
```
chatThreads/{chatThreadId}
{
  "userIds": ["userAId", "userBId"],
  "userNames": {
    "userAId": "User A Name",
    "userBId": "User B Name"
  },
  "lastMessage": null,
  "lastMessageText": "You matched! Say hello!",
  "lastUpdated": Timestamp.now(),
  "createdAt": Timestamp.now(),
  "unreadCount": {
    "userAId": 0,
    "userBId": 0
  }
}
```

## 🚀 Usage

### Basic Like Handling

```dart
// Using MatchService directly
final matchService = MatchService();
final matchId = await matchService.handleLike('otherUserId');

if (matchId != null) {
  print('🎉 Match created! ID: $matchId');
} else {
  print('Like saved, waiting for mutual like');
}
```

### Using BLoC Pattern

```dart
// In your widget
BlocProvider<MatchBloc>(
  create: (context) => MatchBloc(),
  child: YourSwipeScreen(),
)

// Trigger like
context.read<MatchBloc>().add(LikeUserEvent(toUserId: 'userId'));

// Listen for matches
BlocListener<MatchBloc, MatchState>(
  listener: (context, state) {
    if (state is MatchCreated) {
      showMatchDialog(
        context,
        matchId: state.matchId,
        otherUserId: state.otherUserId,
        chatThreadId: state.chatThreadId,
      );
    }
  },
  child: YourWidget(),
)
```

### Integration with Existing Swipe System

The system automatically integrates with your existing swipe functionality:

```dart
// In UserSearchRepo.rightSwipe() - already integrated
static Future<void> rightSwipe(UserModel currentUser, UserModel selectedUser) async {
  // New mutual like detection
  final matchId = await _likesService.handleLike(currentUser.id, selectedUser.id);
  
  if (matchId != null) {
    debugPrint("🎉 Match created! Match ID: $matchId");
  }
  
  // Legacy compatibility code continues...
}
```

## 🎨 UI Components

### Match Notification Dialog

Beautiful animated dialog that appears when a match is created:

```dart
showMatchDialog(
  context,
  matchId: 'match-id',
  otherUserId: 'other-user-id',
  chatThreadId: 'chat-thread-id',
  otherUser: userModel, // Optional user data
);
```

Features:
- Smooth scale and fade animations
- Gradient background
- User avatars display
- "Keep Swiping" and "Say Hello!" buttons
- Automatic chat navigation

## 🔧 API Reference

### LikesService

#### Core Methods

- `handleLike(String fromUserId, String toUserId)` → `Future<String?>`
  - Main method for processing likes and detecting mutual matches
  - Returns match ID if mutual match created, null otherwise

- `hasUserLiked(String fromUserId, String toUserId)` → `Future<bool>`
  - Check if user has already liked another user

- `getUsersWhoLikedMe(String userId)` → `Future<List<String>>`
  - Get list of users who liked the current user

- `getUserMatches(String userId)` → `Future<List<MatchModel>>`
  - Get all matches for a user

- `getMatchesStream(String userId)` → `Stream<List<MatchModel>>`
  - Real-time stream of user matches

### MatchService

#### Updated Methods

- `handleLike(String toUserId)` → `Future<String?>`
  - Wrapper around LikesService.handleLike for current user

- `getUserMatches()` → `Future<List<MatchModel>>`
  - Get matches for current user

- `hasUserLiked(String toUserId)` → `Future<bool>`
  - Check if current user has liked another user

### MatchBloc

#### Events

- `LikeUserEvent(toUserId)` - Like a user
- `LoadMatchesEvent()` - Load user matches
- `UnlikeUserEvent(toUserId)` - Unlike a user
- `DeleteMatchEvent(matchId)` - Delete a match

#### States

- `MatchCreated` - Match successfully created
- `LikeSuccess` - Like processed (with/without match)
- `MatchesLoaded` - Matches loaded
- `MatchError` - Error occurred

## 🔄 Migration Guide

The new system is designed to be backward compatible. Existing functionality will continue to work while new features are gradually adopted.

### Existing Code
```dart
// This continues to work
await UserSearchRepo.rightSwipe(currentUser, selectedUser);
```

### Enhanced Code
```dart
// New approach with match detection
context.read<MatchBloc>().add(LikeUserEvent(toUserId: selectedUser.id));
```

## 🧪 Testing

### Unit Tests

```dart
// Test like handling
test('should create match on mutual like', () async {
  final likesService = LikesService();
  
  // User A likes User B
  await likesService.handleLike('userA', 'userB');
  
  // User B likes User A - should create match
  final matchId = await likesService.handleLike('userB', 'userA');
  
  expect(matchId, isNotNull);
});
```

### Integration Tests

```dart
// Test BLoC integration
testWidgets('should show match dialog on mutual like', (tester) async {
  // Setup BLoC and widget
  // Trigger like event
  // Verify match dialog appears
});
```

## 🚨 Error Handling

The system includes comprehensive error handling:

- Network failures are gracefully handled
- Firestore errors don't crash the app
- Fallback to legacy system if new system fails
- User-friendly error messages in UI

## 📊 Performance Considerations

- Uses efficient Firestore queries with proper indexing
- Batch operations for multiple updates
- Lazy loading of user data
- Optimistic UI updates

## 🔐 Security

- All operations validate user authentication
- Firestore security rules prevent unauthorized access
- User data is properly sanitized
- No sensitive data in client-side logs

## 🎯 Future Enhancements

- [ ] Push notifications for matches
- [ ] Match expiration system
- [ ] Super likes functionality
- [ ] Match analytics and insights
- [ ] Undo like functionality
- [ ] Boost/premium matching features

## 🐛 Troubleshooting

### Common Issues

1. **Matches not creating**: Check Firestore security rules
2. **Dialog not showing**: Verify BLoC listener setup
3. **Chat not opening**: Ensure chat thread ID is valid
4. **Legacy compatibility**: Check UserSearchRepo integration

### Debug Mode

Enable debug logging:
```dart
// Add to main.dart
if (kDebugMode) {
  // Enable Firestore logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}
```

## 📞 Support

For issues or questions about the mutual likes system:

1. Check this README first
2. Review the example integration code
3. Check Firestore console for data issues
4. Review BLoC state transitions in debug mode
