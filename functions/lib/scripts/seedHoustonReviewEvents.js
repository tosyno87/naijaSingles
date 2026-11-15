"use strict";
/**
 * Upsert two published Houston weekend events for Discover home / App Review.
 *
 * Admin-only. The Flutter app never seeds events.
 *
 * Usage:
 *   cd functions
 *   npx ts-node src/scripts/seedHoustonReviewEvents.ts --project naijasingles-staging
 *
 * Production project ids are refused unless --i-am-sure is passed:
 *   npx ts-node src/scripts/seedHoustonReviewEvents.ts \
 *     --project naijasingles-74a75 --i-am-sure
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default login.
 * Idempotent: uses stable document ids and overwrites the same two docs.
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
exports.parseArgs = parseArgs;
exports.assertProjectAllowed = assertProjectAllowed;
const admin = __importStar(require("firebase-admin"));
const PRODUCTION_PROJECT_IDS = new Set([
    'naijasingles-74a75',
    'naijasingles-prod2',
    'afropeep-prod-74a75',
]);
const AFROBEATS_DOC_ID = 'houston-review-weekend-afrobeats';
const BRUNCH_DOC_ID = 'houston-review-weekend-brunch';
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
function assertProjectAllowed(projectId, iAmSure) {
    if (PRODUCTION_PROJECT_IDS.has(projectId) && !iAmSure) {
        throw new Error(`Refusing to seed production project "${projectId}". ` +
            'Pass --i-am-sure if you intend to write Houston review events there.');
    }
}
function nextWeekday(from, weekday) {
    const date = new Date(from);
    date.setHours(19, 0, 0, 0);
    const delta = (weekday + 7 - date.getDay()) % 7;
    date.setDate(date.getDate() + (delta === 0 ? 7 : delta));
    return date;
}
function eventPayload(name, description, start, location) {
    const end = new Date(start.getTime() + 4 * 60 * 60 * 1000);
    const now = admin.firestore.Timestamp.now();
    return {
        name,
        description,
        startDate: admin.firestore.Timestamp.fromDate(start),
        endDate: admin.firestore.Timestamp.fromDate(end),
        imageUrl: null,
        location: {
            name: location.name,
            address: location.address,
            city: location.city,
            state: location.state,
            country: 'United States',
        },
        isFree: true,
        category: 'Culture',
        tags: ['houston', 'review'],
        attendeeCount: 0,
        rsvpCount: 0,
        createdAt: now,
        updatedAt: now,
        status: 'published',
        isPublic: true,
        createdByUserId: 'system_houston_review_seed',
    };
}
async function main() {
    const args = parseArgs(process.argv.slice(2));
    const projectId = args.project;
    if (!projectId) {
        console.error('Usage: npx ts-node src/scripts/seedHoustonReviewEvents.ts ' +
            '--project naijasingles-staging [--i-am-sure]');
        process.exit(1);
    }
    const iAmSure = args['i-am-sure'] === 'true';
    assertProjectAllowed(projectId, iAmSure);
    admin.initializeApp({ projectId });
    const db = admin.firestore();
    const saturday = nextWeekday(new Date(), 6);
    const sunday = nextWeekday(new Date(), 0);
    const afrobeats = eventPayload('Afrobeats & Amapiano', 'Houston diaspora night: Afrobeats and Amapiano in Midtown.', saturday, {
        name: 'Midtown Houston',
        address: 'Midtown, Houston, TX',
        city: 'Houston',
        state: 'TX',
    });
    const brunch = eventPayload('Sunday Brunch & Connect', 'Community brunch for Africans in Houston. New-here friendly.', sunday, {
        name: 'EaDo Houston',
        address: 'East Downtown, Houston, TX',
        city: 'Houston',
        state: 'TX',
    });
    await db.collection('events').doc(AFROBEATS_DOC_ID).set(afrobeats, {
        merge: true,
    });
    await db.collection('events').doc(BRUNCH_DOC_ID).set(brunch, { merge: true });
    console.log('Seeded Houston review events');
    console.log(`  project: ${projectId}`);
    console.log(`  events/${AFROBEATS_DOC_ID}  ${saturday.toISOString()}`);
    console.log(`  events/${BRUNCH_DOC_ID}  ${sunday.toISOString()}`);
}
if (require.main === module) {
    main().catch((err) => {
        console.error('seedHoustonReviewEvents failed:', err);
        process.exit(1);
    });
}
//# sourceMappingURL=seedHoustonReviewEvents.js.map