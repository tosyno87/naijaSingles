/**
 * Notification service for handling push notifications
 */
import { User } from '../types';
export declare class NotificationService {
    private db;
    constructor();
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
     * Store in-app notification
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