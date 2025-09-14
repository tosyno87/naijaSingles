/**
 * Like-related Cloud Function handlers
 */
import * as functions from 'firebase-functions';
export declare class LikeHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle super like creation
     */
    onSuperLikeCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Handle like creation
     */
    onLikeCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=likeHandlers.d.ts.map