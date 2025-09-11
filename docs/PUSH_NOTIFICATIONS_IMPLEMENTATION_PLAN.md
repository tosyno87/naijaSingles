# Push Notifications Implementation Plan

## Phase 1: Critical Notifications (Week 1-2)

### Step 1: Setup Cloud Functions

#### Initialize Cloud Functions
```bash
cd /Users/babatundetosin/StudioProjects/naijaSingles
firebase init functions
# Select JavaScript
# Install dependencies: Yes
# ESLint: Yes
```

#### Create Cloud Functions for Notifications
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Match notification when match is created
exports.onMatchCreated = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {
    const matchData = snap.data();
    const users = matchData.users || [];
    
    if (users.length !== 2) return;
    
    try {
      // Get both users' data
      const [userADoc, userBDoc] = await Promise.all([
        admin.firestore().collection('users').doc(users[0]).get(),
        admin.firestore().collection('users').doc(users[1]).get()
      ]);
      
      if (!userADoc.exists || !userBDoc.exists) return;
      
      const userA = userADoc.data();
      const userB = userBDoc.data();
      
      // Send notifications to both users
      await Promise.all([
        sendMatchNotification(users[0], userB, userA.pushToken),
        sendMatchNotification(users[1], userA, userB.pushToken)
      ]);
      
    } catch (error) {
      console.error('Error sending match notification:', error);
    }
  });

// Message notification when message is sent
exports.onMessageSent = functions.firestore
  .document('chatThreads/{threadId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const threadId = context.params.threadId;
    
    try {
      // Get chat thread to find recipient
      const threadDoc = await admin.firestore()
        .collection('chatThreads').doc(threadId).get();
      
      if (!threadDoc.exists) return;
      
      const threadData = threadDoc.data();
      const participants = threadData.userIds || [];
      const recipientId = participants.find(id => id !== messageData.senderId);
      
      if (!recipientId) return;
      
      // Get sender and recipient data
      const [senderDoc, recipientDoc] = await Promise.all([
        admin.firestore().collection('users').doc(messageData.senderId).get(),
        admin.firestore().collection('users').doc(recipientId).get()
      ]);
      
      if (!senderDoc.exists || !recipientDoc.exists) return;
      
      const sender = senderDoc.data();
      const recipient = recipientDoc.data();
      
      await sendMessageNotification(recipientId, sender, messageData, recipient.pushToken);
      
    } catch (error) {
      console.error('Error sending message notification:', error);
    }
  });

// Like notification when someone likes a profile
exports.onLikeCreated = functions.firestore
  .document('users/{userId}/LikedBy/{likeId}')
  .onCreate(async (snap, context) => {
    const likeData = snap.data();
    const likedUserId = context.params.userId;
    const likerId = likeData.LikedBy;
    
    try {
      // Get both users' data
      const [likedUserDoc, likerDoc] = await Promise.all([
        admin.firestore().collection('users').doc(likedUserId).get(),
        admin.firestore().collection('users').doc(likerId).get()
      ]);
      
      if (!likedUserDoc.exists || !likerDoc.exists) return;
      
      const likedUser = likedUserDoc.data();
      const liker = likerDoc.data();
      
      await sendLikeNotification(likedUserId, liker, likedUser.pushToken);
      
    } catch (error) {
      console.error('Error sending like notification:', error);
    }
  });

// Helper function to send match notification
async function sendMatchNotification(userId, matchedUser, pushToken) {
  if (!pushToken) return;
  
  const message = {
    notification: {
      title: '🎉 New Match!',
      body: `You and ${matchedUser.name || 'someone'} are a match! Start chatting now.`,
    },
    data: {
      type: 'match',
      userId: userId,
      matchedUserId: matchedUser.id || '',
      matchedUserName: matchedUser.name || '',
      matchedUserPhoto: matchedUser.imageUrl?.[0] || '',
    },
    token: pushToken,
  };
  
  try {
    await admin.messaging().send(message);
    console.log('Match notification sent successfully');
    
    // Store in-app notification
    await storeInAppNotification(userId, {
      type: 'match',
      title: '🎉 New Match!',
      message: `You and ${matchedUser.name || 'someone'} are a match!`,
      avatarUrl: matchedUser.imageUrl?.[0],
      actionId: matchedUser.id,
    });
    
  } catch (error) {
    console.error('Error sending match notification:', error);
  }
}

// Helper function to send message notification
async function sendMessageNotification(recipientId, sender, messageData, pushToken) {
  if (!pushToken) return;
  
  const message = {
    notification: {
      title: sender.name || 'New Message',
      body: messageData.text || 'Sent you a message',
    },
    data: {
      type: 'message',
      senderId: sender.id || '',
      senderName: sender.name || '',
      senderPhoto: sender.imageUrl?.[0] || '',
      messageText: messageData.text || '',
      chatId: messageData.chatId || '',
    },
    token: pushToken,
  };
  
  try {
    await admin.messaging().send(message);
    console.log('Message notification sent successfully');
    
    // Store in-app notification
    await storeInAppNotification(recipientId, {
      type: 'message',
      title: `New message from ${sender.name || 'someone'}`,
      message: messageData.text || 'Sent you a message',
      avatarUrl: sender.imageUrl?.[0],
      actionId: messageData.chatId,
    });
    
  } catch (error) {
    console.error('Error sending message notification:', error);
  }
}

// Helper function to send like notification
async function sendLikeNotification(likedUserId, liker, pushToken) {
  if (!pushToken) return;
  
  const message = {
    notification: {
      title: '💖 Someone likes you!',
      body: `${liker.name || 'Someone'} liked your profile`,
    },
    data: {
      type: 'like',
      likerId: liker.id || '',
      likerName: liker.name || '',
      likerPhoto: liker.imageUrl?.[0] || '',
    },
    token: pushToken,
  };
  
  try {
    await admin.messaging().send(message);
    console.log('Like notification sent successfully');
    
    // Store in-app notification
    await storeInAppNotification(likedUserId, {
      type: 'like',
      title: '💖 Someone likes you!',
      message: `${liker.name || 'Someone'} liked your profile`,
      avatarUrl: liker.imageUrl?.[0],
      actionId: liker.id,
    });
    
  } catch (error) {
    console.error('Error sending like notification:', error);
  }
}

// Helper function to store in-app notification
async function storeInAppNotification(userId, notificationData) {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        ...notificationData,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
  } catch (error) {
    console.error('Error storing in-app notification:', error);
  }
}
```

### Step 2: Update Flutter App Notification Handling

#### Enhanced Notification Service
```dart
// lib/services/enhanced_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/notifications/notification_model.dart';

class EnhancedNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Initialize notification service
  static Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get and store FCM token
    await _updateFCMToken();
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateFCMToken);
  }
  
  /// Update FCM token in user document
  static Future<void> _updateFCMToken([String? token]) async {
    try {
      token ??= await _messaging.getToken();
      if (token == null) return;
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'pushToken': token});
          
      debugPrint('FCM token updated: $token');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
  
  /// Get user's notifications from Firestore
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }
  
  /// Mark notification as read
  static Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  /// Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
```

#### Update AppNotification Model
```dart
// lib/features/notifications/notification_model.dart
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? avatarUrl;
  final String type;
  final bool isRead;
  final String? actionId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.avatarUrl,
    this.isRead = false,
    this.actionId,
  });

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'general',
      avatarUrl: data['avatarUrl'],
      isRead: data['isRead'] ?? false,
      actionId: data['actionId'],
    );
  }

  // ... rest of the existing methods
}
```

### Step 3: Update Likes Service

#### Remove Placeholder and Add Real Implementation
```dart
// lib/features/match/services/likes_service.dart
/// Trigger match notification (enhanced implementation)
Future<void> _triggerMatchNotification(String userAId, String userBId) async {
  try {
    debugPrint('🎉 Triggering match notification for users: $userAId, $userBId');
    
    // The Cloud Function will handle the actual notification sending
    // We just need to ensure the match document is created properly
    // which triggers the Cloud Function
    
    // Optional: Add local in-app notification for immediate feedback
    await _addLocalMatchNotification(userAId, userBId);
    
  } catch (e) {
    debugPrint('❌ Error triggering match notification: $e');
  }
}

/// Add local in-app notification for immediate feedback
Future<void> _addLocalMatchNotification(String userAId, String userBId) async {
  try {
    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    // Determine which user to show notification to
    final otherUserId = currentUserId == userAId ? userBId : userAId;
    
    // Get other user's data
    final otherUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();
        
    if (!otherUserDoc.exists) return;
    
    final otherUserData = otherUserDoc.data()!;
    
    // Add to local notification service for immediate display
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '🎉 New Match!',
      message: 'You and ${otherUserData['name'] ?? 'someone'} are a match!',
      timestamp: DateTime.now(),
      type: 'match',
      avatarUrl: otherUserData['imageUrl']?[0],
      actionId: otherUserId,
    );
    
    NotificationService().addNotification(notification);
    
  } catch (e) {
    debugPrint('Error adding local match notification: $e');
  }
}
```

### Step 4: Update Message Handling

#### Add Message Notification Trigger
```dart
// lib/features/chat/ui/widgets/send_message_box.dart
// Add this after message is sent successfully

Future<void> _sendMessage() async {
  // ... existing message sending code ...
  
  try {
    // Send message to Firestore
    await FirebaseFirestore.instance
        .collection('chatThreads')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': _messageController.text,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'chatId': widget.chatId,
      // Add any other message fields
    });
    
    // Clear message input
    _messageController.clear();
    
    // The Cloud Function will automatically trigger notification
    // when the message document is created
    
  } catch (e) {
    debugPrint('Error sending message: $e');
  }
}
```

## Phase 2: Enhanced Features (Week 3-4)

### Step 1: Notification Preferences

#### Add to User Model
```dart
// lib/models/user_model.dart
class NotificationPreferences {
  final bool matchNotifications;
  final bool messageNotifications;
  final bool likeNotifications;
  final bool quietHours;
  final String quietStart; // "22:00"
  final String quietEnd;   // "08:00"
  
  NotificationPreferences({
    this.matchNotifications = true,
    this.messageNotifications = true,
    this.likeNotifications = true,
    this.quietHours = false,
    this.quietStart = "22:00",
    this.quietEnd = "08:00",
  });
  
  Map<String, dynamic> toMap() {
    return {
      'matchNotifications': matchNotifications,
      'messageNotifications': messageNotifications,
      'likeNotifications': likeNotifications,
      'quietHours': quietHours,
      'quietStart': quietStart,
      'quietEnd': quietEnd,
    };
  }
  
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      matchNotifications: map['matchNotifications'] ?? true,
      messageNotifications: map['messageNotifications'] ?? true,
      likeNotifications: map['likeNotifications'] ?? true,
      quietHours: map['quietHours'] ?? false,
      quietStart: map['quietStart'] ?? "22:00",
      quietEnd: map['quietEnd'] ?? "08:00",
    );
  }
}
```

### Step 2: Notification Settings Screen

```dart
// lib/features/notifications/notification_settings_screen.dart
class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferences _preferences = NotificationPreferences();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Match Notifications'),
            subtitle: Text('Get notified when you have a new match'),
            value: _preferences.matchNotifications,
            onChanged: (value) {
              setState(() {
                _preferences = NotificationPreferences(
                  matchNotifications: value,
                  messageNotifications: _preferences.messageNotifications,
                  likeNotifications: _preferences.likeNotifications,
                  quietHours: _preferences.quietHours,
                  quietStart: _preferences.quietStart,
                  quietEnd: _preferences.quietEnd,
                );
              });
              _savePreferences();
            },
          ),
          // Add similar switches for other notification types
        ],
      ),
    );
  }
  
  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'notificationPreferences': _preferences.toMap(),
    });
  }
}
```

## Deployment Steps

### 1. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Update Firestore Rules
```javascript
// Add to firestore.rules
match /users/{userId}/notifications/{notificationId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### 3. Test Notifications
1. Create a match between two users
2. Send a message between matched users  
3. Like a profile
4. Verify notifications are received on both devices

## Expected Results

After implementation:
- ✅ **Match notifications** sent instantly when users match
- ✅ **Message notifications** sent when new messages arrive
- ✅ **Like notifications** sent when someone likes your profile
- ✅ **In-app notifications** stored and displayed in notification screen
- ✅ **Notification badges** showing unread count
- ✅ **User preferences** for controlling notification types

This will significantly improve user engagement and make the app feel more responsive and alive!
