"use strict";
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
function parseArgs(argv) {
    const out = {};
    for (let i = 0; i < argv.length; i++) {
        const arg = argv[i];
        if (arg.startsWith('--')) {
            const key = arg.slice(2);
            const next = argv[i + 1];
            if (next && !next.startsWith('--')) {
                out[key] = next;
                i++;
            }
            else {
                out[key] = 'true';
            }
        }
    }
    return out;
}
async function main() {
    const args = parseArgs(process.argv.slice(2));
    const projectId = args.project ?? 'naijasingles-74a75';
    const emailUser = args['email-user'];
    const otherUid = args['other-uid'];
    const emailUidArg = args['email-uid'];
    if ((!emailUser && !emailUidArg) || !otherUid) {
        console.error('Usage: npx ts-node src/scripts/seedTestChatThread.ts ' +
            '--project naijasingles-74a75 ' +
            '(--email-user EMAIL | --email-uid UID) --other-uid UID');
        process.exit(1);
    }
    admin.initializeApp({ projectId });
    const auth = admin.auth();
    const db = admin.firestore();
    const emailUid = emailUidArg
        ? emailUidArg
        : (await auth.getUserByEmail(emailUser)).uid;
    if (emailUid === otherUid) {
        throw new Error('email-user and other-uid must be different accounts');
    }
    const [emailDoc, otherDoc] = await Promise.all([
        db.collection('users').doc(emailUid).get(),
        db.collection('users').doc(otherUid).get(),
    ]);
    const emailName = emailDoc.data()?.name?.trim() ||
        (emailUser ? emailUser.split('@')[0] : undefined);
    const otherName = otherDoc.data()?.name?.trim();
    if (!emailName) {
        throw new Error(`users/${emailUid} has no name — set a profile name before seeding`);
    }
    if (!otherName) {
        throw new Error(`users/${otherUid} has no name — set a profile name before seeding ` +
            `(do not use a placeholder like "Phone User")`);
    }
    const firstPhoto = (data) => {
        if (!data)
            return undefined;
        for (const key of ['photos', 'Pictures']) {
            const list = data[key];
            if (Array.isArray(list) && list.length > 0 && typeof list[0] === 'string') {
                return list[0];
            }
        }
        return undefined;
    };
    const emailAvatar = firstPhoto(emailDoc.data());
    const otherAvatar = firstPhoto(otherDoc.data());
    const userAvatars = {};
    if (emailAvatar)
        userAvatars[emailUid] = emailAvatar;
    if (otherAvatar)
        userAvatars[otherUid] = otherAvatar;
    const threadRef = db.collection('chatThreads').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    await threadRef.set({
        userIds: [emailUid, otherUid],
        userNames: {
            [emailUid]: emailName,
            [otherUid]: otherName,
        },
        ...(Object.keys(userAvatars).length > 0 ? { userAvatars } : {}),
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
//# sourceMappingURL=seedTestChatThread.js.map