/**
 * Auth user-deletion cleanup (1st gen trigger).
 * When a Firebase Auth user is deleted, removes their Firestore data and Storage files.
 * Uses v1 because Auth onDelete is not available in v2.
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

const USER_SUBCOLLECTIONS = [
  'CheckedUser',
  'LikedBy',
  'Matches',
  'notifications',
] as const;

/**
 * Deletes all documents in a subcollection. Uses batched writes (500 per batch).
 */
async function deleteSubcollection(
  db: admin.firestore.Firestore,
  userRef: admin.firestore.DocumentReference,
  subcollectionName: string
): Promise<void> {
  const colRef = userRef.collection(subcollectionName);
  let lastDoc: admin.firestore.DocumentSnapshot | undefined;
  let totalDeleted = 0;
  const batchSize = 500;

  // eslint-disable-next-line no-constant-condition
  while (true) {
    let query: admin.firestore.Query = colRef
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snapshot = await query.get();
    if (snapshot.empty) break;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snapshot.docs.length;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.docs.length < batchSize) break;
  }

  if (totalDeleted > 0) {
    console.log(`Deleted ${totalDeleted} docs from users/${userRef.id}/${subcollectionName}`);
  }
}

/**
 * Deletes root-level likes where the user is sender or recipient.
 * Like doc id format: ${fromUserId}_likes_${toUserId}; fields: from, to.
 */
async function deleteUserLikes(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const likesRef = db.collection('likes');
  const asFrom = await likesRef.where('from', '==', uid).get();
  const asTo = await likesRef.where('to', '==', uid).get();
  const toDelete = new Set<string>();
  asFrom.docs.forEach((d) => toDelete.add(d.id));
  asTo.docs.forEach((d) => toDelete.add(d.id));
  const batchSize = 500;
  const ids = Array.from(toDelete);
  for (let i = 0; i < ids.length; i += batchSize) {
    const batch = db.batch();
    ids.slice(i, i + batchSize).forEach((id) => batch.delete(likesRef.doc(id)));
    await batch.commit();
  }
  if (toDelete.size > 0) {
    console.log(`Deleted ${toDelete.size} like docs for user ${uid}`);
  }
}

/**
 * Deletes root-level matches where the user is in the users array.
 */
async function deleteUserMatches(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const matchesRef = db.collection('matches');
  const snapshot = await matchesRef.where('users', 'array-contains', uid).get();
  const batchSize = 500;
  for (let i = 0; i < snapshot.docs.length; i += batchSize) {
    const batch = db.batch();
    snapshot.docs
      .slice(i, i + batchSize)
      .forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  if (!snapshot.empty) {
    console.log(`Deleted ${snapshot.docs.length} match docs for user ${uid}`);
  }
}

/**
 * Deletes all files under Storage path users/{uid}/.
 */
async function deleteUserStorage(uid: string): Promise<void> {
  try {
    const storage = admin.storage();
    const bucket = storage.bucket();
    const prefix = `users/${uid}/`;
    const [files] = await bucket.getFiles({ prefix });
    await Promise.all(files.map((file) => file.delete()));
    if (files.length > 0) {
      console.log(`Deleted ${files.length} storage files for user ${uid}`);
    }
  } catch (err) {
    console.warn(`Storage cleanup for ${uid} (non-fatal):`, err);
  }
}

/**
 * Deletes chat threads (and their messages subcollections) where the user participated.
 * chatThreads docs have userIds array.
 */
async function deleteUserChatThreads(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const threadsRef = db.collection('chatThreads');
  const snapshot = await threadsRef.where('userIds', 'array-contains', uid).get();
  for (const doc of snapshot.docs) {
    await deleteSubcollection(db, doc.ref, 'messages');
    await doc.ref.delete();
  }
  if (!snapshot.empty) {
    console.log(`Deleted ${snapshot.docs.length} chat threads for user ${uid}`);
  }
}

/**
 * Deletes legacy chats (and their messages subcollections) where the user participated.
 * chats docs have users array.
 */
async function deleteUserLegacyChats(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const chatsRef = db.collection('chats');
  const snapshot = await chatsRef.where('users', 'array-contains', uid).get();
  for (const doc of snapshot.docs) {
    await deleteSubcollection(db, doc.ref, 'messages');
    await doc.ref.delete();
  }
  if (!snapshot.empty) {
    console.log(`Deleted ${snapshot.docs.length} legacy chats for user ${uid}`);
  }
}

/**
 * Deletes root-level superLikes where the user is sender or recipient.
 */
async function deleteUserSuperLikes(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const ref = db.collection('superLikes');
  const asFrom = await ref.where('fromUserId', '==', uid).get();
  const asTo = await ref.where('toUserId', '==', uid).get();
  const toDelete = new Set<string>();
  asFrom.docs.forEach((d) => toDelete.add(d.id));
  asTo.docs.forEach((d) => toDelete.add(d.id));
  const batchSize = 500;
  const ids = Array.from(toDelete);
  for (let i = 0; i < ids.length; i += batchSize) {
    const batch = db.batch();
    ids.slice(i, i + batchSize).forEach((id) => batch.delete(ref.doc(id)));
    await batch.commit();
  }
  if (toDelete.size > 0) {
    console.log(`Deleted ${toDelete.size} superLike docs for user ${uid}`);
  }
}

/**
 * Deletes root-level docs where field equals uid (e.g. swipeHistory, undoUsage, superLikeUsage, notifications).
 */
async function deleteRootCollectionByUserId(
  db: admin.firestore.Firestore,
  collectionName: string,
  fieldName: string,
  uid: string
): Promise<void> {
  const colRef = db.collection(collectionName);
  const snapshot = await colRef.where(fieldName, '==', uid).get();
  const batchSize = 500;
  for (let i = 0; i < snapshot.docs.length; i += batchSize) {
    const batch = db.batch();
    snapshot.docs
      .slice(i, i + batchSize)
      .forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  if (!snapshot.empty) {
    console.log(
      `Deleted ${snapshot.docs.length} ${collectionName} docs for user ${uid}`
    );
  }
}

/**
 * Updates the accountDeletions doc for this user to completed (written by client as pending before delete).
 */
async function writeAuditCompleted(
  db: admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const ref = db.collection('accountDeletions').doc(uid);
  await ref.set(
    {
      status: 'completed',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  console.log(`Updated accountDeletions/${uid} to completed`);
}

/**
 * Runs the full cleanup for a deleted Auth user. Exported for unit tests.
 * Trigger calls this; production code should use onAuthUserDeleted.
 */
export async function runAuthUserDeletedCleanup(user: {
  uid: string;
}): Promise<void> {
  const uid = user.uid;
  console.log(`Auth user deleted: ${uid}, cleaning up Firestore and Storage`);

  const db = admin.firestore();

  const userRef = db.collection('users').doc(uid);

  for (const sub of USER_SUBCOLLECTIONS) {
    await deleteSubcollection(db, userRef, sub);
  }

  await deleteUserLikes(db, uid);
  await deleteUserMatches(db, uid);
  await deleteUserSuperLikes(db, uid);

  await deleteUserChatThreads(db, uid);
  await deleteUserLegacyChats(db, uid);

  await deleteRootCollectionByUserId(db, 'swipeHistory', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'undoUsage', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'superLikeUsage', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'notifications', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'notificationLogs', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'diaryEntries', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'feedback', 'userId', uid);
  await deleteRootCollectionByUserId(db, 'reports', 'reporterId', uid);
  await deleteRootCollectionByUserId(db, 'group_reports', 'reporterId', uid);
  await deleteRootCollectionByUserId(db, 'security_logs', 'reporterId', uid);

  await userRef.delete();
  console.log(`Deleted user doc users/${uid}`);

  await deleteUserStorage(uid);

  await writeAuditCompleted(db, uid);
  console.log(`Auth cleanup completed for ${uid}`);
}

/**
 * Triggered when a Firebase Auth user is deleted.
 * Cleans up Firestore (user doc + subcollections, root likes/matches, chatThreads, chats) and Storage.
 * Updates accountDeletions/{uid} to completed (client writes pending before delete).
 */
export const onAuthUserDeleted =
  functions.auth.user().onDelete(runAuthUserDeletedCleanup);
