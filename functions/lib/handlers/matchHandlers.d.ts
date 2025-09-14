/**
 * Match-related Cloud Function handlers
 */
import * as functions from 'firebase-functions';
export declare class MatchHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle match creation
     */
    onMatchCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=matchHandlers.d.ts.map