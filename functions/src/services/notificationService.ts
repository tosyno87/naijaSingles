/**
 * Notification service for handling push notifications
 */

import * as admin from 'firebase-admin';
import {
  User,
  NotificationMessage,
  NotificationData,
  NotificationType,
  NotificationStatus,
} from '../types';

export class NotificationService {
  private db: admin.firestore.Firestore;

  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Send match notification
   */
  async sendMatchNotification(user: User, matchedUser: User): Promise<void> {
    const pushToken = user.pushToken;
    if (!pushToken) {
      console.log(`No push token for user ${user.id}`);
      return;
    }

    // Check notification preferences
    const notificationPrefs = user.notificationPreferences || {};
    if (notificationPrefs.matchNotifications === false) {
      console.log(`Match notifications disabled for user ${user.id}`);
      return;
    }

    const message: NotificationMessage = {
      notification: {
        title: '🎉 It\'s a Match!',
        body: `You and ${matchedUser.name || 'someone special'} liked each other!`,
      },
      data: {
        type: 'match',
        userId: user.id,
        matchedUserId: matchedUser.id,
        matchedUserName: matchedUser.name || '',
        matchedUserPhoto: this.getFirstPhoto(matchedUser),
        action: 'open_chat',
      },
      token: pushToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#FF3A5A',
          sound: 'match_sound',
          channelId: 'matches',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'match_sound.caf',
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`✅ Match notification sent to ${user.id}`);

      // Log successful notification
      await this.logNotificationAnalytics(user.id, NotificationType.MATCH, NotificationStatus.SENT);

      // Store in-app notification
      await this.storeInAppNotification(user.id, {
        type: 'match',
        title: '🎉 It\'s a Match!',
        message: `You and ${matchedUser.name || 'someone special'} liked each other!`,
        avatarUrl: this.getFirstPhoto(matchedUser),
        actionId: matchedUser.id,
      });
    } catch (error) {
      console.error(`❌ Error sending match notification to ${user.id}:`, error);
      await this.logNotificationAnalytics(user.id, NotificationType.MATCH, NotificationStatus.FAILED, (error as Error).message);
    }
  }

  /**
   * Send message notification
   */
  async sendMessageNotification(
    recipient: User,
    sender: User,
    messageData: any,
    threadId: string
  ): Promise<void> {
    const pushToken = recipient.pushToken;
    if (!pushToken) {
      console.log(`No push token for user ${recipient.id}`);
      return;
    }

    // Check notification preferences
    const notificationPrefs = recipient.notificationPreferences || {};
    if (notificationPrefs.messageNotifications === false) {
      console.log(`Message notifications disabled for user ${recipient.id}`);
      return;
    }

    // Truncate long messages
    const messageText = messageData.text || 'Sent you a message';
    const truncatedMessage = messageText.length > 100
      ? messageText.substring(0, 100) + '...'
      : messageText;

    const message: NotificationMessage = {
      notification: {
        title: sender.name || 'New Message',
        body: truncatedMessage,
      },
      data: {
        type: 'message',
        senderId: sender.id,
        senderName: sender.name || '',
        senderPhoto: this.getFirstPhoto(sender),
        messageText: messageText,
        threadId: threadId,
        action: 'open_chat',
      },
      token: pushToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#008037',
          sound: 'message_sound',
          channelId: 'messages',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'message_sound.caf',
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`✅ Message notification sent to ${recipient.id}`);

      // Log successful notification
      await this.logNotificationAnalytics(recipient.id, NotificationType.MESSAGE, NotificationStatus.SENT);

      // Store in-app notification
      await this.storeInAppNotification(recipient.id, {
        type: 'message',
        title: `New message from ${sender.name || 'someone'}`,
        message: truncatedMessage,
        avatarUrl: this.getFirstPhoto(sender),
        actionId: threadId,
      });
    } catch (error) {
      console.error(`❌ Error sending message notification to ${recipient.id}:`, error);
      await this.logNotificationAnalytics(recipient.id, NotificationType.MESSAGE, NotificationStatus.FAILED, (error as Error).message);
    }
  }

  /**
   * Send super like notification
   */
  async sendSuperLikeNotification(recipient: User, sender: User, superLikeId: string): Promise<void> {
    const pushToken = recipient.pushToken;
    if (!pushToken) {
      console.log(`No push token for user ${recipient.id}`);
      return;
    }

    // Check notification preferences
    const notificationPrefs = recipient.notificationPreferences || {};
    if (notificationPrefs.superLikeNotifications === false) {
      console.log(`Super like notifications disabled for user ${recipient.id}`);
      return;
    }

    const message: NotificationMessage = {
      notification: {
        title: '⭐ Super Like!',
        body: `${sender.name || 'Someone special'} super liked you! They really want to connect.`,
      },
      data: {
        type: 'super_like',
        senderId: sender.id,
        senderName: sender.name || '',
        senderPhoto: this.getFirstPhoto(sender),
        superLikeId: superLikeId,
        action: 'open_profile',
      },
      token: pushToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#0066FF',
          sound: 'super_like_sound',
          channelId: 'super_likes',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'super_like_sound.caf',
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`✅ Super like notification sent to ${recipient.id}`);

      // Log successful notification
      await this.logNotificationAnalytics(recipient.id, NotificationType.SUPER_LIKE, NotificationStatus.SENT);

      // Store in-app notification
      await this.storeInAppNotification(recipient.id, {
        type: 'super_like',
        title: '⭐ Super Like!',
        message: `${sender.name || 'Someone special'} super liked you!`,
        avatarUrl: this.getFirstPhoto(sender),
        actionId: sender.id,
        superLikeId: superLikeId,
      });
    } catch (error) {
      console.error(`❌ Error sending super like notification to ${recipient.id}:`, error);
      await this.logNotificationAnalytics(recipient.id, NotificationType.SUPER_LIKE, NotificationStatus.FAILED, (error as Error).message);
    }
  }

  /**
   * Send like notification
   */
  async sendLikeNotification(likedUser: User, liker: User): Promise<void> {
    const pushToken = likedUser.pushToken;
    if (!pushToken) {
      console.log(`No push token for user ${likedUser.id}`);
      return;
    }

    // Check notification preferences
    const notificationPrefs = likedUser.notificationPreferences || {};
    if (notificationPrefs.likeNotifications === false) {
      console.log(`Like notifications disabled for user ${likedUser.id}`);
      return;
    }

    const message: NotificationMessage = {
      notification: {
        title: '💖 Someone likes you!',
        body: `${liker.name || 'Someone'} liked your profile`,
      },
      data: {
        type: 'like',
        likerId: liker.id,
        likerName: liker.name || '',
        likerPhoto: this.getFirstPhoto(liker),
        action: 'open_profile',
      },
      token: pushToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#FF69B4',
          sound: 'like_sound',
          channelId: 'likes',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'like_sound.caf',
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`✅ Like notification sent to ${likedUser.id}`);

      // Log successful notification
      await this.logNotificationAnalytics(likedUser.id, NotificationType.LIKE, NotificationStatus.SENT);

      // Store in-app notification
      await this.storeInAppNotification(likedUser.id, {
        type: 'like',
        title: '💖 Someone likes you!',
        message: `${liker.name || 'Someone'} liked your profile`,
        avatarUrl: this.getFirstPhoto(liker),
        actionId: liker.id,
      });
    } catch (error) {
      console.error(`❌ Error sending like notification to ${likedUser.id}:`, error);
      await this.logNotificationAnalytics(likedUser.id, NotificationType.LIKE, NotificationStatus.FAILED, (error as Error).message);
    }
  }

  /**
   * Store in-app notification
   */
  private async storeInAppNotification(userId: string, notificationData: Partial<NotificationData>): Promise<void> {
    try {
      const notificationRef = this.db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();

      await notificationRef.set({
        ...notificationData,
        id: notificationRef.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });

      console.log(`✅ In-app notification stored for user ${userId}`);

      // Log notification analytics
      await this.logNotificationAnalytics(userId, notificationData.type as NotificationType, NotificationStatus.STORED);
    } catch (error) {
      console.error(`❌ Error storing in-app notification for ${userId}:`, error);
    }
  }

  /**
   * Log notification analytics
   */
  private async logNotificationAnalytics(
    userId: string,
    type: NotificationType,
    status: NotificationStatus,
    error?: string
  ): Promise<void> {
    try {
      await this.db.collection('notificationLogs').add({
        userId: userId,
        type: type,
        status: status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        error: error,
      });
    } catch (logError) {
      console.error('Error logging notification analytics:', logError);
    }
  }

  /**
   * Get first photo URL from user object
   */
  private getFirstPhoto(user: User): string {
    if (user.imageUrl && Array.isArray(user.imageUrl) && user.imageUrl.length > 0) {
      return user.imageUrl[0];
    }
    if (user.Pictures && Array.isArray(user.Pictures) && user.Pictures.length > 0) {
      return user.Pictures[0];
    }
    if (user.photos && Array.isArray(user.photos) && user.photos.length > 0) {
      return user.photos[0];
    }
    if (user.photoUrl) {
      return user.photoUrl;
    }
    return '';
  }
}
