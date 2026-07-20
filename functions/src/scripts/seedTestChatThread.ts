/**
 * Seed a chatThreads (+ optional matches) doc for manual Messages-tab QA.
 *
 * Usage:
 *   cd functions
 *   npx ts-node src/scripts/seedTestChatThread.ts \
 *     --project naijasingles-74a75 \
 *     --email-user obatos2015@gmail.com \
 *     --other-uid hnNwP71qSKXJ1Hxi73qiiiOiVk13
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default login.
 */

import * as admin from 'firebase-admin';

function parseArgs(argv: string[]): Record<string, string> {
  const out: Record<string, string> = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        out[key] = next;
        i++;
      } else {
        out[key] = 'true';
      }
    }
  }
  return out;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const projectId = args.project ?? 'naijasingles-74a75';
  const emailUser = args['email-user'];
  const otherUid = args['other-uid'];
  const emailUidArg = args['email-uid'];

  if ((!emailUser && !emailUidArg) || !otherUid) {
    console.error(
      'Usage: npx ts-node src/scripts/seedTestChatThread.ts ' +
        '--project naijasingles-74a75 ' +
        '(--email-user EMAIL | --email-uid UID) --other-uid UID'
    );
    process.exit(1);
  }

  admin.initializeApp({projectId});
  const auth = admin.auth();
  const db = admin.firestore();

  const emailUid = emailUidArg
    ? emailUidArg
    : (await auth.getUserByEmail(emailUser!)).uid;

  if (emailUid === otherUid) {
    throw new Error('email-user and other-uid must be different accounts');
  }

  const [emailDoc, otherDoc] = await Promise.all([
    db.collection('users').doc(emailUid).get(),
    db.collection('users').doc(otherUid).get(),
  ]);

  const emailName =
    (emailDoc.data()?.name as string | undefined)?.trim() ||
    (emailUser ? emailUser.split('@')[0] : undefined);
  const otherName = (otherDoc.data()?.name as string | undefined)?.trim();

  if (!emailName) {
    throw new Error(
      `users/${emailUid} has no name — set a profile name before seeding`,
    );
  }
  if (!otherName) {
    throw new Error(
      `users/${otherUid} has no name — set a profile name before seeding ` +
        `(do not use a placeholder like "Phone User")`,
    );
  }

  const firstPhoto = (data: Record<string, unknown> | undefined): string | undefined => {
    if (!data) return undefined;
    for (const key of ['photos', 'Pictures']) {
      const list = data[key];
      if (Array.isArray(list) && list.length > 0 && typeof list[0] === 'string') {
        return list[0];
      }
    }
    return undefined;
  };

  const emailAvatar = firstPhoto(emailDoc.data() as Record<string, unknown> | undefined);
  const otherAvatar = firstPhoto(otherDoc.data() as Record<string, unknown> | undefined);
  const userAvatars: Record<string, string> = {};
  if (emailAvatar) userAvatars[emailUid] = emailAvatar;
  if (otherAvatar) userAvatars[otherUid] = otherAvatar;

  const threadRef = db.collection('chatThreads').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await threadRef.set({
    userIds: [emailUid, otherUid],
    userNames: {
      [emailUid]: emailName,
      [otherUid]: otherName,
    },
    ...(Object.keys(userAvatars).length > 0 ? {userAvatars} : {}),
    lastMessage: null,
    lastMessageText: 'You matched! Say hello!',
    lastMessageSenderId: null,
    lastUpdated: now,
    createdAt: now,
    unreadCount: {
      [emailUid]: 0,
      [otherUid]: 0,
    },
  });

  const matchRef = db.collection('matches').doc();
  await matchRef.set({
    users: [emailUid, otherUid],
    matchedAt: now,
    chatThreadId: threadRef.id,
    matchStatus: 'matched',
  });

  // Legacy per-user Matches mirrors unlock canReadUserProfile for chat.
  await Promise.all([
    db.collection('users').doc(emailUid).collection('Matches').doc(otherUid).set({
      Matches: otherUid,
      userId: otherUid,
      timestamp: now,
    }),
    db.collection('users').doc(otherUid).collection('Matches').doc(emailUid).set({
      Matches: emailUid,
      userId: emailUid,
      timestamp: now,
    }),
  ]);

  console.log('✅ Seeded test chat thread');
  console.log(`   project:     ${projectId}`);
  console.log(`   email user:  ${emailUser ?? emailUid} (${emailUid})`);
  console.log(`   other uid:   ${otherUid} (${otherName})`);
  console.log(`   chatThread:  chatThreads/${threadRef.id}`);
  console.log(`   match:       matches/${matchRef.id}`);
  console.log(`   mirrors:     users/*/Matches/*`);
}

main().catch((err) => {
  console.error('❌ seedTestChatThread failed:', err);
  process.exit(1);
});
