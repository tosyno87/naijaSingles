/**
 * Tests callable handlers with mocked firebase-admin and messaging.
 */

import type {CallableRequest} from 'firebase-functions/v2/https';

import {hashOtp} from '../../services/accountDeletionOtpCrypto';

const mockGetUser = jest.fn();
const mockDeleteUser = jest.fn();
const mockVerifyIdToken = jest.fn();
const mockDocGet = jest.fn();
const mockDocSet = jest.fn().mockResolvedValue(undefined);
const mockRunTransaction = jest.fn();

jest.mock('../../services/accountDeletionMessaging', () => ({
  sendDeletionOtpEmail: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('firebase-admin', () => {
  const FieldValue = {
    serverTimestamp: jest.fn(() => 'SERVER_TS'),
    delete: jest.fn(() => 'DELETE_FIELD'),
  };
  const Timestamp = {
    fromMillis: jest.fn((ms: number) => ({toMillis: () => ms})),
  };
  const doc = jest.fn(() => ({
    get: mockDocGet,
    set: mockDocSet,
  }));
  const collection = jest.fn(() => ({doc}));
  const mockDb = {
    collection,
    runTransaction: mockRunTransaction,
  };
  const firestoreFn = Object.assign(jest.fn(() => mockDb), {
    FieldValue,
    Timestamp,
  });
  return {
    auth: jest.fn(() => ({
      getUser: mockGetUser,
      deleteUser: mockDeleteUser,
      verifyIdToken: mockVerifyIdToken,
    })),
    firestore: firestoreFn,
  };
});

import {
  confirmDeletionAfterPhoneProofHandler,
  confirmDeletionOtpHandler,
  deleteAccountDirectHandler,
  extractClientIp,
  startDeletionOtpHandler,
} from '../accountDeletionCallables';

function callableWithRaw(raw: unknown): CallableRequest {
  return {rawRequest: raw} as CallableRequest;
}

const PEPPER = 'unit-test-pepper-16chars';

function makeSnap(
  exists: boolean,
  data: Record<string, unknown> | null
): {exists: boolean; data: () => Record<string, unknown> | undefined} {
  return {
    exists,
    data: () => (data === null ? undefined : data),
  };
}

describe('extractClientIp', () => {
  it('returns null when rawRequest is missing', () => {
    expect(extractClientIp(callableWithRaw(undefined))).toBeNull();
  });

  it('returns first x-forwarded-for address', () => {
    const raw = {
      get: (name: string) =>
        name.toLowerCase() === 'x-forwarded-for'
          ? '203.0.113.9, 10.0.0.1'
          : undefined,
    };
    expect(extractClientIp(callableWithRaw(raw))).toBe('203.0.113.9');
  });

  it('uses req.ip when x-forwarded-for is absent', () => {
    const raw = {
      get: () => undefined,
      ip: '198.51.100.2',
    };
    expect(extractClientIp(callableWithRaw(raw))).toBe('198.51.100.2');
  });

  it('falls back to socket.remoteAddress', () => {
    const raw = {
      get: () => undefined,
      socket: {remoteAddress: '::1'},
    };
    expect(extractClientIp(callableWithRaw(raw))).toBe('::1');
  });
});

describe('accountDeletionCallables handlers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.DELETION_OTP_PEPPER = PEPPER;
    mockDeleteUser.mockResolvedValue(undefined);
    mockDocSet.mockResolvedValue(undefined);
    mockRunTransaction.mockReset();
    mockVerifyIdToken.mockReset();
  });

  describe('startDeletionOtpHandler', () => {
    it('rejects unauthenticated', async () => {
      await expect(
        startDeletionOtpHandler({auth: null, data: {channel: 'email'}})
      ).rejects.toMatchObject({code: 'unauthenticated'});
    });

    it('rejects non-email channel (no backend SMS OTP)', async () => {
      await expect(
        startDeletionOtpHandler({
          auth: {uid: 'u1'},
          data: {channel: 'sms'},
        })
      ).rejects.toMatchObject({code: 'invalid-argument'});
    });

    it('sends email OTP when user has email', async () => {
      mockGetUser.mockResolvedValue({
        uid: 'u1',
        email: 'a@b.com',
        phoneNumber: undefined,
        providerData: [],
      });
      mockDocGet.mockResolvedValue(makeSnap(false, null));

      const out = await startDeletionOtpHandler({
        auth: {uid: 'u1'},
        data: {channel: 'email'},
      });

      expect(out.ok).toBe(true);
      expect(out.channel).toBe('email');
      expect(mockDocSet).toHaveBeenCalled();
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it('runs per-IP limit transaction when rawRequest supplies client IP', async () => {
      mockGetUser.mockResolvedValue({
        uid: 'u1',
        email: 'a@b.com',
        phoneNumber: undefined,
        providerData: [],
      });
      mockRunTransaction.mockImplementation(
        async (fn: (tx: {get: jest.Mock; set: jest.Mock}) => Promise<void>) => {
          const tx = {
            get: jest.fn().mockResolvedValue(makeSnap(false, null)),
            set: jest.fn(),
          };
          await fn(tx);
        }
      );
      mockDocGet.mockResolvedValue(makeSnap(false, null));

      const rawStub = {
        get: (name: string): string | undefined =>
          name.toLowerCase() === 'x-forwarded-for'
            ? '203.0.113.55'
            : undefined,
      } as unknown as CallableRequest['rawRequest'];

      const out = await startDeletionOtpHandler({
        auth: {uid: 'u1'},
        data: {channel: 'email'},
        rawRequest: rawStub,
      });

      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      expect(out.ok).toBe(true);
    });

    it('rejects when per-IP startOtp limit is exceeded (rawRequest IP)', async () => {
      mockGetUser.mockResolvedValue({
        uid: 'u1',
        email: 'a@b.com',
        phoneNumber: undefined,
        providerData: [],
      });
      const windowMs = Date.now();
      mockRunTransaction.mockImplementation(
        async (fn: (tx: {get: jest.Mock; set: jest.Mock}) => Promise<void>) => {
          const tx = {
            get: jest.fn().mockResolvedValue(
              makeSnap(true, {
                startOtpWindowAt: {toMillis: () => windowMs},
                startOtpCount: 40,
              })
            ),
            set: jest.fn(),
          };
          await fn(tx);
        }
      );

      const rawStub = {
        get: (name: string): string | undefined =>
          name.toLowerCase() === 'x-forwarded-for'
            ? '203.0.113.99'
            : undefined,
      } as unknown as CallableRequest['rawRequest'];

      await expect(
        startDeletionOtpHandler({
          auth: {uid: 'u1'},
          data: {channel: 'email'},
          rawRequest: rawStub,
        })
      ).rejects.toMatchObject({
        code: 'resource-exhausted',
        details: {retryAfterSeconds: expect.any(Number)},
      });
      expect(mockDocGet).not.toHaveBeenCalled();
    });

    it('enforces resend cooldown', async () => {
      mockGetUser.mockResolvedValue({
        uid: 'u1',
        email: 'a@b.com',
        providerData: [],
      });
      const recent = {toMillis: () => Date.now()};
      mockDocGet.mockResolvedValue(
        makeSnap(true, {
          lastSentAt: recent,
          lockedUntil: null,
        })
      );

      await expect(
        startDeletionOtpHandler({
          auth: {uid: 'u1'},
          data: {channel: 'email'},
        })
      ).rejects.toMatchObject({
        code: 'resource-exhausted',
        details: {retryAfterSeconds: expect.any(Number)},
      });
    });
  });

  describe('confirmDeletionOtpHandler', () => {
    const uid = 'user-otp';
    const code = '424242';
    let verifyFields: Record<string, unknown>;

    beforeEach(() => {
      const {saltB64, hashB64} = hashOtp(code, PEPPER);
      verifyFields = {
        salt: saltB64,
        codeHash: hashB64,
        expiresAt: {toMillis: () => Date.now() + 120_000},
        attemptCount: 0,
        channel: 'email',
      };
      mockGetUser.mockResolvedValue({
        uid,
        email: 'a@b.com',
        phoneNumber: null,
        providerData: [{providerId: 'password'}],
      });
    });

    it('rejects wrong code and increments attempts', async () => {
      mockDocGet.mockResolvedValue(makeSnap(true, {...verifyFields}));

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code: '000000', reason: 'Testing'},
        })
      ).rejects.toMatchObject({
        code: 'permission-denied',
        details: {attemptsRemaining: 4},
      });

      expect(mockDocSet).toHaveBeenCalledWith(
        expect.objectContaining({attemptCount: 1}),
        {merge: true}
      );
      expect(mockRunTransaction).not.toHaveBeenCalled();
      expect(mockDeleteUser).not.toHaveBeenCalled();
    });

    it('locks out after max wrong codes with retryAfterSeconds', async () => {
      mockDocGet.mockResolvedValue(
        makeSnap(true, {...verifyFields, attemptCount: 4})
      );

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code: '000000', reason: 'Testing'},
        })
      ).rejects.toMatchObject({
        code: 'resource-exhausted',
        details: {
          attemptsRemaining: 0,
          retryAfterSeconds: expect.any(Number),
        },
      });
      expect(mockDeleteUser).not.toHaveBeenCalled();
    });

    it('rejects expired code', async () => {
      mockDocGet.mockResolvedValue(
        makeSnap(true, {
          ...verifyFields,
          expiresAt: {toMillis: () => Date.now() - 1000},
        })
      );

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code, reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
    });

    it('rejects when already consumed', async () => {
      mockDocGet.mockResolvedValue(
        makeSnap(true, {
          ...verifyFields,
          consumedAt: 'x',
        })
      );

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code, reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
    });

    it('calls deleteUser on valid code', async () => {
      mockDocGet.mockResolvedValue(makeSnap(true, {...verifyFields}));
      mockRunTransaction.mockImplementation(
        async (fn: (tx: {get: jest.Mock; set: jest.Mock}) => Promise<void>) => {
          const tx = {
            get: jest.fn().mockResolvedValue(makeSnap(true, {...verifyFields})),
            set: jest.fn(),
          };
          await fn(tx);
        }
      );

      const out = await confirmDeletionOtpHandler({
        auth: {uid},
        data: {code, reason: 'Testing'},
      });

      expect(out.ok).toBe(true);
      expect(mockDeleteUser).toHaveBeenCalledWith(uid);
    });

    it('rejects replay inside transaction when consumed', async () => {
      mockDocGet.mockResolvedValue(makeSnap(true, {...verifyFields}));
      mockRunTransaction.mockImplementation(
        async (fn: (tx: {get: jest.Mock; set: jest.Mock}) => Promise<void>) => {
          const tx = {
            get: jest
              .fn()
              .mockResolvedValue(
                makeSnap(true, {...verifyFields, consumedAt: 'done'})
              ),
            set: jest.fn(),
          };
          await fn(tx);
        }
      );

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code, reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
      expect(mockDeleteUser).not.toHaveBeenCalled();
    });

    it('rejects legacy verification doc with sms channel', async () => {
      mockDocGet.mockResolvedValue(
        makeSnap(true, {
          ...verifyFields,
          channel: 'sms',
        })
      );

      await expect(
        confirmDeletionOtpHandler({
          auth: {uid},
          data: {code, reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
    });
  });

  describe('confirmDeletionAfterPhoneProofHandler', () => {
    const uid = 'phone-user';

    beforeEach(() => {
      mockGetUser.mockResolvedValue({
        uid,
        email: 'p@b.com',
        phoneNumber: '+15551234567',
        providerData: [{providerId: 'phone'}],
      });
    });

    it('rejects missing idToken', async () => {
      await expect(
        confirmDeletionAfterPhoneProofHandler({
          data: {reason: 'x'},
        })
      ).rejects.toMatchObject({code: 'invalid-argument'});
    });

    it('rejects when idToken cannot be verified', async () => {
      mockVerifyIdToken.mockRejectedValue(new Error('invalid jwt'));

      await expect(
        confirmDeletionAfterPhoneProofHandler({
          data: {idToken: 'bad-tok', reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'permission-denied'});
    });

    it('rejects when sign-in was not phone', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid,
        auth_time: Math.floor(Date.now() / 1000),
        firebase: {sign_in_provider: 'google.com'},
      });

      await expect(
        confirmDeletionAfterPhoneProofHandler({
          data: {idToken: 'tok', reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
    });

    it('rejects stale auth_time', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid,
        auth_time: Math.floor(Date.now() / 1000) - 600,
        firebase: {sign_in_provider: 'phone'},
      });

      await expect(
        confirmDeletionAfterPhoneProofHandler({
          data: {idToken: 'tok', reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'failed-precondition'});
    });

    it('calls deleteUser when token is valid phone proof', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid,
        auth_time: Math.floor(Date.now() / 1000),
        firebase: {sign_in_provider: 'phone'},
      });

      const out = await confirmDeletionAfterPhoneProofHandler({
        data: {idToken: 'good-tok', reason: 'Testing'},
      });

      expect(out.ok).toBe(true);
      expect(mockVerifyIdToken).toHaveBeenCalledWith('good-tok', true);
      expect(mockDeleteUser).toHaveBeenCalledWith(uid);
      expect(mockDocSet).toHaveBeenCalled();
    });
  });

  describe('deleteAccountDirectHandler', () => {
    const uid = 'direct-user';

    beforeEach(() => {
      mockGetUser.mockResolvedValue({
        uid,
        email: 'd@b.com',
        phoneNumber: null,
        providerData: [{providerId: 'password'}],
      });
    });

    it('rejects missing idToken', async () => {
      await expect(
        deleteAccountDirectHandler({
          data: {reason: 'x'},
        })
      ).rejects.toMatchObject({code: 'invalid-argument'});
    });

    it('rejects when idToken cannot be verified', async () => {
      mockVerifyIdToken.mockRejectedValue(new Error('invalid jwt'));

      await expect(
        deleteAccountDirectHandler({
          data: {idToken: 'bad-tok', reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'permission-denied'});
    });

    it('rejects uid mismatch between callable auth and idToken', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid,
        auth_time: Math.floor(Date.now() / 1000),
        firebase: {sign_in_provider: 'password'},
      });

      await expect(
        deleteAccountDirectHandler({
          auth: {uid: 'different-user'},
          data: {idToken: 'tok', reason: 'Testing'},
        })
      ).rejects.toMatchObject({code: 'permission-denied'});
    });

    it('calls deleteUser when idToken is valid', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid,
        auth_time: Math.floor(Date.now() / 1000),
        firebase: {sign_in_provider: 'password'},
      });

      const out = await deleteAccountDirectHandler({
        data: {idToken: 'good-tok', reason: 'Testing'},
      });

      expect(out.ok).toBe(true);
      expect(mockVerifyIdToken).toHaveBeenCalledWith('good-tok', true);
      expect(mockDeleteUser).toHaveBeenCalledWith(uid);
      expect(mockDocSet).toHaveBeenCalled();
    });
  });
});
