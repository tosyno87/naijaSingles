import * as fs from 'fs';
import * as path from 'path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'afropeep-rules-test';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('firestore.rules', () => {
  test('premium user can update profile without changing entitlement fields', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('premium-user').set({
        name: 'Premium User',
        dateOfBirth: '1990-01-01',
        isPremium: true,
        subscriptionDate: '2026-01-01',
        onboardingCompleted: true,
        isDiscoverable: true,
        isProfilePrivate: false,
        isDeleted: false,
        accountStatus: 'active',
      });
    });

    const db = testEnv.authenticatedContext('premium-user').firestore();
    await assertSucceeds(
      db.collection('users').doc('premium-user').update({
        bio: 'Updated bio',
      }),
    );
  });

  test('premium user cannot self-grant premium entitlement', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('free-user').set({
        name: 'Free User',
        dateOfBirth: '1995-05-05',
        isPremium: false,
        onboardingCompleted: true,
        isDiscoverable: true,
        isProfilePrivate: false,
        isDeleted: false,
        accountStatus: 'active',
      });
    });

    const db = testEnv.authenticatedContext('free-user').firestore();
    await assertFails(
      db.collection('users').doc('free-user').update({
        isPremium: true,
        subscriptionDate: '2026-06-01',
      }),
    );
  });

  test('legacy root verification field does not block profile reads', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('verified-user').set({
        name: 'Verified User',
        verification: {status: 'approved'},
        isDiscoverable: true,
        isProfilePrivate: false,
        isDeleted: false,
        accountStatus: 'active',
      });
    });

    const db = testEnv.authenticatedContext('other-user').firestore();
    await assertSucceeds(db.collection('users').doc('verified-user').get());
  });

  test('owner can write verification subcollection metadata', async () => {
    const db = testEnv.authenticatedContext('owner-user').firestore();
    await assertSucceeds(
      db
        .collection('users')
        .doc('owner-user')
        .collection('verification')
        .doc('current')
        .set({
          status: 'pending',
          imageUrl: 'https://example.com/verification.jpg',
        }),
    );
  });

  test('non-owner cannot read verification subcollection metadata', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection('users')
        .doc('owner-user')
        .collection('verification')
        .doc('current')
        .set({status: 'pending'});
    });

    const db = testEnv.authenticatedContext('other-user').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('owner-user')
        .collection('verification')
        .doc('current')
        .get(),
    );
  });

  test('call create validates request.resource participantIds', async () => {
    const db = testEnv.authenticatedContext('caller-a').firestore();
    await assertSucceeds(
      db.collection('calls').doc('call-1').set({
        participantIds: ['caller-a', 'caller-b'],
        status: 'ringing',
      }),
    );
  });

  test('call create fails when caller is not in participantIds', async () => {
    const db = testEnv.authenticatedContext('caller-a').firestore();
    await assertFails(
      db.collection('calls').doc('call-2').set({
        participantIds: ['caller-b', 'caller-c'],
        status: 'ringing',
      }),
    );
  });

  test('non-participant cannot read call session', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('calls').doc('call-3').set({
        participantIds: ['caller-a', 'caller-b'],
        status: 'active',
      });
    });

    const db = testEnv.authenticatedContext('intruder').firestore();
    await assertFails(db.collection('calls').doc('call-3').get());
  });

  test('unknown top-level collection is denied', async () => {
    const db = testEnv.authenticatedContext('any-user').firestore();
    await assertFails(
      db.collection('secretCollection').doc('doc-1').set({value: 1}),
    );
  });
});
