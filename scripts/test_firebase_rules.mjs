import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

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

    // ──────────────────────────────────────────────────────────────────────────
    // Chat thread, message, and typing indicator tests.
    // ──────────────────────────────────────────────────────────────────────────

    // Seed a chat thread between userA and userB (bypassing rules).
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'chatThreads/thread_ab'), {
        userIds: ['userA', 'userB'],
        createdAt: new Date().toISOString(),
        lastMessage: '',
      });
      await setDoc(doc(db, 'chatThreads/thread_ab/messages/msg1'), {
        senderId: 'userA',
        text: 'Hello!',
        timestamp: new Date().toISOString(),
        read: false,
      });
      await setDoc(doc(db, 'chatThreads/thread_ab/typing/userA'), {
        isTyping: false,
      });
    });

    // --- chatThreads read access ---
    await assertSucceeds(getDoc(doc(userADb, 'chatThreads/thread_ab')));
    pass('Chat participant (userA) can read the thread');

    await assertSucceeds(getDoc(doc(userBDb, 'chatThreads/thread_ab')));
    pass('Chat participant (userB) can read the thread');

    await assertFails(getDoc(doc(otherUserDb, 'chatThreads/thread_ab')));
    pass('Non-participant cannot read the chat thread');

    const unauthDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(unauthDb, 'chatThreads/thread_ab')));
    pass('Unauthenticated user cannot read the chat thread');

    // --- chatThreads create ---
    await assertSucceeds(
      setDoc(doc(userADb, 'chatThreads/thread_ac'), {
        userIds: ['userA', 'otherUser'],
        createdAt: new Date().toISOString(),
      }),
    );
    pass('Participant can create a valid chat thread with 2 userIds');

    await assertFails(
      setDoc(doc(otherUserDb, 'chatThreads/thread_spoof'), {
        userIds: ['userA', 'userB'],
        createdAt: new Date().toISOString(),
      }),
    );
    pass('Cannot create a thread if not included in userIds');

    await assertFails(
      setDoc(doc(userADb, 'chatThreads/thread_triple'), {
        userIds: ['userA', 'userB', 'otherUser'],
        createdAt: new Date().toISOString(),
      }),
    );
    pass('Cannot create a thread with more than 2 userIds');

    await assertFails(
      setDoc(doc(userADb, 'chatThreads/thread_bad'), {
        userIds: ['userA', 'userB'],
      }),
    );
    pass('Cannot create a thread without required createdAt field');

    // --- chatThreads update ---
    await assertSucceeds(
      updateDoc(doc(userADb, 'chatThreads/thread_ab'), {
        lastMessage: 'Updated message',
      }),
    );
    pass('Participant can update chat thread (e.g. lastMessage)');

    await assertFails(
      updateDoc(doc(userADb, 'chatThreads/thread_ab'), {
        userIds: ['userA', 'otherUser'],
      }),
    );
    pass('Participant cannot change userIds on update');

    await assertFails(
      updateDoc(doc(otherUserDb, 'chatThreads/thread_ab'), {
        lastMessage: 'hacked',
      }),
    );
    pass('Non-participant cannot update chat thread');

    // --- chatThreads delete ---
    // Create a disposable thread to delete.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'chatThreads/thread_del'), {
        userIds: ['userA', 'userB'],
        createdAt: new Date().toISOString(),
      });
    });

    await assertFails(
      updateDoc(doc(otherUserDb, 'chatThreads/thread_del'), {
        lastMessage: 'bye',
      }),
    );
    pass('Non-participant cannot delete chat thread (verified via denied update)');

    // --- messages read ---
    await assertSucceeds(
      getDoc(doc(userADb, 'chatThreads/thread_ab/messages/msg1')),
    );
    pass('Thread participant can read messages');

    await assertFails(
      getDoc(doc(otherUserDb, 'chatThreads/thread_ab/messages/msg1')),
    );
    pass('Non-participant cannot read messages');

    // --- messages create ---
    await assertSucceeds(
      setDoc(doc(userADb, 'chatThreads/thread_ab/messages/msg2'), {
        senderId: 'userA',
        text: 'How are you?',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('Participant can create a valid message with correct senderId');

    await assertFails(
      setDoc(doc(userADb, 'chatThreads/thread_ab/messages/msg_spoof'), {
        senderId: 'userB',
        text: 'Spoofed message',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('Participant cannot create a message with a spoofed senderId');

    await assertFails(
      setDoc(doc(userADb, 'chatThreads/thread_ab/messages/msg_empty'), {
        senderId: 'userA',
        text: '',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('Cannot create a message with empty text');

    await assertFails(
      setDoc(doc(userADb, 'chatThreads/thread_ab/messages/msg_long'), {
        senderId: 'userA',
        text: 'x'.repeat(1001),
        timestamp: new Date().toISOString(),
      }),
    );
    pass('Cannot create a message exceeding 1000 characters');

    await assertFails(
      setDoc(doc(otherUserDb, 'chatThreads/thread_ab/messages/msg_intruder'), {
        senderId: 'otherUser',
        text: 'Intruder message',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('Non-participant cannot create a message in the thread');

    // --- messages update (read status only) ---
    await assertSucceeds(
      updateDoc(doc(userBDb, 'chatThreads/thread_ab/messages/msg1'), {
        read: true,
      }),
    );
    pass('Participant can update message read status');

    await assertFails(
      updateDoc(doc(userBDb, 'chatThreads/thread_ab/messages/msg1'), {
        text: 'Tampered text',
      }),
    );
    pass('Participant cannot update message text (only read status allowed)');

    await assertFails(
      updateDoc(doc(otherUserDb, 'chatThreads/thread_ab/messages/msg1'), {
        read: true,
      }),
    );
    pass('Non-participant cannot update message read status');

    // --- messages delete ---
    // Seed a message from userA to test deletion.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'chatThreads/thread_ab/messages/msg_del'), {
        senderId: 'userA',
        text: 'Temporary',
        timestamp: new Date().toISOString(),
        read: false,
      });
    });

    await assertFails(
      userBDb.doc('chatThreads/thread_ab/messages/msg_del').delete(),
    );
    pass('Receiver cannot delete the sender message');

    // NOTE: assertSucceeds for sender delete uses the compat API .delete()
    await assertSucceeds(
      userADb.doc('chatThreads/thread_ab/messages/msg_del').delete(),
    );
    pass('Sender can delete their own message');

    // --- typing indicators ---
    await assertSucceeds(
      getDoc(doc(userADb, 'chatThreads/thread_ab/typing/userA')),
    );
    pass('Participant can read typing status');

    await assertFails(
      getDoc(doc(otherUserDb, 'chatThreads/thread_ab/typing/userA')),
    );
    pass('Non-participant cannot read typing status');

    await assertSucceeds(
      setDoc(doc(userADb, 'chatThreads/thread_ab/typing/userA'), {
        isTyping: true,
      }),
    );
    pass('Participant can write their own typing status');

    await assertFails(
      setDoc(doc(userBDb, 'chatThreads/thread_ab/typing/userA'), {
        isTyping: true,
      }),
    );
    pass('Participant cannot write someone else typing status');

    await assertFails(
      setDoc(doc(otherUserDb, 'chatThreads/thread_ab/typing/otherUser'), {
        isTyping: true,
      }),
    );
    pass('Non-participant cannot write typing status');

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
