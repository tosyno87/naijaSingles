"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.DiscoverabilityHandlers = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
function computeDiscoverable(data) {
    const status = data.accountStatus ?? 'active';
    if (status !== 'active')
        return false;
    if (data.isDeleted === true)
        return false;
    if (data.isProfilePrivate === true)
        return false;
    return true;
}
class DiscoverabilityHandlers {
    onUserWritten = (0, firestore_1.onDocumentWritten)('users/{userId}', async (event) => {
        const after = event.data?.after;
        if (!after?.exists)
            return; // document deleted
        const data = after.data();
        const computed = computeDiscoverable(data);
        if (data.isDiscoverable === computed)
            return; // already correct
        await after.ref.update({ isDiscoverable: computed });
        console.log(`🔄 Synced isDiscoverable=${computed} for user ${event.params.userId}`);
    });
}
exports.DiscoverabilityHandlers = DiscoverabilityHandlers;
//# sourceMappingURL=discoverabilityHandlers.js.map