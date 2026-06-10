import * as fs from 'fs';
import * as path from 'path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'afropeep-storage-rules-test';

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
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../storage.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

describe('storage.rules', () => {
  test('owner can upload verification image', async () => {
    const storage = testEnv
      .authenticatedContext('owner-user')
      .storage()
      .ref('verification/owner-user/selfie.jpg');

    await assertSucceeds(
      storage.put(new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }) as unknown as Promise<void>,
    );
  });

  test('non-owner cannot read verification image', async () => {
    const ownerStorage = testEnv
      .authenticatedContext('owner-user')
      .storage()
      .ref('verification/owner-user/selfie.jpg');
    await ownerStorage.put(new Uint8Array([1, 2, 3]), {
      contentType: 'image/jpeg',
    });

    const intruderStorage = testEnv
      .authenticatedContext('other-user')
      .storage()
      .ref('verification/owner-user/selfie.jpg');

    await assertFails(intruderStorage.getMetadata());
  });

  test('unauthenticated users cannot read profile photos', async () => {
    const ownerStorage = testEnv
      .authenticatedContext('owner-user')
      .storage()
      .ref('users/owner-user/profile.jpg');
    await ownerStorage.put(new Uint8Array([1, 2, 3]), {
      contentType: 'image/jpeg',
    });

    const guestStorage = testEnv.unauthenticatedContext().storage().ref(
      'users/owner-user/profile.jpg',
    );

    await assertFails(guestStorage.getMetadata());
  });

  test('unknown storage path is denied', async () => {
    const storage = testEnv
      .authenticatedContext('any-user')
      .storage()
      .ref('secret/path/file.jpg');

    await assertFails(
      storage.put(new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }) as unknown as Promise<void>,
    );
  });
});
