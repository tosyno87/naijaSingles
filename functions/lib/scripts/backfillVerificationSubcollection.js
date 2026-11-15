"use strict";
/**
 * One-time backfill: copy legacy root `verification` field on user docs
 * to `users/{uid}/verification/current` subcollection.
 *
 * Does NOT delete the root field — keep until all readers use subcollection.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/backfillVerificationSubcollection.ts
 *   cd functions && npx ts-node src/scripts/backfillVerificationSubcollection.ts --dry-run
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or default application credentials.
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
const dryRun = process.argv.includes('--dry-run');
admin.initializeApp();
const db = admin.firestore();
function hasLegacyVerification(data) {
    const v = data.verification;
    return v != null && typeof v === 'object' && !Array.isArray(v);
}
async function backfill() {
    const usersRef = db.collection('users');
    const batchSize = 500;
    let lastDoc;
    let totalCopied = 0;
    let totalSkipped = 0;
    let totalNoLegacy = 0;
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
            if (!hasLegacyVerification(data)) {
                totalNoLegacy++;
                continue;
            }
            const subRef = doc.ref.collection('verification').doc('current');
            const existing = await subRef.get();
            if (existing.exists) {
                totalSkipped++;
                continue;
            }
            const legacy = data.verification;
            const payload = {
                status: legacy.status ?? 'pending',
                imageUrl: legacy.imageUrl ?? null,
                submittedAt: legacy.submittedAt ?? admin.firestore.FieldValue.serverTimestamp(),
                backfilledAt: admin.firestore.FieldValue.serverTimestamp(),
                backfillSource: 'root_verification_field',
            };
            if (dryRun) {
                console.log(`[dry-run] Would copy ${doc.id} -> verification/current`);
                totalCopied++;
                continue;
            }
            batch.set(subRef, payload, { merge: true });
            batchCount++;
        }
        if (!dryRun && batchCount > 0) {
            await batch.commit();
        }
        totalCopied += batchCount;
        console.log(`Processed ${snapshot.docs.length} docs ` +
            `(${batchCount} copied, ${totalSkipped} subcollection exists, ` +
            `${snapshot.docs.length - batchCount - totalSkipped} no legacy in batch). ` +
            `Running total copied: ${totalCopied}.`);
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.docs.length < batchSize)
            break;
    }
    console.log(`\n✅ Backfill ${dryRun ? '(dry-run) ' : ''}complete. ` +
        `${totalCopied} copied, ${totalSkipped} already had subcollection, ` +
        `${totalNoLegacy} without legacy field.`);
}
backfill().catch((err) => {
    console.error('❌ Backfill failed:', err);
    process.exit(1);
});
//# sourceMappingURL=backfillVerificationSubcollection.js.map