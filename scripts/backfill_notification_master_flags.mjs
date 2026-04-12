#!/usr/bin/env node
/**
 * One-time / ops backfill: ensure `enableAllNotifications` and `muteAllNotifications`
 * exist on every `notificationSettings/{uid}` doc and mirror push prefs to
 * `users/{uid}.notificationPreferences` (merge).
 *
 * Run from repo root with Application Default Credentials, e.g.:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json node scripts/backfill_notification_master_flags.mjs
 *
 * Resolves firebase-admin from `functions/node_modules` (run after `npm install` in functions/).
 */

import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const require = createRequire(resolve(repoRoot, 'functions/package.json'));
const admin = require('firebase-admin');

function loadServiceAccount() {
  const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!p) return null;
  return JSON.parse(readFileSync(p, 'utf8'));
}

function prefsFromSettingsData(d) {
  const like = d.likeNotifications !== false;
  const superLike =
    d.superLikeNotifications !== undefined ? d.superLikeNotifications : like;
  return {
    matchNotifications: d.matchNotifications !== false,
    messageNotifications: d.messageNotifications !== false,
    likeNotifications: like,
    superLikeNotifications: superLike,
    enableAllNotifications:
      d.enableAllNotifications !== undefined ? d.enableAllNotifications : true,
    muteAllNotifications:
      d.muteAllNotifications !== undefined ? d.muteAllNotifications : false,
  };
}

async function main() {
  const sa = loadServiceAccount();
  if (admin.apps.length === 0) {
    if (sa) {
      admin.initializeApp({ credential: admin.credential.cert(sa) });
    } else {
      admin.initializeApp();
    }
  }

  const db = admin.firestore();
  const snap = await db.collection('notificationSettings').get();
  let updatedNs = 0;
  let updatedUsers = 0;
  let batch = db.batch();
  let ops = 0;

  const commitBatch = async () => {
    if (ops === 0) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const doc of snap.docs) {
    const uid = doc.id;
    const d = doc.data();
    const patch = {};
    if (d.enableAllNotifications === undefined) {
      patch.enableAllNotifications = true;
    }
    if (d.muteAllNotifications === undefined) {
      patch.muteAllNotifications = false;
    }
    if (Object.keys(patch).length > 0) {
      batch.set(doc.ref, patch, { merge: true });
      ops++;
      updatedNs++;
    }

    const merged = { ...d, ...patch };
    batch.set(
      db.collection('users').doc(uid),
      { notificationPreferences: prefsFromSettingsData(merged) },
      { merge: true },
    );
    ops++;
    updatedUsers++;

    if (ops >= 450) {
      await commitBatch();
    }
  }

  await commitBatch();
  console.log(
    JSON.stringify({
      notificationSettingsDocs: snap.size,
      patchedNotificationSettings: updatedNs,
      mirroredUsers: updatedUsers,
      cwd: repoRoot,
    }),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
