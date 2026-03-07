/**
 * One-time backfill script to set `isDiscoverable` on all existing user documents.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/backfillDiscoverable.ts
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service-account key,
 * or run from a Cloud Shell that already has default credentials.
 */

import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

function computeDiscoverable(data: admin.firestore.DocumentData): boolean {
  const status = (data.accountStatus as string | undefined) ?? 'active';
  if (status !== 'active') return false;
  if (data.isDeleted === true) return false;
  if (data.isProfilePrivate === true) return false;
  return true;
}

async function backfill(): Promise<void> {
  const usersRef = db.collection('users');
  const batchSize = 500;
  let lastDoc: admin.firestore.DocumentSnapshot | undefined;
  let totalUpdated = 0;
  let totalSkipped = 0;

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
      const computed = computeDiscoverable(data);

      if (data.isDiscoverable !== computed) {
        batch.update(doc.ref, {isDiscoverable: computed});
        batchCount++;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      totalUpdated += batchCount;
    }
    totalSkipped += snapshot.docs.length - batchCount;

    console.log(
      `Processed ${snapshot.docs.length} docs ` +
      `(${batchCount} updated, ${snapshot.docs.length - batchCount} skipped). ` +
      `Running total: ${totalUpdated} updated, ${totalSkipped} skipped.`
    );

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    if (snapshot.docs.length < batchSize) break;
  }

  console.log(
    `\n✅ Backfill complete. ${totalUpdated} updated, ${totalSkipped} already correct.`
  );
}

backfill().catch((err) => {
  console.error('❌ Backfill failed:', err);
  process.exit(1);
});
