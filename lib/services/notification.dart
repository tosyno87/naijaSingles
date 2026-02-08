import 'package:firebase_messaging/firebase_messaging.dart';

import '../common/utils/app_logger.dart';

class NotificationData {
  static final firebaseInstance = FirebaseMessaging.instance;

  // Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    final settings = await firebaseInstance.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await firebaseInstance.getToken();
    } catch (e) {
      AppLogger.error('Error getting FCM token', error: e);
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await firebaseInstance.subscribeToTopic(topic);
    } catch (e) {
      AppLogger.error('Error subscribing to topic $topic', error: e);
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await firebaseInstance.unsubscribeFromTopic(topic);
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic $topic', error: e);
    }
  }
}
