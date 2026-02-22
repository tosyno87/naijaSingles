import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

final FirebaseOptions _firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAwsU8j3acGo_cKOECbgsXHd3-qvvLn_Fw',
  appId: '1:888697307756:ios:95ea92b8c7288e31704e49',
  messagingSenderId: '888697307756',
  projectId: 'naijasingles-74a75',
  storageBucket: 'naijasingles-74a75.appspot.com',
  iosBundleId: 'com.naijasingles.app',
);

/// One-time migration: replaces placeholder 'Current User' RSVP attendee
/// profiles with real user data from the `users` collection.
///
/// Usage:
///   dart run scripts/backfill_rsvp_profiles.dart          # dry-run (default)
///   dart run scripts/backfill_rsvp_profiles.dart --apply   # write changes
///
/// Affected collections:
///   event_attendees/{eventId}/attendees/{userId}
///   user_rsvps/{userId}/events/{eventId}
void main(List<String> args) async {
  final dryRun = !args.contains('--apply');

  print('🔧 RSVP Profile Backfill Migration');
  print('===================================');
  print('Mode: ${dryRun ? "DRY RUN (no writes)" : "⚠️  APPLY (writing to Firestore)"}');
  print('');

  await Firebase.initializeApp(options: _firebaseOptions);
  final firestore = FirebaseFirestore.instance;

  final userProfileCache = <String, Map<String, dynamic>?>{};

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    if (userProfileCache.containsKey(userId)) {
      return userProfileCache[userId];
    }
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        userProfileCache[userId] = null;
        return null;
      }
      final data = doc.data()!;
      final photos = data['photos'];
      final profile = {
        'name': data['name']?.toString() ?? 'Unknown',
        'avatar': (photos is List && photos.isNotEmpty) ? photos[0] : null,
        'age': data['age'],
        'location': data['address']?.toString(),
      };
      userProfileCache[userId] = profile;
      return profile;
    } catch (e) {
      print('  ❌ Error fetching user $userId: $e');
      userProfileCache[userId] = null;
      return null;
    }
  }

  bool needsBackfill(Map<String, dynamic> data) {
    final profile = data['userProfile'];
    if (profile == null) return true;
    if (profile is! Map) return true;
    final name = profile['name']?.toString() ?? '';
    return name.isEmpty || name == 'Current User' || name == 'Unknown';
  }

  // --- Phase 1: Scan event_attendees via collectionGroup ---
  print('📡 Scanning event_attendees (collectionGroup: attendees)...');

  final badRecords = <_BadRecord>[];

  try {
    final attendeesQuery = firestore.collectionGroup('attendees');
    final snapshot = await attendeesQuery.get();

    print('   Found ${snapshot.docs.length} total attendee records.');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!needsBackfill(data)) continue;

      final userId = data['userId']?.toString() ?? '';
      final eventId = data['eventId']?.toString() ?? '';
      if (userId.isEmpty || eventId.isEmpty) continue;

      final currentName = data['userProfile']?['name']?.toString() ?? '<null>';
      badRecords.add(_BadRecord(
        userId: userId,
        eventId: eventId,
        currentName: currentName,
        docPath: doc.reference.path,
      ));
    }
  } catch (e) {
    print('   ⚠️  collectionGroup query failed: $e');
    print('   This likely needs a Firestore index. Falling back to manual scan...');
    await _manualScan(firestore, badRecords, needsBackfill);
  }

  print('   🔍 Found ${badRecords.length} records needing backfill.\n');

  if (badRecords.isEmpty) {
    print('✅ No bad records found. Nothing to do.');
    exit(0);
  }

  // --- Phase 2: Backfill ---
  print('🔄 Backfilling profiles...\n');

  var updated = 0;
  var skipped = 0;
  var errors = 0;

  for (final record in badRecords) {
    final profile = await fetchUserProfile(record.userId);

    if (profile == null) {
      print('  ⏭️  SKIP ${record.userId} (user doc not found)');
      skipped++;
      continue;
    }

    final newName = profile['name'] ?? 'Unknown';
    print('  ${dryRun ? "🔍" : "✏️"} ${record.currentName} → $newName '
        '(user: ${record.userId}, event: ${record.eventId})');

    if (!dryRun) {
      try {
        final batch = firestore.batch();

        final attendeeRef = firestore
            .collection('event_attendees')
            .doc(record.eventId)
            .collection('attendees')
            .doc(record.userId);
        batch.update(attendeeRef, {'userProfile': profile});

        final userRsvpRef = firestore
            .collection('user_rsvps')
            .doc(record.userId)
            .collection('events')
            .doc(record.eventId);
        batch.update(userRsvpRef, {'userProfile': profile});

        await batch.commit();
        updated++;
      } catch (e) {
        print('    ❌ Error updating: $e');
        errors++;
      }
    } else {
      updated++;
    }
  }

  print('\n===================================');
  print('📊 Results:');
  print('   Total bad records:  ${badRecords.length}');
  print('   ${dryRun ? "Would update" : "Updated"}:      $updated');
  print('   Skipped (no user): $skipped');
  if (errors > 0) print('   Errors:             $errors');
  print('   Mode:               ${dryRun ? "DRY RUN" : "APPLIED"}');

  if (dryRun && updated > 0) {
    print('\n💡 Run with --apply to write changes:');
    print('   dart run scripts/backfill_rsvp_profiles.dart --apply');
  }

  print('');
  exit(0);
}

/// Fallback: manually iterate top-level event_attendees docs if
/// collectionGroup query fails (missing index).
Future<void> _manualScan(
  FirebaseFirestore firestore,
  List<_BadRecord> badRecords,
  bool Function(Map<String, dynamic>) needsBackfill,
) async {
  print('   Scanning event_attendees top-level docs...');
  final eventAttendeeDocs =
      await firestore.collection('event_attendees').get();

  for (final eventDoc in eventAttendeeDocs.docs) {
    final eventId = eventDoc.id;
    final attendees = await firestore
        .collection('event_attendees')
        .doc(eventId)
        .collection('attendees')
        .get();

    for (final doc in attendees.docs) {
      final data = doc.data();
      if (!needsBackfill(data)) continue;

      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) continue;

      badRecords.add(_BadRecord(
        userId: userId,
        eventId: eventId,
        currentName: data['userProfile']?['name']?.toString() ?? '<null>',
        docPath: doc.reference.path,
      ));
    }
  }
}

class _BadRecord {
  _BadRecord({
    required this.userId,
    required this.eventId,
    required this.currentName,
    required this.docPath,
  });

  final String userId;
  final String eventId;
  final String currentName;
  final String docPath;
}
