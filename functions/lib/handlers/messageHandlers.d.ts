/**
 * Message-related Cloud Function handlers
 */
import * as functions from 'firebase-functions/v1';
export declare class MessageHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle message creation (Gen 1 - compatible with existing deployments)
     */
    onMessageSent: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=messageHandlers.d.ts.map