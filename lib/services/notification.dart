import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../common/constants/constants.dart';

class NotificationData {
  static final firebaseInstance = FirebaseMessaging.instance;

  // Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    final settings = await firebaseInstance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await firebaseInstance.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await firebaseInstance.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await firebaseInstance.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }
}
