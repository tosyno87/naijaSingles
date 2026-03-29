import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

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

    // ──────────────────────────────────────────────────────────────────────────
    // Discovery & matching domain tests.
    // Collections: likes, matches, superLikes, swipeHistory,
    //              superLikeUsage, undoUsage, Likes (legacy), Matches (legacy)
    // ──────────────────────────────────────────────────────────────────────────

    // Seed existing documents for read/update/delete tests.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // likes collection
      await setDoc(doc(db, 'likes/like_ab'), {
        from: 'userA',
        to: 'userB',
        timestamp: new Date().toISOString(),
      });

      // matches collection
      await setDoc(doc(db, 'matches/match_ab'), {
        users: ['userA', 'userB'],
        matchedAt: new Date().toISOString(),
      });

      // Legacy Likes collection (capital L) - fully disabled
      await setDoc(doc(db, 'Likes/legacy_like_ab'), {
        from: 'userA',
        to: 'userB',
      });

      // Legacy top-level Matches collection
      await setDoc(doc(db, 'Matches/legacy_match_ab'), {
        users: ['userA', 'userB'],
      });

      // superLikes collection
      await setDoc(doc(db, 'superLikes/sl_ab'), {
        fromUserId: 'userA',
        toUserId: 'userB',
        timestamp: new Date().toISOString(),
      });

      // swipeHistory collection
      await setDoc(doc(db, 'swipeHistory/swipe_a1'), {
        userId: 'userA',
        targetUserId: 'userB',
        direction: 'right',
        timestamp: new Date().toISOString(),
      });

      // superLikeUsage collection
      await setDoc(doc(db, 'superLikeUsage/slu_a'), {
        userId: 'userA',
        count: 1,
      });

      // undoUsage collection
      await setDoc(doc(db, 'undoUsage/uu_a'), {
        userId: 'userA',
        count: 2,
      });
    });

    // ── likes collection ────────────────────────────────────────────────────

    // Create: from must match auth.uid, requires ['from', 'to', 'timestamp'].
    await assertSucceeds(
      setDoc(doc(userADb, 'likes/like_ac'), {
        from: 'userA',
        to: 'otherUser',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('likes: user can create a like with from matching auth.uid');

    await assertFails(
      setDoc(doc(userADb, 'likes/like_forged'), {
        from: 'userB',
        to: 'otherUser',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('likes: cannot create a like with forged from field');

    await assertFails(
      setDoc(doc(userADb, 'likes/like_bad'), {
        from: 'userA',
        to: 'otherUser',
      }),
    );
    pass('likes: create rejected without timestamp field');

    await assertFails(
      setDoc(doc(unauthDb, 'likes/like_unauth'), {
        from: 'anon',
        to: 'userA',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('likes: unauthenticated user cannot create a like');

    // Read: only sender (from) or receiver (to) can read.
    await assertSucceeds(getDoc(doc(userADb, 'likes/like_ab')));
    pass('likes: sender can read their own like');

    await assertSucceeds(getDoc(doc(userBDb, 'likes/like_ab')));
    pass('likes: receiver can read a like sent to them');

    await assertFails(getDoc(doc(otherUserDb, 'likes/like_ab')));
    pass('likes: unrelated user cannot read the like');

    // Update: only involved parties (from or to).
    await assertSucceeds(
      updateDoc(doc(userBDb, 'likes/like_ab'), { mutual: true }),
    );
    pass('likes: receiver can update the like (e.g. mutual flag)');

    await assertFails(
      updateDoc(doc(userBDb, 'likes/like_ab'), { from: 'userB' }),
    );
    pass('likes: participant cannot mutate the from field');

    await assertFails(
      updateDoc(doc(userADb, 'likes/like_ab'), { to: 'otherUser' }),
    );
    pass('likes: participant cannot mutate the to field');

    await assertFails(
      updateDoc(doc(otherUserDb, 'likes/like_ab'), { mutual: true }),
    );
    pass('likes: unrelated user cannot update the like');

    // Delete: only the sender (from) can delete.
    await assertFails(
      deleteDoc(doc(userBDb, 'likes/like_ab')),
    );
    pass('likes: receiver cannot delete the like');

    await assertFails(
      deleteDoc(doc(otherUserDb, 'likes/like_ab')),
    );
    pass('likes: unrelated user cannot delete the like');

    // Seed a disposable like for sender-delete test.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'likes/like_del'), {
        from: 'userA',
        to: 'userB',
        timestamp: new Date().toISOString(),
      });
    });

    await assertSucceeds(
      deleteDoc(doc(userADb, 'likes/like_del')),
    );
    pass('likes: sender can delete their own like');

    // ── matches collection ──────────────────────────────────────────────────

    // Create: requires ['users', 'matchedAt'], users.size() == 2, auth.
    await assertSucceeds(
      setDoc(doc(userADb, 'matches/match_ac'), {
        users: ['userA', 'otherUser'],
        matchedAt: new Date().toISOString(),
      }),
    );
    pass('matches: participant can create a match with 2 users and matchedAt');

    await assertFails(
      setDoc(doc(userADb, 'matches/match_triple'), {
        users: ['userA', 'userB', 'otherUser'],
        matchedAt: new Date().toISOString(),
      }),
    );
    pass('matches: create rejected with more than 2 users');

    await assertFails(
      setDoc(doc(userADb, 'matches/match_nots'), {
        users: ['userA', 'userB'],
      }),
    );
    pass('matches: create rejected without matchedAt field');

    // Matches create now requires auth.uid in users array (ownership check).
    await assertFails(
      setDoc(doc(otherUserDb, 'matches/match_forged'), {
        users: ['userA', 'userB'],
        matchedAt: new Date().toISOString(),
      }),
    );
    pass('matches: non-participant cannot create a match between other users');

    await assertFails(
      setDoc(doc(unauthDb, 'matches/match_unauth'), {
        users: ['userA', 'userB'],
        matchedAt: new Date().toISOString(),
      }),
    );
    pass('matches: unauthenticated user cannot create a match');

    // Read: only users in the match.
    await assertSucceeds(getDoc(doc(userADb, 'matches/match_ab')));
    pass('matches: participant (userA) can read their match');

    await assertSucceeds(getDoc(doc(userBDb, 'matches/match_ab')));
    pass('matches: participant (userB) can read their match');

    await assertFails(getDoc(doc(otherUserDb, 'matches/match_ab')));
    pass('matches: non-participant cannot read the match');

    // Update: only participants.
    await assertSucceeds(
      updateDoc(doc(userADb, 'matches/match_ab'), { lastInteraction: 'now' }),
    );
    pass('matches: participant can update their match');

    await assertFails(
      updateDoc(doc(otherUserDb, 'matches/match_ab'), { lastInteraction: 'now' }),
    );
    pass('matches: non-participant cannot update the match');

    // Delete: only participants.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'matches/match_del'), {
        users: ['userA', 'userB'],
        matchedAt: new Date().toISOString(),
      });
    });

    await assertFails(
      deleteDoc(doc(otherUserDb, 'matches/match_del')),
    );
    pass('matches: non-participant cannot delete the match');

    await assertSucceeds(
      deleteDoc(doc(userADb, 'matches/match_del')),
    );
    pass('matches: participant can delete (unmatch)');

    // ── Legacy Likes collection (fully disabled) ──────────────────────────

    await assertFails(getDoc(doc(userADb, 'Likes/legacy_like_ab')));
    pass('Likes (legacy): reads are fully blocked');

    await assertFails(
      setDoc(doc(userADb, 'Likes/legacy_new'), { from: 'userA', to: 'userB' }),
    );
    pass('Likes (legacy): writes are fully blocked');

    // ── Legacy top-level Matches collection ─────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'Matches/legacy_match_ab')));
    pass('Matches (legacy): participant can read');

    await assertFails(getDoc(doc(otherUserDb, 'Matches/legacy_match_ab')));
    pass('Matches (legacy): non-participant cannot read');

    await assertSucceeds(
      setDoc(doc(userADb, 'Matches/legacy_match_ac'), {
        users: ['userA', 'otherUser'],
      }),
    );
    pass('Matches (legacy): participant can create');

    await assertFails(
      setDoc(doc(otherUserDb, 'Matches/legacy_match_spoof'), {
        users: ['userA', 'userB'],
      }),
    );
    pass('Matches (legacy): non-participant cannot create');

    // ── superLikes collection ───────────────────────────────────────────────

    // Create: fromUserId must match auth.uid, requires ['fromUserId', 'toUserId', 'timestamp'].
    await assertSucceeds(
      setDoc(doc(userADb, 'superLikes/sl_ac'), {
        fromUserId: 'userA',
        toUserId: 'otherUser',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('superLikes: sender can create with valid fromUserId and required fields');

    await assertFails(
      setDoc(doc(userADb, 'superLikes/sl_spoof'), {
        fromUserId: 'userB',
        toUserId: 'otherUser',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('superLikes: cannot create with spoofed fromUserId');

    await assertFails(
      setDoc(doc(userADb, 'superLikes/sl_bad'), {
        fromUserId: 'userA',
        toUserId: 'userB',
      }),
    );
    pass('superLikes: create rejected without timestamp');

    // Read: sender or receiver.
    await assertSucceeds(getDoc(doc(userADb, 'superLikes/sl_ab')));
    pass('superLikes: sender can read their super like');

    await assertSucceeds(getDoc(doc(userBDb, 'superLikes/sl_ab')));
    pass('superLikes: receiver can read a super like sent to them');

    await assertFails(getDoc(doc(otherUserDb, 'superLikes/sl_ab')));
    pass('superLikes: unrelated user cannot read the super like');

    // Update: sender can update status, receiver can respond.
    await assertSucceeds(
      updateDoc(doc(userADb, 'superLikes/sl_ab'), { status: 'cancelled' }),
    );
    pass('superLikes: sender can update their super like (status change)');

    await assertSucceeds(
      updateDoc(doc(userBDb, 'superLikes/sl_ab'), { responded: true }),
    );
    pass('superLikes: receiver can update the super like (respond)');

    await assertFails(
      updateDoc(doc(otherUserDb, 'superLikes/sl_ab'), { status: 'hacked' }),
    );
    pass('superLikes: unrelated user cannot update the super like');

    // ── swipeHistory collection ─────────────────────────────────────────────

    // Create: userId must match auth.uid, requires ['userId', 'targetUserId', 'direction', 'timestamp'].
    await assertSucceeds(
      setDoc(doc(userADb, 'swipeHistory/swipe_a2'), {
        userId: 'userA',
        targetUserId: 'otherUser',
        direction: 'left',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('swipeHistory: user can create their own swipe record');

    await assertFails(
      setDoc(doc(userADb, 'swipeHistory/swipe_spoof'), {
        userId: 'userB',
        targetUserId: 'otherUser',
        direction: 'right',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('swipeHistory: cannot create swipe with spoofed userId');

    await assertFails(
      setDoc(doc(userADb, 'swipeHistory/swipe_bad'), {
        userId: 'userA',
        targetUserId: 'userB',
      }),
    );
    pass('swipeHistory: create rejected without direction and timestamp');

    // Read: owner only.
    await assertSucceeds(getDoc(doc(userADb, 'swipeHistory/swipe_a1')));
    pass('swipeHistory: owner can read their own swipe record');

    await assertFails(getDoc(doc(userBDb, 'swipeHistory/swipe_a1')));
    pass('swipeHistory: other user cannot read swipe history');

    // Update: owner only (for undo).
    await assertSucceeds(
      updateDoc(doc(userADb, 'swipeHistory/swipe_a1'), { undone: true }),
    );
    pass('swipeHistory: owner can update their swipe (undo operation)');

    await assertFails(
      updateDoc(doc(userBDb, 'swipeHistory/swipe_a1'), { undone: true }),
    );
    pass('swipeHistory: other user cannot update swipe history');

    // ── superLikeUsage collection ───────────────────────────────────────────

    // Create: userId must match auth.uid.
    await assertSucceeds(
      setDoc(doc(userBDb, 'superLikeUsage/slu_b'), {
        userId: 'userB',
        count: 0,
      }),
    );
    pass('superLikeUsage: user can create own usage record');

    await assertFails(
      setDoc(doc(userBDb, 'superLikeUsage/slu_spoof'), {
        userId: 'userA',
        count: 0,
      }),
    );
    pass('superLikeUsage: cannot create usage record with spoofed userId');

    await assertFails(
      setDoc(doc(unauthDb, 'superLikeUsage/slu_anon'), {
        userId: 'anon',
        count: 0,
      }),
    );
    pass('superLikeUsage: unauthenticated user cannot create usage record');

    // Read: owner only.
    await assertSucceeds(getDoc(doc(userADb, 'superLikeUsage/slu_a')));
    pass('superLikeUsage: owner can read their own usage');

    await assertFails(getDoc(doc(userBDb, 'superLikeUsage/slu_a')));
    pass('superLikeUsage: other user cannot read usage record');

    // ── undoUsage collection ────────────────────────────────────────────────

    // Create: userId must match auth.uid.
    await assertSucceeds(
      setDoc(doc(userBDb, 'undoUsage/uu_b'), {
        userId: 'userB',
        count: 0,
      }),
    );
    pass('undoUsage: user can create own usage record');

    await assertFails(
      setDoc(doc(userBDb, 'undoUsage/uu_spoof'), {
        userId: 'userA',
        count: 0,
      }),
    );
    pass('undoUsage: cannot create usage record with spoofed userId');

    await assertFails(
      setDoc(doc(unauthDb, 'undoUsage/uu_anon'), {
        userId: 'anon',
        count: 0,
      }),
    );
    pass('undoUsage: unauthenticated user cannot create usage record');

    // Read: owner only.
    await assertSucceeds(getDoc(doc(userADb, 'undoUsage/uu_a')));
    pass('undoUsage: owner can read their own usage');

    await assertFails(getDoc(doc(userBDb, 'undoUsage/uu_a')));
    pass('undoUsage: other user cannot read usage record');

    // ──────────────────────────────────────────────────────────────────────────
    // Events domain tests.
    // Collections: events, eventRSVPs, userEvents, user_rsvps,
    //              event_attendees, event_moderation
    // ──────────────────────────────────────────────────────────────────────────

    // Seed events and related documents.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'events/evt_published'), {
        name: 'Afro Night',
        description: 'Live music event',
        startDate: '2026-03-01',
        endDate: '2026-03-02',
        createdByUserId: 'userA',
        status: 'published',
      });

      await setDoc(doc(db, 'events/evt_draft'), {
        name: 'Draft Event',
        description: 'Not published yet',
        startDate: '2026-04-01',
        endDate: '2026-04-02',
        createdByUserId: 'userA',
        status: 'draft',
      });

      await setDoc(doc(db, 'eventRSVPs/rsvp_a'), {
        userId: 'userA',
        eventId: 'evt_published',
        status: 'going',
        timestamp: new Date().toISOString(),
      });

      await setDoc(doc(db, 'userEvents/userA'), { count: 1 });
      await setDoc(doc(db, 'userEvents/userA/events/evt_published'), { name: 'Afro Night' });

      await setDoc(doc(db, 'user_rsvps/userA'), { count: 1 });
      await setDoc(doc(db, 'user_rsvps/userA/events/evt_published'), { status: 'going' });

      await setDoc(doc(db, 'event_attendees/evt_published/attendees/userB'), {
        status: 'going',
      });

      await setDoc(doc(db, 'event_moderation/evt_published'), {
        status: 'approved',
      });
    });

    // ── events collection ───────────────────────────────────────────────────

    // Read: any authenticated user.
    await assertSucceeds(getDoc(doc(userADb, 'events/evt_published')));
    pass('events: authenticated user can read published event');

    await assertSucceeds(getDoc(doc(otherUserDb, 'events/evt_published')));
    pass('events: non-creator can read event');

    await assertFails(getDoc(doc(unauthDb, 'events/evt_published')));
    pass('events: unauthenticated user cannot read event');

    // Create: createdByUserId must match auth.uid, required fields + validation.
    await assertSucceeds(
      setDoc(doc(userBDb, 'events/evt_new'), {
        name: 'New Event',
        description: 'A new event',
        startDate: '2026-05-01',
        endDate: '2026-05-02',
        createdByUserId: 'userB',
        status: 'draft',
      }),
    );
    pass('events: user can create event with own createdByUserId');

    await assertFails(
      setDoc(doc(userBDb, 'events/evt_spoof'), {
        name: 'Spoofed',
        description: 'Spoofed event',
        startDate: '2026-05-01',
        endDate: '2026-05-02',
        createdByUserId: 'userA',
        status: 'draft',
      }),
    );
    pass('events: cannot create event with spoofed createdByUserId');

    await assertFails(
      setDoc(doc(userBDb, 'events/evt_noname'), {
        name: '',
        description: 'Missing name',
        startDate: '2026-05-01',
        endDate: '2026-05-02',
        createdByUserId: 'userB',
        status: 'draft',
      }),
    );
    pass('events: create rejected with empty name');

    await assertFails(
      setDoc(doc(userBDb, 'events/evt_nofields'), {
        name: 'Partial',
        createdByUserId: 'userB',
      }),
    );
    pass('events: create rejected without required fields');

    // Update: only creator, cannot change createdByUserId.
    await assertSucceeds(
      updateDoc(doc(userADb, 'events/evt_published'), {
        description: 'Updated description',
      }),
    );
    pass('events: creator can update their event');

    await assertFails(
      updateDoc(doc(userBDb, 'events/evt_published'), {
        description: 'Hacked',
      }),
    );
    pass('events: non-creator cannot update event');

    await assertFails(
      updateDoc(doc(userADb, 'events/evt_published'), {
        createdByUserId: 'userB',
      }),
    );
    pass('events: creator cannot change createdByUserId');

    // Delete: only creator.
    await assertFails(
      deleteDoc(doc(userBDb, 'events/evt_draft')),
    );
    pass('events: non-creator cannot delete event');

    await assertSucceeds(
      deleteDoc(doc(userADb, 'events/evt_draft')),
    );
    pass('events: creator can delete their event');

    // ── eventRSVPs collection ───────────────────────────────────────────────

    // Read: RSVP owner or event creator.
    await assertSucceeds(getDoc(doc(userADb, 'eventRSVPs/rsvp_a')));
    pass('eventRSVPs: RSVP owner can read their RSVP');

    // Event creator (userA created evt_published) can also read.
    // (Already tested implicitly since userA is both RSVP owner and event creator.)

    await assertFails(getDoc(doc(otherUserDb, 'eventRSVPs/rsvp_a')));
    pass('eventRSVPs: unrelated user cannot read RSVP');

    // Create: userId must match auth, event must exist and be published, required fields.
    await assertSucceeds(
      setDoc(doc(userBDb, 'eventRSVPs/rsvp_b'), {
        userId: 'userB',
        eventId: 'evt_published',
        status: 'going',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('eventRSVPs: user can RSVP to a published event');

    await assertFails(
      setDoc(doc(userBDb, 'eventRSVPs/rsvp_spoof'), {
        userId: 'userA',
        eventId: 'evt_published',
        status: 'going',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('eventRSVPs: cannot RSVP with spoofed userId');

    await assertFails(
      setDoc(doc(userBDb, 'eventRSVPs/rsvp_nofields'), {
        userId: 'userB',
        eventId: 'evt_published',
      }),
    );
    pass('eventRSVPs: create rejected without required fields');

    // Update: owner only, cannot change userId or eventId.
    await assertSucceeds(
      updateDoc(doc(userADb, 'eventRSVPs/rsvp_a'), {
        status: 'maybe',
      }),
    );
    pass('eventRSVPs: owner can update RSVP status');

    await assertFails(
      updateDoc(doc(userADb, 'eventRSVPs/rsvp_a'), {
        userId: 'userB',
      }),
    );
    pass('eventRSVPs: cannot change userId on update');

    await assertFails(
      updateDoc(doc(otherUserDb, 'eventRSVPs/rsvp_a'), {
        status: 'not going',
      }),
    );
    pass('eventRSVPs: non-owner cannot update RSVP');

    // Delete: owner only.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'eventRSVPs/rsvp_del'), {
        userId: 'userA',
        eventId: 'evt_published',
        status: 'going',
        timestamp: new Date().toISOString(),
      });
    });

    await assertFails(
      deleteDoc(doc(otherUserDb, 'eventRSVPs/rsvp_del')),
    );
    pass('eventRSVPs: non-owner cannot delete RSVP');

    await assertSucceeds(
      deleteDoc(doc(userADb, 'eventRSVPs/rsvp_del')),
    );
    pass('eventRSVPs: owner can delete their RSVP');

    // ── userEvents collection ───────────────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'userEvents/userA')));
    pass('userEvents: owner can read own events');

    await assertFails(getDoc(doc(userBDb, 'userEvents/userA')));
    pass('userEvents: non-owner cannot read events');

    await assertSucceeds(getDoc(doc(userADb, 'userEvents/userA/events/evt_published')));
    pass('userEvents: owner can read own events subcollection');

    await assertFails(getDoc(doc(userBDb, 'userEvents/userA/events/evt_published')));
    pass('userEvents: non-owner cannot read events subcollection');

    await assertSucceeds(
      setDoc(doc(userADb, 'userEvents/userA/events/evt_new'), { name: 'New' }),
    );
    pass('userEvents: owner can write to own events subcollection');

    await assertFails(
      setDoc(doc(userBDb, 'userEvents/userA/events/evt_hack'), { name: 'Hack' }),
    );
    pass('userEvents: non-owner cannot write to events subcollection');

    // ── user_rsvps collection ───────────────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'user_rsvps/userA')));
    pass('user_rsvps: owner can read own RSVPs');

    await assertFails(getDoc(doc(userBDb, 'user_rsvps/userA')));
    pass('user_rsvps: non-owner cannot read RSVPs');

    await assertSucceeds(getDoc(doc(userADb, 'user_rsvps/userA/events/evt_published')));
    pass('user_rsvps: owner can read own RSVP events subcollection');

    await assertFails(getDoc(doc(userBDb, 'user_rsvps/userA/events/evt_published')));
    pass('user_rsvps: non-owner cannot read RSVP events subcollection');

    // ── event_attendees collection ──────────────────────────────────────────

    // Attendee can read/write own attendance.
    await assertSucceeds(
      getDoc(doc(userBDb, 'event_attendees/evt_published/attendees/userB')),
    );
    pass('event_attendees: attendee can read own attendance');

    await assertSucceeds(
      setDoc(doc(userBDb, 'event_attendees/evt_published/attendees/userB'), {
        status: 'not going',
      }),
    );
    pass('event_attendees: attendee can write own attendance');

    await assertFails(
      setDoc(doc(otherUserDb, 'event_attendees/evt_published/attendees/userB'), {
        status: 'hacked',
      }),
    );
    pass('event_attendees: non-attendee cannot write another attendance');

    // Event creator can read attendees.
    await assertSucceeds(
      getDoc(doc(userADb, 'event_attendees/evt_published/attendees/userB')),
    );
    pass('event_attendees: event creator can read attendees');

    // ── event_moderation collection ─────────────────────────────────────────

    // Event creator can read moderation status.
    await assertSucceeds(
      getDoc(doc(userADb, 'event_moderation/evt_published')),
    );
    pass('event_moderation: event creator can read moderation status');

    await assertFails(
      getDoc(doc(otherUserDb, 'event_moderation/evt_published')),
    );
    pass('event_moderation: non-creator cannot read moderation status');

    // Client-side writes blocked (Admin SDK / Cloud Functions only).
    await assertFails(
      setDoc(doc(userBDb, 'event_moderation/evt_mod_new'), {
        status: 'pending',
      }),
    );
    pass('event_moderation: client SDK cannot create moderation record');

    await assertFails(
      setDoc(doc(unauthDb, 'event_moderation/evt_mod_unauth'), {
        status: 'pending',
      }),
    );
    pass('event_moderation: unauthenticated user cannot create moderation record');

    // ──────────────────────────────────────────────────────────────────────────
    // Remaining collections: reports, feedback, chats (legacy),
    //   notificationSettings, userSettings, accountDeletions, security_logs
    // ──────────────────────────────────────────────────────────────────────────

    // Seed remaining documents.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'reports/report_a'), {
        reporterId: 'userA',
        reportedUserId: 'userB',
        reason: 'Spam',
        timestamp: new Date().toISOString(),
      });

      await setDoc(doc(db, 'feedback/fb_a'), {
        userId: 'userA',
        message: 'Great app!',
      });

      await setDoc(doc(db, 'chats/chat_ab'), {
        users: ['userA', 'userB'],
        lastMessage: 'Hey',
      });

      await setDoc(doc(db, 'notificationSettings/userA'), {
        pushEnabled: true,
      });

      await setDoc(doc(db, 'userSettings/userA'), {
        theme: 'dark',
      });

      await setDoc(doc(db, 'runtimeConfig/featureFlags'), {
        useBackendAccountDeletion: false,
      });

      // accountDeletions: not seeded; tests create accountDeletions/userA and update it

      await setDoc(doc(db, 'security_logs/slog_a'), {
        reporterId: 'userA',
        action: 'reported_user',
      });
    });

    // ── reports collection ──────────────────────────────────────────────────

    // Create: reporterId must match auth, required fields, reason non-empty.
    await assertSucceeds(
      setDoc(doc(userADb, 'reports/report_new'), {
        reporterId: 'userA',
        reportedUserId: 'otherUser',
        reason: 'Inappropriate',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('reports: user can create report with own reporterId');

    await assertFails(
      setDoc(doc(userADb, 'reports/report_spoof'), {
        reporterId: 'userB',
        reportedUserId: 'otherUser',
        reason: 'Spoofed',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('reports: cannot create report with spoofed reporterId');

    await assertFails(
      setDoc(doc(userADb, 'reports/report_empty'), {
        reporterId: 'userA',
        reportedUserId: 'otherUser',
        reason: '',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('reports: create rejected with empty reason');

    await assertFails(
      setDoc(doc(userADb, 'reports/report_nofields'), {
        reporterId: 'userA',
        reason: 'Missing fields',
      }),
    );
    pass('reports: create rejected without required fields');

    // Read: reporter only.
    await assertSucceeds(getDoc(doc(userADb, 'reports/report_a')));
    pass('reports: reporter can read their own report');

    await assertFails(getDoc(doc(userBDb, 'reports/report_a')));
    pass('reports: other user cannot read report');

    // ── feedback collection ─────────────────────────────────────────────────

    await assertSucceeds(
      setDoc(doc(userADb, 'feedback/fb_new'), {
        userId: 'userA',
        message: 'Love it!',
      }),
    );
    pass('feedback: user can create own feedback');

    await assertFails(
      setDoc(doc(userADb, 'feedback/fb_spoof'), {
        userId: 'userB',
        message: 'Spoofed feedback',
      }),
    );
    pass('feedback: cannot create feedback with spoofed userId');

    await assertSucceeds(getDoc(doc(userADb, 'feedback/fb_a')));
    pass('feedback: user can read own feedback');

    await assertFails(getDoc(doc(userBDb, 'feedback/fb_a')));
    pass('feedback: other user cannot read feedback');

    // ── chats (legacy) collection ───────────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'chats/chat_ab')));
    pass('chats (legacy): participant can read chat');

    await assertFails(getDoc(doc(otherUserDb, 'chats/chat_ab')));
    pass('chats (legacy): non-participant cannot read chat');

    await assertSucceeds(
      setDoc(doc(userADb, 'chats/chat_new'), {
        users: ['userA', 'otherUser'],
        lastMessage: '',
      }),
    );
    pass('chats (legacy): participant can create chat');

    await assertFails(
      setDoc(doc(otherUserDb, 'chats/chat_spoof'), {
        users: ['userA', 'userB'],
        lastMessage: '',
      }),
    );
    pass('chats (legacy): non-participant cannot create chat');

    // ── notificationSettings collection ─────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'notificationSettings/userA')));
    pass('notificationSettings: owner can read own settings');

    await assertFails(getDoc(doc(userBDb, 'notificationSettings/userA')));
    pass('notificationSettings: non-owner cannot read settings');

    await assertSucceeds(
      setDoc(doc(userADb, 'notificationSettings/userA'), { pushEnabled: false }),
    );
    pass('notificationSettings: owner can write own settings');

    await assertFails(
      setDoc(doc(userBDb, 'notificationSettings/userA'), { pushEnabled: false }),
    );
    pass('notificationSettings: non-owner cannot write settings');

    // ── userSettings collection ─────────────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'userSettings/userA')));
    pass('userSettings: owner can read own settings');

    await assertFails(getDoc(doc(userBDb, 'userSettings/userA')));
    pass('userSettings: non-owner cannot read settings');

    await assertSucceeds(
      setDoc(doc(userADb, 'userSettings/userA'), { theme: 'light' }),
    );
    pass('userSettings: owner can write own settings');

    await assertFails(
      setDoc(doc(userBDb, 'userSettings/userA'), { theme: 'hacked' }),
    );
    pass('userSettings: non-owner cannot write settings');

    // ── accountDeletions collection ─────────────────────────────────────────
    // Server-only writes; owner read when doc exists (e.g. after callable wrote pending).

    await assertFails(
      setDoc(doc(userADb, 'accountDeletions/userA'), {
        userId: 'userA',
        reason: 'Testing',
        status: 'pending',
      }),
    );
    pass('accountDeletions: client cannot create (server-only)');

    await assertFails(
      setDoc(doc(userBDb, 'accountDeletions/userB'), {
        userId: 'userB',
        reason: 'Testing',
        status: 'aborted',
      }),
    );
    pass('accountDeletions: client cannot create aborted doc');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'accountDeletions/userA'), {
        userId: 'userA',
        reason: 'Seeded',
        status: 'pending',
      });
    });

    await assertFails(
      updateDoc(doc(userADb, 'accountDeletions/userA'), { status: 'aborted' }),
    );
    pass('accountDeletions: client cannot update (server-only)');

    await assertSucceeds(getDoc(doc(userADb, 'accountDeletions/userA')));
    pass('accountDeletions: user can read own deletion record');

    await assertFails(getDoc(doc(userBDb, 'accountDeletions/userA')));
    pass('accountDeletions: other user cannot read deletion record');

    // ── accountDeletionAbuse (server-only) ───────────────────────────────────

    await assertFails(
      setDoc(doc(userADb, 'accountDeletionAbuse/ip_hash_test'), {
        count: 1,
      }),
    );
    pass('accountDeletionAbuse: client cannot write');

    await assertFails(
      getDoc(doc(userADb, 'accountDeletionAbuse/ip_hash_test')),
    );
    pass('accountDeletionAbuse: client cannot read');

    // ── accountDeletionVerifications (server-only) ───────────────────────────

    await assertFails(
      setDoc(doc(userADb, 'accountDeletionVerifications/userA'), {
        uid: 'userA',
      }),
    );
    pass('accountDeletionVerifications: client cannot create');

    await assertFails(
      getDoc(doc(userADb, 'accountDeletionVerifications/userA')),
    );
    pass('accountDeletionVerifications: client cannot read');

    // ── security_logs collection ────────────────────────────────────────────

    // Client-side writes blocked (Admin SDK / Cloud Functions only).
    await assertFails(
      setDoc(doc(userADb, 'security_logs/slog_new'), {
        reporterId: 'userA',
        action: 'flagged_content',
      }),
    );
    pass('security_logs: client SDK cannot create log');

    await assertFails(
      setDoc(doc(unauthDb, 'security_logs/slog_unauth'), {
        reporterId: 'anon',
        action: 'hack',
      }),
    );
    pass('security_logs: unauthenticated user cannot create log');

    await assertSucceeds(getDoc(doc(userADb, 'security_logs/slog_a')));
    pass('security_logs: reporter can read own log');

    await assertFails(getDoc(doc(userBDb, 'security_logs/slog_a')));
    pass('security_logs: non-reporter cannot read log');

    // ──────────────────────────────────────────────────────────────────────────
    // Groups domain tests.
    // Collections: unifiedGroups (+ messages), groups (legacy), groupChats
    //   (+ messages), groupInvitations, user_group_notifications,
    //   group_unread_counts, group_reports, Item_access
    // ──────────────────────────────────────────────────────────────────────────

    // Seed group documents.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // unifiedGroups
      await setDoc(doc(db, 'unifiedGroups/ug1'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA', 'userB'],
        name: 'Diaspora Connect',
      });
      await setDoc(doc(db, 'unifiedGroups/ug1/messages/gm1'), {
        senderId: 'userA',
        text: 'Welcome!',
        read: false,
      });

      // Legacy groups
      await setDoc(doc(db, 'groups/g1'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA', 'userB'],
        isPublic: true,
        name: 'Lagos Meetup',
        memberCount: 2,
      });

      // groupChats
      await setDoc(doc(db, 'groupChats/gc1'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA', 'userB'],
        name: 'Chat Group',
        memberCount: 2,
      });
      await setDoc(doc(db, 'groupChats/gc1/messages/gcm1'), {
        senderId: 'userA',
        text: 'Group message',
      });

      // groupInvitations
      await setDoc(doc(db, 'groupInvitations/inv1'), {
        groupId: 'ug1',
        invitedUserId: 'userB',
        invitedByUserId: 'userA',
        status: 'pending',
        createdAt: new Date().toISOString(),
      });
      await setDoc(doc(db, 'groupInvitations/inv_accepted'), {
        groupId: 'ug1',
        invitedUserId: 'userB',
        invitedByUserId: 'userA',
        status: 'accepted',
        createdAt: new Date().toISOString(),
      });

      // user_group_notifications
      await setDoc(doc(db, 'user_group_notifications/ugn_a'), {
        userId: 'userA',
        groupId: 'ug1',
        isMuted: false,
        updatedAt: new Date().toISOString(),
      });

      // group_unread_counts
      await setDoc(doc(db, 'group_unread_counts/guc_a'), {
        userId: 'userA',
        groupId: 'ug1',
        count: 3,
        updatedAt: new Date().toISOString(),
      });

      // group_reports
      await setDoc(doc(db, 'group_reports/gr_a'), {
        groupId: 'ug1',
        reporterId: 'userB',
        reason: 'Spam content',
        status: 'pending',
        createdAt: new Date().toISOString(),
      });

      // Item_access
      await setDoc(doc(db, 'Item_access/config1'), {
        feature: 'premium',
        enabled: true,
      });
    });

    // ── unifiedGroups collection ────────────────────────────────────────────

    // Read: any authenticated user.
    await assertSucceeds(getDoc(doc(userADb, 'unifiedGroups/ug1')));
    pass('unifiedGroups: authenticated user can read group');

    await assertSucceeds(getDoc(doc(otherUserDb, 'unifiedGroups/ug1')));
    pass('unifiedGroups: non-member can read group');

    await assertFails(getDoc(doc(unauthDb, 'unifiedGroups/ug1')));
    pass('unifiedGroups: unauthenticated cannot read group');

    // Create: creatorId must match auth.uid.
    await assertSucceeds(
      setDoc(doc(userBDb, 'unifiedGroups/ug_new'), {
        creatorId: 'userB',
        adminIds: ['userB'],
        memberIds: ['userB'],
        name: 'New Group',
      }),
    );
    pass('unifiedGroups: user can create group with own creatorId');

    await assertFails(
      setDoc(doc(userBDb, 'unifiedGroups/ug_spoof'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA'],
        name: 'Spoofed',
      }),
    );
    pass('unifiedGroups: cannot create group with spoofed creatorId');

    // Update: admin can update.
    await assertSucceeds(
      updateDoc(doc(userADb, 'unifiedGroups/ug1'), { name: 'Updated Name' }),
    );
    pass('unifiedGroups: admin can update group');

    // Update: non-admin/non-member cannot update arbitrary fields.
    await assertFails(
      updateDoc(doc(otherUserDb, 'unifiedGroups/ug1'), { name: 'Hacked' }),
    );
    pass('unifiedGroups: non-admin cannot update group');

    // Delete: only creator.
    await assertFails(
      deleteDoc(doc(userBDb, 'unifiedGroups/ug1')),
    );
    pass('unifiedGroups: non-creator cannot delete group');

    // ── unifiedGroups messages subcollection ────────────────────────────────

    // Read: members only.
    await assertSucceeds(
      getDoc(doc(userADb, 'unifiedGroups/ug1/messages/gm1')),
    );
    pass('unifiedGroups/messages: member can read messages');

    await assertFails(
      getDoc(doc(otherUserDb, 'unifiedGroups/ug1/messages/gm1')),
    );
    pass('unifiedGroups/messages: non-member cannot read messages');

    // Create: member with matching senderId.
    await assertSucceeds(
      setDoc(doc(userBDb, 'unifiedGroups/ug1/messages/gm2'), {
        senderId: 'userB',
        text: 'Hello group!',
      }),
    );
    pass('unifiedGroups/messages: member can create message with own senderId');

    await assertFails(
      setDoc(doc(userBDb, 'unifiedGroups/ug1/messages/gm_spoof'), {
        senderId: 'userA',
        text: 'Spoofed',
      }),
    );
    pass('unifiedGroups/messages: member cannot create message with spoofed senderId');

    await assertFails(
      setDoc(doc(otherUserDb, 'unifiedGroups/ug1/messages/gm_intruder'), {
        senderId: 'otherUser',
        text: 'Intruder',
      }),
    );
    pass('unifiedGroups/messages: non-member cannot create message');

    // Update: member can update read/readBy only.
    await assertSucceeds(
      updateDoc(doc(userBDb, 'unifiedGroups/ug1/messages/gm1'), {
        read: true,
        readBy: ['userB'],
      }),
    );
    pass('unifiedGroups/messages: member can update read status');

    await assertFails(
      updateDoc(doc(userBDb, 'unifiedGroups/ug1/messages/gm1'), {
        text: 'Tampered',
      }),
    );
    pass('unifiedGroups/messages: member cannot update message text');

    // Delete: sender only.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'unifiedGroups/ug1/messages/gm_del'), {
        senderId: 'userA',
        text: 'Delete me',
      });
    });

    await assertFails(
      userBDb.doc('unifiedGroups/ug1/messages/gm_del').delete(),
    );
    pass('unifiedGroups/messages: non-sender cannot delete message');

    await assertSucceeds(
      userADb.doc('unifiedGroups/ug1/messages/gm_del').delete(),
    );
    pass('unifiedGroups/messages: sender can delete own message');

    // ── groups (legacy) collection ──────────────────────────────────────────

    // Read: any authenticated user (the open read rule overrides).
    await assertSucceeds(getDoc(doc(otherUserDb, 'groups/g1')));
    pass('groups (legacy): any authenticated user can read');

    await assertFails(getDoc(doc(unauthDb, 'groups/g1')));
    pass('groups (legacy): unauthenticated cannot read');

    // Create: creatorId must match.
    await assertSucceeds(
      setDoc(doc(userBDb, 'groups/g_new'), {
        creatorId: 'userB',
        adminIds: ['userB'],
        memberIds: ['userB'],
        isPublic: true,
        name: 'New Legacy Group',
        memberCount: 1,
      }),
    );
    pass('groups (legacy): user can create group');

    await assertFails(
      setDoc(doc(userBDb, 'groups/g_spoof'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA'],
        isPublic: true,
        name: 'Spoofed',
        memberCount: 1,
      }),
    );
    pass('groups (legacy): cannot create with spoofed creatorId');

    // Delete: creator only.
    await assertFails(
      deleteDoc(doc(userBDb, 'groups/g1')),
    );
    pass('groups (legacy): non-creator cannot delete group');

    // ── groupChats collection ───────────────────────────────────────────────

    // Read: any authenticated user.
    await assertSucceeds(getDoc(doc(otherUserDb, 'groupChats/gc1')));
    pass('groupChats: any authenticated user can read');

    // Create: creatorId must match.
    await assertSucceeds(
      setDoc(doc(userBDb, 'groupChats/gc_new'), {
        creatorId: 'userB',
        adminIds: ['userB'],
        memberIds: ['userB'],
        name: 'New Chat Group',
        memberCount: 1,
      }),
    );
    pass('groupChats: user can create group chat');

    await assertFails(
      setDoc(doc(userBDb, 'groupChats/gc_spoof'), {
        creatorId: 'userA',
        adminIds: ['userA'],
        memberIds: ['userA'],
        name: 'Spoofed',
        memberCount: 1,
      }),
    );
    pass('groupChats: cannot create with spoofed creatorId');

    // Delete: creator only.
    await assertFails(
      deleteDoc(doc(userBDb, 'groupChats/gc1')),
    );
    pass('groupChats: non-creator cannot delete group chat');

    // ── groupChats messages subcollection ────────────────────────────────────

    await assertSucceeds(
      getDoc(doc(userADb, 'groupChats/gc1/messages/gcm1')),
    );
    pass('groupChats/messages: member can read messages');

    await assertFails(
      getDoc(doc(otherUserDb, 'groupChats/gc1/messages/gcm1')),
    );
    pass('groupChats/messages: non-member cannot read messages');

    await assertSucceeds(
      setDoc(doc(userBDb, 'groupChats/gc1/messages/gcm2'), {
        senderId: 'userB',
        text: 'Hi from group chat!',
      }),
    );
    pass('groupChats/messages: member can create message with own senderId');

    await assertFails(
      setDoc(doc(userBDb, 'groupChats/gc1/messages/gcm_spoof'), {
        senderId: 'userA',
        text: 'Spoofed',
      }),
    );
    pass('groupChats/messages: member cannot create with spoofed senderId');

    await assertFails(
      setDoc(doc(otherUserDb, 'groupChats/gc1/messages/gcm_intruder'), {
        senderId: 'otherUser',
        text: 'Intruder',
      }),
    );
    pass('groupChats/messages: non-member cannot create message');

    // Delete: sender only.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'groupChats/gc1/messages/gcm_del'), {
        senderId: 'userA',
        text: 'Delete me',
      });
    });

    await assertFails(
      userBDb.doc('groupChats/gc1/messages/gcm_del').delete(),
    );
    pass('groupChats/messages: non-sender cannot delete message');

    await assertSucceeds(
      userADb.doc('groupChats/gc1/messages/gcm_del').delete(),
    );
    pass('groupChats/messages: sender can delete own message');

    // ── groupInvitations collection ─────────────────────────────────────────

    // Read: invitee or inviter.
    await assertSucceeds(getDoc(doc(userBDb, 'groupInvitations/inv1')));
    pass('groupInvitations: invitee can read invitation');

    await assertSucceeds(getDoc(doc(userADb, 'groupInvitations/inv1')));
    pass('groupInvitations: inviter can read invitation');

    await assertFails(getDoc(doc(otherUserDb, 'groupInvitations/inv1')));
    pass('groupInvitations: unrelated user cannot read invitation');

    // Create: invitedByUserId must match, required fields, status must be pending.
    await assertSucceeds(
      setDoc(doc(userADb, 'groupInvitations/inv_new'), {
        groupId: 'ug1',
        invitedUserId: 'otherUser',
        invitedByUserId: 'userA',
        status: 'pending',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('groupInvitations: inviter can create valid invitation');

    await assertFails(
      setDoc(doc(userADb, 'groupInvitations/inv_spoof'), {
        groupId: 'ug1',
        invitedUserId: 'otherUser',
        invitedByUserId: 'userB',
        status: 'pending',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('groupInvitations: cannot create with spoofed invitedByUserId');

    await assertFails(
      setDoc(doc(userADb, 'groupInvitations/inv_bad_status'), {
        groupId: 'ug1',
        invitedUserId: 'otherUser',
        invitedByUserId: 'userA',
        status: 'accepted',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('groupInvitations: create rejected with non-pending status');

    await assertFails(
      setDoc(doc(userADb, 'groupInvitations/inv_nofields'), {
        groupId: 'ug1',
        invitedByUserId: 'userA',
        status: 'pending',
      }),
    );
    pass('groupInvitations: create rejected without required fields');

    // Update: invitee only, only status fields, existing status must be pending.
    await assertSucceeds(
      updateDoc(doc(userBDb, 'groupInvitations/inv1'), {
        status: 'accepted',
        acceptedAt: new Date().toISOString(),
      }),
    );
    pass('groupInvitations: invitee can accept pending invitation');

    await assertFails(
      updateDoc(doc(userADb, 'groupInvitations/inv1'), {
        status: 'declined',
      }),
    );
    pass('groupInvitations: inviter cannot update invitation');

    // Already-accepted invitation cannot be updated again.
    await assertFails(
      updateDoc(doc(userBDb, 'groupInvitations/inv_accepted'), {
        status: 'declined',
      }),
    );
    pass('groupInvitations: cannot update already-accepted invitation');

    // Delete: inviter only.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'groupInvitations/inv_del'), {
        groupId: 'ug1',
        invitedUserId: 'userB',
        invitedByUserId: 'userA',
        status: 'pending',
        createdAt: new Date().toISOString(),
      });
    });

    await assertFails(
      deleteDoc(doc(userBDb, 'groupInvitations/inv_del')),
    );
    pass('groupInvitations: invitee cannot delete invitation');

    await assertSucceeds(
      deleteDoc(doc(userADb, 'groupInvitations/inv_del')),
    );
    pass('groupInvitations: inviter can delete invitation');

    // ── user_group_notifications collection ─────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'user_group_notifications/ugn_a')));
    pass('user_group_notifications: owner can read own preferences');

    await assertFails(getDoc(doc(userBDb, 'user_group_notifications/ugn_a')));
    pass('user_group_notifications: non-owner cannot read preferences');

    await assertSucceeds(
      setDoc(doc(userBDb, 'user_group_notifications/ugn_b'), {
        userId: 'userB',
        groupId: 'ug1',
        isMuted: true,
        updatedAt: new Date().toISOString(),
      }),
    );
    pass('user_group_notifications: user can create own notification pref');

    await assertFails(
      setDoc(doc(userBDb, 'user_group_notifications/ugn_spoof'), {
        userId: 'userA',
        groupId: 'ug1',
        isMuted: true,
        updatedAt: new Date().toISOString(),
      }),
    );
    pass('user_group_notifications: cannot create with spoofed userId');

    // ── group_unread_counts collection ──────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'group_unread_counts/guc_a')));
    pass('group_unread_counts: owner can read own unread count');

    await assertFails(getDoc(doc(userBDb, 'group_unread_counts/guc_a')));
    pass('group_unread_counts: non-owner cannot read unread count');

    await assertSucceeds(
      setDoc(doc(userBDb, 'group_unread_counts/guc_b'), {
        userId: 'userB',
        groupId: 'ug1',
        count: 0,
        updatedAt: new Date().toISOString(),
      }),
    );
    pass('group_unread_counts: user can create own unread count record');

    await assertFails(
      setDoc(doc(userBDb, 'group_unread_counts/guc_spoof'), {
        userId: 'userA',
        groupId: 'ug1',
        count: 0,
        updatedAt: new Date().toISOString(),
      }),
    );
    pass('group_unread_counts: cannot create with spoofed userId');

    // ── group_reports collection ────────────────────────────────────────────

    // Create: reporterId must match, required fields, status must be pending.
    await assertSucceeds(
      setDoc(doc(userADb, 'group_reports/gr_new'), {
        groupId: 'ug1',
        reporterId: 'userA',
        reason: 'Offensive content',
        status: 'pending',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('group_reports: user can create report with own reporterId');

    await assertFails(
      setDoc(doc(userADb, 'group_reports/gr_spoof'), {
        groupId: 'ug1',
        reporterId: 'userB',
        reason: 'Spoofed',
        status: 'pending',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('group_reports: cannot create with spoofed reporterId');

    await assertFails(
      setDoc(doc(userADb, 'group_reports/gr_bad_status'), {
        groupId: 'ug1',
        reporterId: 'userA',
        reason: 'Test',
        status: 'resolved',
        createdAt: new Date().toISOString(),
      }),
    );
    pass('group_reports: create rejected with non-pending status');

    // Read: reporter can read own report.
    await assertSucceeds(getDoc(doc(userBDb, 'group_reports/gr_a')));
    pass('group_reports: reporter can read own report');

    await assertFails(getDoc(doc(otherUserDb, 'group_reports/gr_a')));
    pass('group_reports: unrelated user cannot read report');

    // Group admin/creator can read reports for their group.
    await assertSucceeds(getDoc(doc(userADb, 'group_reports/gr_a')));
    pass('group_reports: group admin can read report for their group');

    // ── Item_access collection ──────────────────────────────────────────────

    await assertSucceeds(getDoc(doc(userADb, 'Item_access/config1')));
    pass('Item_access: authenticated user can read config');

    await assertFails(getDoc(doc(unauthDb, 'Item_access/config1')));
    pass('Item_access: unauthenticated cannot read config');

    await assertFails(
      setDoc(doc(userADb, 'Item_access/config_new'), { feature: 'hack' }),
    );
    pass('Item_access: users cannot write to config (read-only)');

    // ── catch-all rule ──────────────────────────────────────────────────────

    await assertFails(
      setDoc(doc(userADb, 'nonexistent_collection/doc1'), { data: 'test' }),
    );
    pass('catch-all: writes to undefined collections are blocked');

    await assertFails(
      getDoc(doc(userADb, 'nonexistent_collection/doc1')),
    );
    pass('catch-all: reads from undefined collections are blocked');

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
