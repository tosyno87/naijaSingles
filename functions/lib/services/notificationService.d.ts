/**
 * Notification service for handling push notifications
 */
import { User } from '../types';
export declare class NotificationService {
    private db;
    constructor();
    /**
     * Global FCM gate (evaluated before per-type flags).
     *
     * Precedence (same outcome if both apply — no push):
     * 1. `enableAllNotifications === false` → block
     * 2. `muteAllNotifications === true` → block
     *
     * Omitted fields default to legacy behavior (all on, not muted).
     */
    private isPushGloballyBlocked;
    /**
     * Send match notification
     */
    sendMatchNotification(user: User, matchedUser: User): Promise<void>;
    /**
     * Send message notification
     */
    sendMessageNotification(recipient: User, sender: User, messageData: any, threadId: string): Promise<void>;
    /**
     * Send super like notification
     */
    sendSuperLikeNotification(recipient: User, sender: User, superLikeId: string): Promise<void>;
    /**
     * Send like notification
     */
    sendLikeNotification(likedUser: User, liker: User): Promise<void>;
    /**
     * Store in-app notification in both the user subcollection (legacy/static API)
     * and the top-level /notifications collection (modern instance API).
     * The top-level collection is what ModernNotificationsScreen reads via
     * `.where('userId', isEqualTo: currentUserId)`.
     */
    private storeInAppNotification;
    /**
     * Log notification analytics
     */
    private logNotificationAnalytics;
    /**
     * Get first photo URL from user object
     */
    private getFirstPhoto;
}
//# sourceMappingURL=notificationService.d.ts.map