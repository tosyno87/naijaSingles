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

import * as admin from 'firebase-admin';

const PRODUCTION_PROJECT_IDS = new Set<string>([
  'naijasingles-74a75',
  'naijasingles-prod2',
  'afropeep-prod-74a75',
]);

const AFROBEATS_DOC_ID = 'houston-review-weekend-afrobeats';
const BRUNCH_DOC_ID = 'houston-review-weekend-brunch';

export function parseArgs(argv: string[]): Record<string, string> {
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

export function assertProjectAllowed(
  projectId: string,
  iAmSure: boolean,
): void {
  if (PRODUCTION_PROJECT_IDS.has(projectId) && !iAmSure) {
    throw new Error(
      `Refusing to seed production project "${projectId}". ` +
        'Pass --i-am-sure if you intend to write Houston review events there.',
    );
  }
}

function nextWeekday(from: Date, weekday: number): Date {
  const date = new Date(from);
  date.setHours(19, 0, 0, 0);
  const delta = (weekday + 7 - date.getDay()) % 7;
  date.setDate(date.getDate() + (delta === 0 ? 7 : delta));
  return date;
}

function eventPayload(
  name: string,
  description: string,
  start: Date,
  location: {name: string; address: string; city: string; state: string},
): Record<string, unknown> {
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

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const projectId = args.project;
  if (!projectId) {
    console.error(
      'Usage: npx ts-node src/scripts/seedHoustonReviewEvents.ts ' +
        '--project naijasingles-staging [--i-am-sure]',
    );
    process.exit(1);
  }

  const iAmSure = args['i-am-sure'] === 'true';
  assertProjectAllowed(projectId, iAmSure);

  admin.initializeApp({projectId});
  const db = admin.firestore();

  const saturday = nextWeekday(new Date(), 6);
  const sunday = nextWeekday(new Date(), 0);

  const afrobeats = eventPayload(
    'Afrobeats & Amapiano',
    'Houston diaspora night: Afrobeats and Amapiano in Midtown.',
    saturday,
    {
      name: 'Midtown Houston',
      address: 'Midtown, Houston, TX',
      city: 'Houston',
      state: 'TX',
    },
  );
  const brunch = eventPayload(
    'Sunday Brunch & Connect',
    'Community brunch for Africans in Houston. New-here friendly.',
    sunday,
    {
      name: 'EaDo Houston',
      address: 'East Downtown, Houston, TX',
      city: 'Houston',
      state: 'TX',
    },
  );

  await db.collection('events').doc(AFROBEATS_DOC_ID).set(afrobeats, {
    merge: true,
  });
  await db.collection('events').doc(BRUNCH_DOC_ID).set(brunch, {merge: true});

  console.log('Seeded Houston review events');
  console.log(`  project: ${projectId}`);
  console.log(`  events/${AFROBEATS_DOC_ID}  ${saturday.toISOString()}`);
  console.log(`  events/${BRUNCH_DOC_ID}  ${sunday.toISOString()}`);
}

if (require.main === module) {
  main().catch((err: unknown) => {
    console.error('seedHoustonReviewEvents failed:', err);
    process.exit(1);
  });
}
