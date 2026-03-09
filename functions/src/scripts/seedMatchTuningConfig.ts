/**
 * Seeds the `runtimeConfig/matchTuning` document with default config and
 * an inactive experiment block.
 *
 * Safe to run multiple times -- skips if the document already exists
 * unless --force is passed.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/seedMatchTuningConfig.ts
 *   cd functions && npx ts-node src/scripts/seedMatchTuningConfig.ts --force
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service-account key,
 * or run from a Cloud Shell that already has default credentials.
 */

import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

const COLLECTION = 'runtimeConfig';
const DOC_ID = 'matchTuning';

async function seed(force: boolean): Promise<void> {
  const docRef = db.collection(COLLECTION).doc(DOC_ID);

  if (!force) {
    const existing = await docRef.get();
    if (existing.exists) {
      console.log(`Document ${COLLECTION}/${DOC_ID} already exists.`);
      console.log('Run with --force to overwrite.');
      return;
    }
  }

  const payload = {
    version: '1.0.0',
    rollbackKey: 'v0_defaults',
    datingWeights: {
      age: 0.30,
      location: 0.25,
      lifestyle: 0.20,
      interest: 0.15,
      completeness: 0.10,
    },
    friendshipWeights: {
      social: 0.35,
      interest: 0.25,
      location: 0.20,
      age: 0.10,
      completeness: 0.10,
    },
    networkingWeights: {
      professional: 0.40,
      industry: 0.25,
      location: 0.20,
      completeness: 0.15,
    },
    locationPerfectMiles: 5.0,
    locationDecayMiles: 50.0,
    locationFloorScore: 0.2,
    experiment: {
      active: false,
    },
  };

  await docRef.set({
    payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Wrote ${COLLECTION}/${DOC_ID}:`);
  console.log(`  version: ${payload.version}`);
  console.log(`  rollbackKey: ${payload.rollbackKey}`);
  console.log('  experiment.active: false');
  console.log('\nDone.');
}

const force = process.argv.includes('--force');
seed(force).catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
