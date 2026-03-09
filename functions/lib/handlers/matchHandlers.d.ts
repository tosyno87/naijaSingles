/**
 * Match-related Cloud Function handlers
 */
export declare class MatchHandlers {
    private userService;
    private notificationService;
    constructor();
    onMatchCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
        matchId: string;
    }>>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=matchHandlers.d.ts.map