/**
 * NaijaSingles Cloud Functions - TypeScript Implementation
 *
 * This file exports all Cloud Functions for the NaijaSingles application.
 * The functions are organized into modular handlers for better maintainability.
 */
export declare const onMatchCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/firestore").FirestoreEvent<import("firebase-functions/firestore").QueryDocumentSnapshot | undefined, {
    matchId: string;
}>>;
export declare const onMessageSent: import("firebase-functions/core").CloudFunction<import("firebase-functions/firestore").FirestoreEvent<import("firebase-functions/firestore").QueryDocumentSnapshot | undefined, {
    threadId: string;
    messageId: string;
}>>;
export declare const onSuperLikeCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/firestore").FirestoreEvent<import("firebase-functions/firestore").QueryDocumentSnapshot | undefined, {
    superLikeId: string;
}>>;
export declare const onLikeCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/firestore").FirestoreEvent<import("firebase-functions/firestore").QueryDocumentSnapshot | undefined, {
    userId: string;
    likeId: string;
}>>;
export declare const createTestUsers: import("firebase-functions/v2/https").HttpsFunction;
export declare const healthCheck: import("firebase-functions/v2/https").HttpsFunction;
//# sourceMappingURL=index.d.ts.map