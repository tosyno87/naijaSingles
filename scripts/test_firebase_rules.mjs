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
      await setDoc(doc(db, 'users/userA/notifications/n1'), {
        title: 'Welcome',
      });
      await setDoc(doc(db, 'notifications/existing_user_a'), {
        userId: 'userA',
        title: 'Ping',
      });
      await setDoc(doc(db, 'notificationLogs/log_user_a'), {
        userId: 'userA',
        action: 'delivered',
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

    // User notifications subcollection ownership tests.
    const userADb = testEnv.authenticatedContext('userA').firestore();
    const userBDb = testEnv.authenticatedContext('userB').firestore();
    await assertSucceeds(getDoc(doc(userADb, 'users/userA/notifications/n1')));
    pass('Notification owner can read user notifications subcollection');

    await assertFails(getDoc(doc(userBDb, 'users/userA/notifications/n1')));
    pass('Non-owner cannot read another user notifications subcollection');

    // Top-level notifications ownership tests.
    await assertSucceeds(
      setDoc(doc(userADb, 'notifications/new_user_a'), {
        userId: 'userA',
        title: 'Self notification',
      }),
    );
    pass('User can create top-level notification for self');

    await assertFails(
      setDoc(doc(userBDb, 'notifications/spoof_user_a'), {
        userId: 'userA',
        title: 'Spoofed notification',
      }),
    );
    pass('User cannot create top-level notification for another user');

    // Legacy user match mirror ownership tests.
    await assertSucceeds(
      setDoc(doc(userADb, 'users/userA/Matches/userB'), {
        Matches: 'userB',
      }),
    );
    pass('Matched user can create own legacy mirror match');

    await assertFails(
      setDoc(doc(otherUserDb, 'users/userA/Matches/userB'), {
        Matches: 'userB',
      }),
    );
    pass('Unrelated user cannot write another user legacy mirror match');

    await assertFails(
      setDoc(doc(userADb, 'users/userA/Matches/userB'), {
        Matches: 'userC',
      }),
    );
    pass('Legacy mirror match rejects mismatched payload data');

    // Notification logs are client-write blocked.
    await assertFails(
      setDoc(doc(userADb, 'notificationLogs/client_write_attempt'), {
        userId: 'userA',
      }),
    );
    pass('Client cannot create notification log documents');

    await assertSucceeds(getDoc(doc(userADb, 'notificationLogs/log_user_a')));
    pass('User can read own notification log document');

    await assertFails(getDoc(doc(userBDb, 'notificationLogs/log_user_a')));
    pass('User cannot read another user notification log document');

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
