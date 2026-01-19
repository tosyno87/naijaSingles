/**
 * Match-related Cloud Function handlers
 */
import * as functions from 'firebase-functions/v1';
export declare class MatchHandlers {
    private userService;
    private notificationService;
    constructor();
    /**
     * Handle match creation (Gen 1 - compatible with existing deployments)
     */
    onMatchCreated: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=matchHandlers.d.ts.map