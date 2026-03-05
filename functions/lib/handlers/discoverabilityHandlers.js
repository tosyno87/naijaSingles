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
    var _a;
    const status = (_a = data.accountStatus) !== null && _a !== void 0 ? _a : 'active';
    if (status !== 'active')
        return false;
    if (data.isDeleted === true)
        return false;
    if (data.isProfilePrivate === true)
        return false;
    return true;
}
class DiscoverabilityHandlers {
    constructor() {
        this.onUserWritten = (0, firestore_1.onDocumentWritten)('users/{userId}', async (event) => {
            var _a;
            const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
            if (!(after === null || after === void 0 ? void 0 : after.exists))
                return; // document deleted
            const data = after.data();
            const computed = computeDiscoverable(data);
            if (data.isDiscoverable === computed)
                return; // already correct
            await after.ref.update({ isDiscoverable: computed });
            console.log(`🔄 Synced isDiscoverable=${computed} for user ${event.params.userId}`);
        });
    }
}
exports.DiscoverabilityHandlers = DiscoverabilityHandlers;
//# sourceMappingURL=discoverabilityHandlers.js.map