#!/usr/bin/env node

/**
 * One-time migration: replaces placeholder 'Current User' RSVP attendee
 * profiles with real user data from the `users` collection.
 *
 * Usage:
 *   node scripts/backfill_rsvp_profiles.js            # dry-run (default)
 *   node scripts/backfill_rsvp_profiles.js --apply     # write changes
 *
 * Auth: uses Firebase CLI cached credentials (~/.config/configstore/firebase-tools.json)
 *       or GOOGLE_APPLICATION_CREDENTIALS env var if set.
 *
 * Affected collections:
 *   event_attendees/{eventId}/attendees/{userId}
 *   user_rsvps/{userId}/events/{eventId}
 */

const { Firestore } = require("@google-cloud/firestore");
const { OAuth2Client } = require("google-auth-library");
const fs = require("fs");
const path = require("path");

const DRY_RUN = !process.argv.includes("--apply");
const BATCH_LIMIT = 400;
const PROJECT_ID = "naijasingles-74a75";

// Firebase CLI OAuth client ID (public, used by all Firebase CLI installations)
const FIREBASE_CLIENT_ID =
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const FIREBASE_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";

function createFirestore() {
  // If GOOGLE_APPLICATION_CREDENTIALS is set, Firestore uses it automatically
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return new Firestore({ projectId: PROJECT_ID });
  }

  // Otherwise use Firebase CLI cached tokens
  const tokenPath = path.join(
    process.env.HOME,
    ".config",
    "configstore",
    "firebase-tools.json"
  );

  if (!fs.existsSync(tokenPath)) {
    console.error("❌ No Firebase credentials found.");
    console.error("   Run 'firebase login' first, or set GOOGLE_APPLICATION_CREDENTIALS.");
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(tokenPath, "utf8"));
  const tokens = config.tokens;

  if (!tokens || !tokens.refresh_token) {
    console.error("❌ Firebase CLI token missing or expired. Run 'firebase login'.");
    process.exit(1);
  }

  const oauth2Client = new OAuth2Client(
    FIREBASE_CLIENT_ID,
    FIREBASE_CLIENT_SECRET
  );
  oauth2Client.setCredentials({
    refresh_token: tokens.refresh_token,
  });

  return new Firestore({
    projectId: PROJECT_ID,
    authClient: oauth2Client,
  });
}

async function main() {
  console.log("🔧 RSVP Profile Backfill Migration");
  console.log("===================================");
  console.log(
    `Mode: ${DRY_RUN ? "DRY RUN (no writes)" : "⚠️  APPLY (writing to Firestore)"}`
  );
  console.log("");

  const db = createFirestore();

  // Quick connectivity check
  console.log("🔌 Connecting to Firestore...");
  try {
    await db.collection("users").limit(1).get();
    console.log("   ✅ Connected.\n");
  } catch (e) {
    console.error("   ❌ Connection failed:", e.message);
    process.exit(1);
  }

  const userProfileCache = new Map();

  async function fetchUserProfile(userId) {
    if (userProfileCache.has(userId)) return userProfileCache.get(userId);
    try {
      const doc = await db.collection("users").doc(userId).get();
      if (!doc.exists) {
        userProfileCache.set(userId, null);
        return null;
      }
      const data = doc.data();
      const photos = Array.isArray(data.photos) ? data.photos : [];
      const profile = {
        name: (data.name || "Unknown").toString(),
        avatar: photos.length > 0 ? photos[0] : null,
        age: data.age || null,
        location: data.address ? data.address.toString() : null,
      };
      userProfileCache.set(userId, profile);
      return profile;
    } catch (e) {
      console.error(`  ❌ Error fetching user ${userId}:`, e.message);
      userProfileCache.set(userId, null);
      return null;
    }
  }

  function needsBackfill(data) {
    const profile = data.userProfile;
    if (!profile || typeof profile !== "object") return true;
    const name = (profile.name || "").toString();
    return name === "" || name === "Current User" || name === "Unknown";
  }

  // --- Phase 1: Scan event_attendees ---
  console.log("📡 Scanning event_attendees...");
  const badRecords = [];

  const eventAttendeeDocs = await db.collection("event_attendees").listDocuments();
  console.log(`   Found ${eventAttendeeDocs.length} event(s) with attendees.`);

  for (const eventDocRef of eventAttendeeDocs) {
    const eventId = eventDocRef.id;
    const attendeesSnap = await eventDocRef.collection("attendees").get();

    for (const doc of attendeesSnap.docs) {
      const data = doc.data();
      if (!needsBackfill(data)) continue;

      const userId = (data.userId || "").toString();
      if (!userId) continue;

      badRecords.push({
        userId,
        eventId,
        currentName: (data.userProfile?.name || "<null>").toString(),
        docPath: doc.ref.path,
      });
    }
  }

  console.log(`   🔍 Found ${badRecords.length} records needing backfill.\n`);

  if (badRecords.length === 0) {
    console.log("✅ No bad records found. Nothing to do.");
    process.exit(0);
  }

  // --- Phase 2: Backfill ---
  console.log("🔄 Backfilling profiles...\n");

  let updated = 0;
  let skipped = 0;
  let errors = 0;

  for (let i = 0; i < badRecords.length; i += BATCH_LIMIT / 2) {
    const chunk = badRecords.slice(i, i + BATCH_LIMIT / 2);
    const batch = db.batch();
    let batchWrites = 0;

    for (const record of chunk) {
      const profile = await fetchUserProfile(record.userId);

      if (!profile) {
        console.log(`  ⏭️  SKIP ${record.userId} (user doc not found)`);
        skipped++;
        continue;
      }

      const newName = profile.name || "Unknown";
      console.log(
        `  ${DRY_RUN ? "🔍" : "✏️"} "${record.currentName}" → "${newName}" ` +
          `(user: ${record.userId}, event: ${record.eventId})`
      );

      if (!DRY_RUN) {
        const attendeeRef = db
          .collection("event_attendees")
          .doc(record.eventId)
          .collection("attendees")
          .doc(record.userId);
        batch.set(attendeeRef, { userProfile: profile }, { merge: true });

        const userRsvpRef = db
          .collection("user_rsvps")
          .doc(record.userId)
          .collection("events")
          .doc(record.eventId);
        batch.set(userRsvpRef, { userProfile: profile }, { merge: true });

        batchWrites += 2;
      }

      updated++;
    }

    if (!DRY_RUN && batchWrites > 0) {
      try {
        await batch.commit();
        console.log(`   ✅ Batch committed (${batchWrites} writes)`);
      } catch (e) {
        console.error(`   ❌ Batch error:`, e.message);
        errors += chunk.length;
        updated -= chunk.length;
      }
    }
  }

  console.log("\n===================================");
  console.log("📊 Results:");
  console.log(`   Total bad records:  ${badRecords.length}`);
  console.log(`   ${DRY_RUN ? "Would update" : "Updated"}:      ${updated}`);
  console.log(`   Skipped (no user): ${skipped}`);
  if (errors > 0) console.log(`   Errors:             ${errors}`);
  console.log(`   Mode:               ${DRY_RUN ? "DRY RUN" : "APPLIED"}`);

  if (DRY_RUN && updated > 0) {
    console.log("\n💡 Run with --apply to write changes:");
    console.log("   node scripts/backfill_rsvp_profiles.js --apply");
  }

  console.log("");
  process.exit(0);
}

main().catch((e) => {
  console.error("💥 Fatal error:", e.message || e);
  process.exit(1);
});
