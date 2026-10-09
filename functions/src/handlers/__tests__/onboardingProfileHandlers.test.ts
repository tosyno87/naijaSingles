import type {CallableRequest} from 'firebase-functions/v2/https';
import {HttpsError} from 'firebase-functions/v2/https';

const mockDocGet = jest.fn();
const mockDocSet = jest.fn().mockResolvedValue(undefined);
const mockRunTransaction = jest.fn();

jest.mock('firebase-admin', () => {
  const FieldValue = {
    serverTimestamp: jest.fn(() => 'SERVER_TS'),
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
  });
  return {firestore: firestoreFn};
});

import {extractOnboardingProfileHandler} from '../onboardingProfileHandlers';
import {
  ExtractionValidationError,
  REVIEW_FIXTURE,
} from '../../services/onboardingProfileExtraction';

function request(uid: string | null, answers: unknown): CallableRequest<{
  answers?: unknown;
}> {
  return {
    auth: uid ? {uid} : undefined,
    data: {answers},
  } as CallableRequest<{answers?: unknown}>;
}

describe('extractOnboardingProfileHandler', () => {
  const extractionGet = jest.fn();
  const extractionSet = jest.fn().mockResolvedValue(undefined);
  const budgetGet = jest.fn();
  const budgetSet = jest.fn();

  const extractionRef = {get: extractionGet, set: extractionSet};
  const budgetRef = {get: budgetGet, set: budgetSet};

  const db = {
    collection: jest.fn(),
    runTransaction: mockRunTransaction,
  } as unknown as FirebaseFirestore.Firestore;

  beforeEach(() => {
    jest.clearAllMocks();
    (db.collection as jest.Mock).mockImplementation((name: string) => {
      if (name === 'onboardingExtractions') {
        return {doc: () => extractionRef};
      }
      return {doc: () => budgetRef};
    });
    extractionGet.mockResolvedValue({data: () => undefined});
    budgetGet.mockResolvedValue({data: () => undefined});
    mockRunTransaction.mockImplementation(
      async (fn: (tx: FirebaseFirestore.Transaction) => Promise<void>) => {
        const tx = {
          get: async (ref: {get: jest.Mock}) => {
            if (ref === extractionRef) {
              return extractionGet();
            }
            return budgetGet();
          },
          set: (
            ref: {set: jest.Mock},
            data: Record<string, unknown>,
            options?: {merge?: boolean}
          ) => {
            if (ref === extractionRef) {
              return extractionSet(data, options);
            }
            return budgetSet(data, options);
          },
        } as unknown as FirebaseFirestore.Transaction;
        await fn(tx);
      }
    );
  });

  it('requires auth', async () => {
    await expect(
      extractOnboardingProfileHandler(
        request(null, [{promptId: 'who', text: 'hi'}]),
        {db, now: () => new Date('2026-09-03T00:00:00.000Z')}
      )
    ).rejects.toMatchObject({code: 'unauthenticated'});
  });

  it('returns the App Review fixture without calling OpenAI', async () => {
    const openai = {
      transcribe: jest.fn(),
      extract: jest.fn(),
    };
    const result = await extractOnboardingProfileHandler(
      request('review-uid', [{promptId: 'who', text: 'hi from Houston'}]),
      {
        db,
        now: () => new Date('2026-09-03T00:00:00.000Z'),
        openai,
        reviewUids: 'review-uid',
      }
    );
    expect(result.source).toBe('review_fixture');
    expect(result.fields.fullName).toBe(REVIEW_FIXTURE.fields.fullName);
    expect(openai.extract).not.toHaveBeenCalled();
    expect(mockRunTransaction).not.toHaveBeenCalled();
  });

  it('enforces the 24h rate limit on last attempt', async () => {
    extractionGet.mockResolvedValue({
      data: () => ({lastAttemptAtMs: Date.parse('2026-09-03T10:00:00.000Z')}),
    });
    const openai = {
      transcribe: jest.fn(),
      extract: jest.fn(),
    };
    await expect(
      extractOnboardingProfileHandler(
        request('u1', [{promptId: 'who', text: 'Ada in Houston'}]),
        {
          db,
          now: () => new Date('2026-09-03T12:00:00.000Z'),
          openai,
        }
      )
    ).rejects.toBeInstanceOf(HttpsError);
    expect(openai.extract).not.toHaveBeenCalled();
  });

  it('extracts typed answers and records the rate-limit stamp', async () => {
    const openai = {
      transcribe: jest.fn(),
      extract: jest.fn().mockResolvedValue({
        source: 'model',
        fields: {fullName: 'Ada', gender: 'Female', bio: 'Houston community'},
        confidence: {fullName: 0.9, gender: 0.9, bio: 0.9},
      }),
    };
    const result = await extractOnboardingProfileHandler(
      request('u1', [{promptId: 'who', text: 'I am Ada, a woman in Houston'}]),
      {
        db,
        now: () => new Date('2026-09-03T00:00:00.000Z'),
        openai,
        dailyCapCents: 1500,
      }
    );
    expect(result.fields.fullName).toBe('Ada');
    expect(result.fields.gender).toBe('Female');
    expect(extractionSet).toHaveBeenCalled();
    expect(openai.transcribe).not.toHaveBeenCalled();
  });

  it('fails closed when OpenAI is not configured without consuming budget', async () => {
    await expect(
      extractOnboardingProfileHandler(
        request('u1', [{promptId: 'who', text: 'Ada'}]),
        {db, now: () => new Date('2026-09-03T00:00:00.000Z')}
      )
    ).rejects.toMatchObject({code: 'failed-precondition'});
    expect(mockRunTransaction).not.toHaveBeenCalled();
  });

  it('stamps the cooldown and budget when OpenAI fails so retries cannot drain spend', async () => {
    const openai = {
      transcribe: jest.fn(),
      extract: jest.fn().mockRejectedValue(
        new ExtractionValidationError('failed-precondition', 'ai_unavailable')
      ),
    };
    const now = new Date('2026-09-03T00:00:00.000Z');
    await expect(
      extractOnboardingProfileHandler(
        request('u1', [{promptId: 'who', text: 'Ada in Houston'}]),
        {db, now: () => now, openai, dailyCapCents: 1500}
      )
    ).rejects.toMatchObject({code: 'failed-precondition'});

    expect(extractionSet).toHaveBeenCalledWith(
      expect.objectContaining({lastAttemptAtMs: now.getTime()}),
      {merge: true}
    );
    expect(budgetSet).toHaveBeenCalled();
    expect(openai.extract).toHaveBeenCalledTimes(1);

    extractionGet.mockResolvedValue({
      data: () => ({lastAttemptAtMs: now.getTime()}),
    });
    openai.extract.mockClear();
    await expect(
      extractOnboardingProfileHandler(
        request('u1', [{promptId: 'who', text: 'Ada in Houston'}]),
        {
          db,
          now: () => new Date('2026-09-03T01:00:00.000Z'),
          openai,
          dailyCapCents: 1500,
        }
      )
    ).rejects.toMatchObject({code: 'resource-exhausted'});
    expect(openai.extract).not.toHaveBeenCalled();
  });
});
