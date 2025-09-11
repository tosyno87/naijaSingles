# Notifications System

This directory contains the implementation of the Notifications System for Afropeep.

## Components

1. **NotificationsScreen**: The main screen that displays all notifications.
2. **AppNotification**: Model class for notification data.
3. **NotificationService**: Service class to manage notifications.
4. **NotificationBadge**: Widget that displays a notification icon with a badge for unread notifications.

## Features

- Display notifications with different types (like, match, message, invite)
- Mark notifications as read
- Delete notifications
- Show unread count badge
- Navigate to relevant screens based on notification type

## Usage

To use the notification badge in any screen:

```dart
import '../notifications/notification_badge.dart';

// In your AppBar actions
actions: [
  const NotificationBadge(),
],
```

To navigate to the notifications screen:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
);
```

## Notification Types

- **like**: Someone liked your profile
- **match**: You have a new match
- **message**: You received a new message
- **invite**: You were invited to a group or event

## Future Improvements

- Connect to Firebase Cloud Messaging for real-time notifications
- Add notification preferences
- Implement push notifications
- Add more notification types
