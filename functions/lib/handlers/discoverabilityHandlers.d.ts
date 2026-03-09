/**
 * Discoverability sync handler.
 *
 * Keeps a stored `isDiscoverable` boolean on each user document in sync with
 * the privacy-related fields (accountStatus, isDeleted, isProfilePrivate).
 *
 * Firestore security rules for `list` queries can then gate on a single
 * equality check (`resource.data.isDiscoverable == true`) instead of
 * per-document inequality checks that cause permission-denied on queries.
 */
export declare class DiscoverabilityHandlers {
    onUserWritten: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
        userId: string;
    }>>;
}
//# sourceMappingURL=discoverabilityHandlers.d.ts.map