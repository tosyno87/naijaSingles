/**
 * Auth user-deletion cleanup (1st gen trigger).
 * When a Firebase Auth user is deleted, removes their Firestore data and Storage files.
 * Uses v1 because Auth onDelete is not available in v2.
 */
import * as functions from 'firebase-functions/v1';
/**
 * Runs the full cleanup for a deleted Auth user. Exported for unit tests.
 * Trigger calls this; production code should use onAuthUserDeleted.
 */
export declare function runAuthUserDeletedCleanup(user: {
    uid: string;
}): Promise<void>;
/**
 * Triggered when a Firebase Auth user is deleted.
 * Cleans up Firestore (user doc + subcollections, root likes/matches, chatThreads, chats) and Storage.
 * Updates accountDeletions/{uid} to completed (client writes pending before delete).
 */
export declare const onAuthUserDeleted: functions.CloudFunction<import("firebase-admin/auth").UserRecord>;
//# sourceMappingURL=authCleanupHandlers.d.ts.map