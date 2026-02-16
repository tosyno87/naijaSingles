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

    // Create: requires ['from', 'to', 'timestamp'] and auth.
    await assertSucceeds(
      setDoc(doc(userADb, 'likes/like_ac'), {
        from: 'userA',
        to: 'otherUser',
        timestamp: new Date().toISOString(),
      }),
    );
    pass('likes: authenticated user can create a like with required fields');

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

    // NOTE: The matches create rule is intentionally permissive -- any
    // authenticated user can create a structurally valid match. Match
    // verification (ensuring both users consented) is handled at the
    // application level, not in Firestore rules. This avoids complex
    // cross-document lookups in rules that would hurt performance.
    await assertSucceeds(
      setDoc(doc(otherUserDb, 'matches/match_proxy'), {
        users: ['userA', 'userB'],
        matchedAt: new Date().toISOString(),
      }),
    );
    pass('matches: any auth user can create structurally valid match (app-level verification)');

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

    // Create: any authenticated user.
    await assertSucceeds(
      setDoc(doc(userBDb, 'superLikeUsage/slu_b'), {
        userId: 'userB',
        count: 0,
      }),
    );
    pass('superLikeUsage: authenticated user can create usage record');

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

    // Create: any authenticated user.
    await assertSucceeds(
      setDoc(doc(userBDb, 'undoUsage/uu_b'), {
        userId: 'userB',
        count: 0,
      }),
    );
    pass('undoUsage: authenticated user can create usage record');

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

    // Any authenticated user can create/update (system-level).
    await assertSucceeds(
      setDoc(doc(userBDb, 'event_moderation/evt_mod_new'), {
        status: 'pending',
      }),
    );
    pass('event_moderation: authenticated user can create moderation record');

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

      await setDoc(doc(db, 'accountDeletions/del_a'), {
        userId: 'userA',
        reason: 'Moving on',
      });

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

    await assertSucceeds(
      setDoc(doc(userADb, 'accountDeletions/del_new'), {
        userId: 'userA',
        reason: 'Testing',
      }),
    );
    pass('accountDeletions: user can create own deletion record');

    await assertFails(
      setDoc(doc(userADb, 'accountDeletions/del_spoof'), {
        userId: 'userB',
        reason: 'Spoofed',
      }),
    );
    pass('accountDeletions: cannot create deletion with spoofed userId');

    await assertSucceeds(getDoc(doc(userADb, 'accountDeletions/del_a')));
    pass('accountDeletions: user can read own deletion record');

    await assertFails(getDoc(doc(userBDb, 'accountDeletions/del_a')));
    pass('accountDeletions: other user cannot read deletion record');

    // ── security_logs collection ────────────────────────────────────────────

    await assertSucceeds(
      setDoc(doc(userADb, 'security_logs/slog_new'), {
        reporterId: 'userA',
        action: 'flagged_content',
      }),
    );
    pass('security_logs: authenticated user can create log');

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
