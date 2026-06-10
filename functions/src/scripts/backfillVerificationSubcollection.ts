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

import * as admin from 'firebase-admin';

const dryRun = process.argv.includes('--dry-run');

admin.initializeApp();
const db = admin.firestore();

type LegacyVerification = {
  status?: string;
  imageUrl?: string;
  submittedAt?: admin.firestore.Timestamp | admin.firestore.FieldValue;
  [key: string]: unknown;
};

function hasLegacyVerification(
  data: admin.firestore.DocumentData,
): data is {verification: LegacyVerification} {
  const v = data.verification;
  return v != null && typeof v === 'object' && !Array.isArray(v);
}

async function backfill(): Promise<void> {
  const usersRef = db.collection('users');
  const batchSize = 500;
  let lastDoc: admin.firestore.DocumentSnapshot | undefined;
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
    if (snapshot.empty) break;

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
      const payload: Record<string, unknown> = {
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

      batch.set(subRef, payload, {merge: true});
      batchCount++;
    }

    if (!dryRun && batchCount > 0) {
      await batch.commit();
    }
    totalCopied += batchCount;

    console.log(
      `Processed ${snapshot.docs.length} docs ` +
        `(${batchCount} copied, ${totalSkipped} subcollection exists, ` +
        `${snapshot.docs.length - batchCount - totalSkipped} no legacy in batch). ` +
        `Running total copied: ${totalCopied}.`
    );

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.docs.length < batchSize) break;
  }

  console.log(
    `\n✅ Backfill ${dryRun ? '(dry-run) ' : ''}complete. ` +
      `${totalCopied} copied, ${totalSkipped} already had subcollection, ` +
      `${totalNoLegacy} without legacy field.`
  );
}

backfill().catch((err) => {
  console.error('❌ Backfill failed:', err);
  process.exit(1);
});
