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

import * as admin from 'firebase-admin';

import {
  assertProjectAllowed,
  parseArgs,
} from './seedHoustonReviewEvents';

const CREATOR_ID = 'system_houston_review_seed';
const DIASPORA_DOC_ID = 'houston-review-group-diaspora';
const PROFESSIONALS_DOC_ID = 'houston-review-group-professionals';

function groupPayload(
  name: string,
  description: string,
  type: string,
  tags: string[],
): Record<string, unknown> {
  const now = admin.firestore.Timestamp.now();
  return {
    name,
    description,
    type,
    imageUrl: null,
    location: 'Houston, TX',
    tags,
    culturalInfo: {city: 'Houston', region: 'Greater Houston'},
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

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const projectId = args.project;
  if (!projectId) {
    console.error(
      'Usage: npx ts-node src/scripts/seedHoustonReviewGroups.ts ' +
        '--project naijasingles-staging [--i-am-sure]',
    );
    process.exit(1);
  }

  const iAmSure = args['i-am-sure'] === 'true';
  assertProjectAllowed(projectId, iAmSure);

  admin.initializeApp({projectId});
  const db = admin.firestore();

  const diaspora = groupPayload(
    'Houston Diaspora Meetups',
    'Public group for Africans in Houston — events, hangouts, and new-here tips.',
    'local',
    ['houston', 'diaspora', 'review'],
  );
  const professionals = groupPayload(
    'Houston African Professionals',
    'Career and community networking for diaspora professionals in Greater Houston.',
    'networking',
    ['houston', 'career', 'review'],
  );

  await db
    .collection('unifiedGroups')
    .doc(DIASPORA_DOC_ID)
    .set(diaspora, {merge: true});
  await db
    .collection('unifiedGroups')
    .doc(PROFESSIONALS_DOC_ID)
    .set(professionals, {merge: true});

  console.log('Seeded Houston review groups');
  console.log(`  project: ${projectId}`);
  console.log(`  unifiedGroups/${DIASPORA_DOC_ID}`);
  console.log(`  unifiedGroups/${PROFESSIONALS_DOC_ID}`);
}

if (require.main === module) {
  main().catch((err: unknown) => {
    console.error('seedHoustonReviewGroups failed:', err);
    process.exit(1);
  });
}
