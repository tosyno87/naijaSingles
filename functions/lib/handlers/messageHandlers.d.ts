/**
 * Message-related Cloud Function handlers
 */
import * as functions from 'firebase-functions';
export declare class MessageHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle message creation
     */
    onMessageSent: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=messageHandlers.d.ts.map