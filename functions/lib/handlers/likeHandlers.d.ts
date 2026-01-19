/**
 * Like-related Cloud Function handlers
 */
import * as functions from 'firebase-functions/v1';
export declare class LikeHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle super like creation (Gen 1 - compatible with existing deployments)
     */
    onSuperLikeCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Handle like creation (Gen 1 - compatible with existing deployments)
     */
    onLikeCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=likeHandlers.d.ts.map