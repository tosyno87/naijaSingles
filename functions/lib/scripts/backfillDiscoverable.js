"use strict";
/**
 * One-time backfill script to set `isDiscoverable` on all existing user documents.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/backfillDiscoverable.ts
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service-account key,
 * or run from a Cloud Shell that already has default credentials.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
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
async function backfill() {
    const usersRef = db.collection('users');
    const batchSize = 500;
    let lastDoc;
    let totalUpdated = 0;
    let totalSkipped = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        let query = usersRef.orderBy('__name__').limit(batchSize);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        let batchCount = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const computed = computeDiscoverable(data);
            if (data.isDiscoverable !== computed) {
                batch.update(doc.ref, { isDiscoverable: computed });
                batchCount++;
            }
        }
        if (batchCount > 0) {
            await batch.commit();
            totalUpdated += batchCount;
        }
        totalSkipped += snapshot.docs.length - batchCount;
        console.log(`Processed ${snapshot.docs.length} docs ` +
            `(${batchCount} updated, ${snapshot.docs.length - batchCount} skipped). ` +
            `Running total: ${totalUpdated} updated, ${totalSkipped} skipped.`);
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.docs.length < batchSize)
            break;
    }
    console.log(`\n✅ Backfill complete. ${totalUpdated} updated, ${totalSkipped} already correct.`);
}
backfill().catch((err) => {
    console.error('❌ Backfill failed:', err);
    process.exit(1);
});
//# sourceMappingURL=backfillDiscoverable.js.map