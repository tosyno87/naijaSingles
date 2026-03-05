/**
 * Message-related Cloud Function handlers
 */
export declare class MessageHandlers {
    private userService;
    private notificationService;
    constructor();
    onMessageSent: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
        threadId: string;
        messageId: string;
    }>>;
    /**
     * Log errors to Firestore for monitoring
     */
    private logError;
}
//# sourceMappingURL=messageHandlers.d.ts.map