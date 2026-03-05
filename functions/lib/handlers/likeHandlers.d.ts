/**
 * Like-related Cloud Function handlers
 */
export declare class LikeHandlers {
    private userService;
    private notificationService;
    constructor();
    onSuperLikeCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
        superLikeId: string;
    }>>;
    onLikeCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
        userId: string;
        likeId: string;
    }>>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=likeHandlers.d.ts.map