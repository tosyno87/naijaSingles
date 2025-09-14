/**
 * NaijaSingles Cloud Functions - TypeScript Implementation
 *
 * This file exports all Cloud Functions for the NaijaSingles application.
 * The functions are organized into modular handlers for better maintainability.
 */
export declare const onMatchCreated: import("firebase-functions/v1").CloudFunction<import("firebase-functions/v1/firestore").QueryDocumentSnapshot>;
export declare const onMessageSent: import("firebase-functions/v1").CloudFunction<import("firebase-functions/v1/firestore").QueryDocumentSnapshot>;
export declare const onSuperLikeCreated: import("firebase-functions/v1").CloudFunction<import("firebase-functions/v1/firestore").QueryDocumentSnapshot>;
export declare const onLikeCreated: import("firebase-functions/v1").CloudFunction<import("firebase-functions/v1/firestore").QueryDocumentSnapshot>;
export declare const healthCheck: (req: any, res: any) => Promise<void>;
//# sourceMappingURL=index.d.ts.map