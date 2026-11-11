"use strict";
/**
 * Upsert public Houston unifiedGroups for Discover "Explore groups" / App Review.
 *
 * Admin-only. The Flutter app never seeds groups.
 *
 * Usage:
 *   cd functions
 *   npx ts-node src/scripts/seedHoustonReviewGroups.ts --project naijasingles-staging
 *
 * Production project ids are refused unless --i-am-sure is passed.
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default login.
 * Idempotent: uses stable document ids.
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
const seedHoustonReviewEvents_1 = require("./seedHoustonReviewEvents");
const CREATOR_ID = 'system_houston_review_seed';
const DIASPORA_DOC_ID = 'houston-review-group-diaspora';
const PROFESSIONALS_DOC_ID = 'houston-review-group-professionals';
function groupPayload(name, description, type, tags) {
    const now = admin.firestore.Timestamp.now();
    return {
        name,
        description,
        type,
        imageUrl: null,
        location: 'Houston, TX',
        tags,
        culturalInfo: { city: 'Houston', region: 'Greater Houston' },
        creatorId: CREATOR_ID,
        adminIds: [CREATOR_ID],
        memberIds: [CREATOR_ID],
        memberCount: 1,
        maxMembers: 200,
        isPublic: true,
        enableChat: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        lastActivityAt: now,
        lastMessageAt: now,
        lastMessageText: `Welcome to ${name}`,
        lastMessageSenderId: CREATOR_ID,
    };
}
async function main() {
    const args = (0, seedHoustonReviewEvents_1.parseArgs)(process.argv.slice(2));
    const projectId = args.project;
    if (!projectId) {
        console.error('Usage: npx ts-node src/scripts/seedHoustonReviewGroups.ts ' +
            '--project naijasingles-staging [--i-am-sure]');
        process.exit(1);
    }
    const iAmSure = args['i-am-sure'] === 'true';
    (0, seedHoustonReviewEvents_1.assertProjectAllowed)(projectId, iAmSure);
    admin.initializeApp({ projectId });
    const db = admin.firestore();
    const diaspora = groupPayload('Houston Diaspora Meetups', 'Public group for Africans in Houston — events, hangouts, and new-here tips.', 'local', ['houston', 'diaspora', 'review']);
    const professionals = groupPayload('Houston African Professionals', 'Career and community networking for diaspora professionals in Greater Houston.', 'networking', ['houston', 'career', 'review']);
    await db
        .collection('unifiedGroups')
        .doc(DIASPORA_DOC_ID)
        .set(diaspora, { merge: true });
    await db
        .collection('unifiedGroups')
        .doc(PROFESSIONALS_DOC_ID)
        .set(professionals, { merge: true });
    console.log('Seeded Houston review groups');
    console.log(`  project: ${projectId}`);
    console.log(`  unifiedGroups/${DIASPORA_DOC_ID}`);
    console.log(`  unifiedGroups/${PROFESSIONALS_DOC_ID}`);
}
if (require.main === module) {
    main().catch((err) => {
        console.error('seedHoustonReviewGroups failed:', err);
        process.exit(1);
    });
}
//# sourceMappingURL=seedHoustonReviewGroups.js.map