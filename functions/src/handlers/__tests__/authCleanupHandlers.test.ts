/**
 * Unit tests for onAuthUserDeleted cleanup.
 * Verifies correct collection names, where() field names (reporterId vs userId),
 * audit write (accountDeletions doc with status completed), and batch deletes when data exists.
 */

interface WhereCall {
  collection: string;
  field: string;
  op: string;
  value: string;
}

interface SetCall {
  docId: string;
  data: Record<string, unknown>;
  options?: { merge?: boolean };
}

const collectionCalls: string[] = [];
const whereCalls: WhereCall[] = [];
const accountDeletionsSetCalls: SetCall[] = [];
const batchDeleteCalls: unknown[][] = [];
let batchCommitCount = 0;
const userDocDeleteCalls: string[] = [];
const docRefDeleteCalls: string[] = []; // for chat/thread doc.ref.delete()

// Optional: per-collection snapshot override. If set, where(collection).get() returns this.
let snapshotOverride: { empty: false; docs: Array<{ id: string; ref: { delete: () => Promise<void>; collection: (name: string) => unknown } }> } | null = null;
let snapshotOverrideCollection: string | null = null;

/**
 * Creates a mock doc ref (e.g. for a thread or chat). Optionally the 'messages'
 * subcollection can return a non-empty snapshot so deleteSubcollection batches and deletes message docs.
 */
function createMockDocRef(
  docId: string,
  opts?: { messageDocCount?: number }
) {
  const messageDocCount = opts?.messageDocCount ?? 0;
  const messageRefs = Array.from({ length: messageDocCount }, (_, i) => ({
    id: `msg-${docId}-${i}`,
  }));
  const messagesSnapshot =
    messageDocCount > 0
      ? {
          empty: false as const,
          docs: messageRefs.map((r) => ({ id: r.id, ref: r })),
        }
      : { empty: true as const, docs: [] as Array<{ id: string; ref: unknown }> };

  const ref = {
    id: docId,
    delete: jest.fn().mockResolvedValue(undefined),
    collection: jest.fn((subName: string) => {
      if (subName === 'messages') {
        return {
          orderBy: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(messagesSnapshot),
              startAfter: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
              }),
            }),
          }),
        };
      }
      return {};
    }),
  };
  (ref.delete as jest.Mock).mockImplementation(() => {
    docRefDeleteCalls.push(docId);
    return Promise.resolve();
  });
  return ref;
}

const emptySnapshot = { empty: true as const, docs: [] };

function mockFirestore() {
  const db = {
    collection: jest.fn((name: string) => {
      collectionCalls.push(name);
      const col = name;
      return {
        doc: jest.fn((id?: string) => {
          if (col === 'accountDeletions' && id) {
            return {
              set: jest.fn((data: Record<string, unknown>, options?: { merge?: boolean }) => {
                accountDeletionsSetCalls.push({ docId: id, data, options });
                return Promise.resolve();
              }),
            };
          }
          if (col === 'users' && id) {
            const userRef = {
              delete: jest.fn().mockImplementation(() => {
                userDocDeleteCalls.push(id);
                return Promise.resolve();
              }),
              collection: jest.fn((subName: string) => ({
                orderBy: jest.fn().mockReturnValue({
                  limit: jest.fn().mockReturnValue({
                    get: jest.fn().mockResolvedValue(emptySnapshot),
                    startAfter: jest.fn().mockReturnValue({
                      get: jest.fn().mockResolvedValue(emptySnapshot),
                    }),
                  }),
                }),
              })),
            };
            return userRef;
          }
          return {
            set: jest.fn().mockResolvedValue(undefined),
            delete: jest.fn().mockResolvedValue(undefined),
            collection: jest.fn(() => ({
              orderBy: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(emptySnapshot),
                  startAfter: jest.fn().mockReturnValue({
                    get: jest.fn().mockResolvedValue(emptySnapshot),
                  }),
                }),
              }),
            })),
          };
        }),
        where: jest.fn((field: string, op: string, value: string) => {
          whereCalls.push({ collection: col, field, op, value });
          const snapshot =
            snapshotOverrideCollection === col && snapshotOverride
              ? snapshotOverride
              : emptySnapshot;
          return {
            get: jest.fn().mockResolvedValue(snapshot),
          };
        }),
        orderBy: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
            startAfter: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(emptySnapshot),
            }),
          }),
        }),
      };
    }),
    batch: jest.fn(() => {
      const batch = {
        delete: jest.fn((ref: unknown) => {
          batchDeleteCalls.push([ref]);
        }),
        set: jest.fn(),
        commit: jest.fn().mockImplementation(() => {
          batchCommitCount += 1;
          return Promise.resolve();
        }),
      };
      return batch;
    }),
  };
  return db;
}

const firestoreInstance = mockFirestore();
const firestoreFn = Object.assign(() => firestoreInstance, {
  FieldValue: {
    serverTimestamp: jest.fn(() => ({ _serverTimestamp: true })),
  },
  FieldPath: {
    documentId: jest.fn(() => ({ _documentId: true })),
  },
});

const mockStorage = () => ({
  bucket: jest.fn(() => ({
    getFiles: jest.fn().mockResolvedValue([[]]),
  })),
});

jest.mock('firebase-admin', () => ({
  firestore: firestoreFn,
  storage: jest.fn(mockStorage),
  initializeApp: jest.fn(),
}));

jest.mock('firebase-functions/v1', () => ({
  auth: {
    user: () => ({
      onDelete: (handler: (u: { uid: string }) => Promise<void>) => handler,
    }),
  },
}));

import { runAuthUserDeletedCleanup } from '../authCleanupHandlers';

function resetSpies() {
  collectionCalls.length = 0;
  whereCalls.length = 0;
  accountDeletionsSetCalls.length = 0;
  batchDeleteCalls.length = 0;
  batchCommitCount = 0;
  userDocDeleteCalls.length = 0;
  docRefDeleteCalls.length = 0;
  snapshotOverride = null;
  snapshotOverrideCollection = null;
}

describe('runAuthUserDeletedCleanup', () => {
  const uid = 'user-123';

  beforeEach(() => {
    resetSpies();
  });

  describe('collection and where() field names', () => {
    it('queries group_reports and security_logs with reporterId', async () => {
      await runAuthUserDeletedCleanup({ uid });

      const groupReports = whereCalls.filter((w) => w.collection === 'group_reports');
      const securityLogs = whereCalls.filter((w) => w.collection === 'security_logs');
      expect(groupReports.length).toBeGreaterThanOrEqual(1);
      expect(groupReports.every((w) => w.field === 'reporterId' && w.value === uid)).toBe(true);
      expect(securityLogs.length).toBeGreaterThanOrEqual(1);
      expect(securityLogs.every((w) => w.field === 'reporterId' && w.value === uid)).toBe(true);
    });

    it('queries reports with reporterId', async () => {
      await runAuthUserDeletedCleanup({ uid });

      const reports = whereCalls.filter((w) => w.collection === 'reports');
      expect(reports.length).toBeGreaterThanOrEqual(1);
      expect(reports.every((w) => w.field === 'reporterId' && w.value === uid)).toBe(true);
    });

    it('queries swipeHistory, undoUsage, notifications, diaryEntries, feedback with userId', async () => {
      await runAuthUserDeletedCleanup({ uid });

      const userIdCollections = [
        'swipeHistory',
        'undoUsage',
        'superLikeUsage',
        'notifications',
        'notificationLogs',
        'diaryEntries',
        'feedback',
      ];
      for (const col of userIdCollections) {
        const calls = whereCalls.filter((w) => w.collection === col);
        expect(calls.length).toBeGreaterThanOrEqual(1);
        expect(calls.every((w) => w.field === 'userId' && w.value === uid)).toBe(true);
      }
    });

    it('queries chatThreads with userIds array-contains and chats with users array-contains', async () => {
      await runAuthUserDeletedCleanup({ uid });

      const chatThreads = whereCalls.filter((w) => w.collection === 'chatThreads');
      const chats = whereCalls.filter((w) => w.collection === 'chats');
      expect(chatThreads.length).toBeGreaterThanOrEqual(1);
      expect(chatThreads.every((w) => w.field === 'userIds' && w.op === 'array-contains')).toBe(
        true
      );
      expect(chats.length).toBeGreaterThanOrEqual(1);
      expect(chats.every((w) => w.field === 'users' && w.op === 'array-contains')).toBe(true);
    });
  });

  describe('audit write (accountDeletions)', () => {
    it('writes accountDeletions doc with status completed and merge true', async () => {
      await runAuthUserDeletedCleanup({ uid });

      expect(accountDeletionsSetCalls.length).toBe(1);
      const [call] = accountDeletionsSetCalls;
      expect(call.docId).toBe(uid);
      expect(call.data.status).toBe('completed');
      expect(call.data).toHaveProperty('deletedAt');
      expect(call.options).toEqual({ merge: true });
    });
  });

  describe('user doc and batch behavior', () => {
    it('deletes the user doc (users/{uid})', async () => {
      await runAuthUserDeletedCleanup({ uid });

      expect(userDocDeleteCalls).toContain(uid);
    });

    it('when a root collection has docs, batch delete and commit are used', async () => {
      snapshotOverride = {
        empty: false,
        docs: [{ id: 'gr1', ref: createMockDocRef('gr1') }],
      };
      snapshotOverrideCollection = 'group_reports';

      await runAuthUserDeletedCleanup({ uid });

      expect(batchDeleteCalls.length).toBeGreaterThanOrEqual(1);
      expect(batchCommitCount).toBeGreaterThanOrEqual(1);
    });
  });

  describe('chat/thread cleanup', () => {
    it('when chatThreads has a thread with messages, batch-deletes message docs then deletes thread doc', async () => {
      const messageCount = 2;
      const threadRef = createMockDocRef('thread-1', { messageDocCount: messageCount });
      snapshotOverride = {
        empty: false,
        docs: [{ id: 'thread-1', ref: threadRef }],
      };
      snapshotOverrideCollection = 'chatThreads';

      await runAuthUserDeletedCleanup({ uid });

      expect(threadRef.collection).toHaveBeenCalledWith('messages');
      expect(batchDeleteCalls.length).toBeGreaterThanOrEqual(messageCount);
      expect(batchCommitCount).toBeGreaterThanOrEqual(1);
      expect(threadRef.delete).toHaveBeenCalled();
      expect(docRefDeleteCalls).toContain('thread-1');
    });

    it('when chats has a chat with messages, batch-deletes message docs then deletes chat doc', async () => {
      const messageCount = 1;
      const chatRef = createMockDocRef('chat-1', { messageDocCount: messageCount });
      snapshotOverride = {
        empty: false,
        docs: [{ id: 'chat-1', ref: chatRef }],
      };
      snapshotOverrideCollection = 'chats';

      await runAuthUserDeletedCleanup({ uid });

      expect(chatRef.collection).toHaveBeenCalledWith('messages');
      expect(batchDeleteCalls.length).toBeGreaterThanOrEqual(messageCount);
      expect(batchCommitCount).toBeGreaterThanOrEqual(1);
      expect(chatRef.delete).toHaveBeenCalled();
      expect(docRefDeleteCalls).toContain('chat-1');
    });
  });

  describe('coverage of all cleanup surfaces', () => {
    it('touches users, likes, matches, superLikes, chatThreads, chats, accountDeletions', async () => {
      await runAuthUserDeletedCleanup({ uid });

      expect(collectionCalls).toContain('users');
      expect(collectionCalls).toContain('likes');
      expect(collectionCalls).toContain('matches');
      expect(collectionCalls).toContain('superLikes');
      expect(collectionCalls).toContain('chatThreads');
      expect(collectionCalls).toContain('chats');
      expect(collectionCalls).toContain('accountDeletions');
    });

    it('touches group_reports, security_logs, reports, feedback, diaryEntries', async () => {
      await runAuthUserDeletedCleanup({ uid });

      expect(collectionCalls).toContain('group_reports');
      expect(collectionCalls).toContain('security_logs');
      expect(collectionCalls).toContain('reports');
      expect(collectionCalls).toContain('feedback');
      expect(collectionCalls).toContain('diaryEntries');
    });
  });
});
