import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const projectId = 'naijasingles-rules-tests';

const firestoreRules = readFileSync(resolve('firestore.rules'), 'utf8');
const storageRules = readFileSync(resolve('storage.rules'), 'utf8');

function pass(message) {
  console.log(`✅ ${message}`);
}

async function run() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });

  try {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/privateUser'), {
        name: 'Private',
        isProfilePrivate: true,
      });
      await setDoc(doc(db, 'users/publicUser'), {
        name: 'Public',
        isProfilePrivate: false,
        isDeleted: false,
        accountStatus: 'active',
      });
      await setDoc(doc(db, 'users/deletedUser'), {
        name: 'Deleted',
        isDeleted: true,
      });
    });

    // Firestore profile visibility tests.
    const ownerDb = testEnv.authenticatedContext('privateUser').firestore();
    await assertSucceeds(getDoc(doc(ownerDb, 'users/privateUser')));
    pass('Owner can read own private profile');

    const otherUserDb = testEnv.authenticatedContext('otherUser').firestore();
    await assertFails(getDoc(doc(otherUserDb, 'users/privateUser')));
    pass('Non-owner cannot read private profile');

    await assertSucceeds(getDoc(doc(otherUserDb, 'users/publicUser')));
    pass('Non-owner can read active public profile');

    await assertFails(getDoc(doc(otherUserDb, 'users/deletedUser')));
    pass('Non-owner cannot read deleted profile');

    // Legacy LikedBy ownership tests.
    const likerDb = testEnv.authenticatedContext('likerA').firestore();
    await assertSucceeds(
      setDoc(doc(likerDb, 'users/targetUser/LikedBy/likerA'), {
        LikedBy: 'likerA',
      }),
    );
    pass('Liker can create their own legacy LikedBy entry');

    await assertFails(
      setDoc(doc(otherUserDb, 'users/targetUser/LikedBy/likerA'), {
        LikedBy: 'likerA',
      }),
    );
    pass('Other users cannot spoof someone else in legacy LikedBy');

    // Storage owner path tests.
    const ownerStorage = testEnv.authenticatedContext('owner1').storage();
    await assertSucceeds(
      ownerStorage.ref('event_images/owner1/event1_photo.jpg').put(
        new Uint8Array([1, 2, 3, 4]),
        { contentType: 'image/jpeg' },
      ),
    );
    pass('Owner can upload to owner-scoped event image path');

    const otherStorage = testEnv.authenticatedContext('otherUser').storage();
    await assertFails(
      otherStorage.ref('event_images/owner1/event1_hack.jpg').put(
        new Uint8Array([1, 2, 3, 4]),
        { contentType: 'image/jpeg' },
      ),
    );
    pass('Non-owner cannot upload to another owner event image path');

    await assertFails(
      otherStorage.ref('event_images/legacy_without_owner.jpg').put(
        new Uint8Array([1, 2, 3, 4]),
        { contentType: 'image/jpeg' },
      ),
    );
    pass('Writes to legacy unscoped event_images path are blocked');

    await assertSucceeds(
      otherStorage.ref('event_images/owner1/event1_photo.jpg').getDownloadURL(),
    );
    pass('Authenticated users can still read published event images');
  } finally {
    await testEnv.cleanup();
  }
}

try {
  await run();
  console.log('🎉 Firebase rules regression tests passed.');
} catch (error) {
  console.error('❌ Firebase rules regression tests failed.');
  console.error(error);
  process.exitCode = 1;
}
