import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../common/utils/app_logger.dart';
import '../models/event_model.dart';

class SeedEventsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seeds the database with sample Afrocentric events if no events exist
  Future<void> seedEventsIfEmpty() async {
    try {
      // Check if events already exist
      final existingEvents =
          await _firestore.collection('events').limit(1).get();

      if (existingEvents.docs.isNotEmpty) {
        AppLogger.debug('Events already exist, skipping seed');
        return;
      }

      AppLogger.info('No events found, seeding with sample events...');
      await _seedSampleEvents();
      AppLogger.info('Sample events seeded successfully');
    } on Object catch (e) {
      AppLogger.error('Error seeding events', error: e);
    }
  }

  Future<void> _seedSampleEvents() async {
    final sampleEvents = _getSampleAfrocentricEvents();

    final batch = _firestore.batch();

    for (final event in sampleEvents) {
      final docRef = _firestore.collection('events').doc();
      final eventWithId = event.copyWith(id: docRef.id);
      batch.set(docRef, eventWithId.toFirestoreJson());
    }

    await batch.commit();
  }

  List<EventModel> _getSampleAfrocentricEvents() {
    final now = DateTime.now();
    const systemUserId = 'system_seed_user'; // System user for seeded events

    return [
      EventModel(
        id: '',
        name: 'Afrobeats Night Lagos',
        description:
            'Experience the best of Afrobeats music with top DJs and live performances. Dance the night away to the latest hits from Nigeria, Ghana, and across Africa.',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7, hours: 6)),
        location: const EventLocation(
          name: 'Victoria Island, Lagos',
          address: 'Victoria Island, Lagos, Nigeria',
          latitude: 6.4281,
          longitude: 3.4219,
        ),
        imageUrl:
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
        category: 'Music',
        isFree: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: systemUserId,
      ),
      EventModel(
        id: '',
        name: 'African Art & Culture Exhibition',
        description:
            'Discover contemporary African art, traditional crafts, and cultural artifacts. Meet local artists and learn about African heritage and traditions.',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 16)),
        location: const EventLocation(
          name: 'National Theatre, Iganmu, Lagos',
          address: 'National Theatre, Iganmu, Lagos, Nigeria',
          latitude: 6.4698,
          longitude: 3.3792,
        ),
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
        category: 'Arts & Culture',
        isFree: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: systemUserId,
      ),
      EventModel(
        id: '',
        name: 'Nigerian Food Festival',
        description:
            'Taste authentic Nigerian cuisine from different regions. Enjoy jollof rice, suya, pounded yam, and more delicious traditional dishes.',
        startDate: now.add(const Duration(days: 21)),
        endDate: now.add(const Duration(days: 21, hours: 8)),
        location: const EventLocation(
          name: 'Tafawa Balewa Square, Lagos',
          address: 'Tafawa Balewa Square, Lagos, Nigeria',
          latitude: 6.4541,
          longitude: 3.3947,
        ),
        imageUrl:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
        category: 'Food & Drink',
        isFree: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: systemUserId,
      ),
      EventModel(
        id: '',
        name: 'Diaspora Connect Event',
        description:
            'Connect with fellow Nigerians living abroad and locals. Share experiences, network, and build lasting friendships in the diaspora community.',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 10, hours: 4)),
        location: const EventLocation(
          name: 'Radisson Blu Anchorage Hotel, Victoria Island',
          address: 'Radisson Blu Anchorage Hotel, Victoria Island, Lagos',
          latitude: 6.4269,
          longitude: 3.4105,
        ),
        imageUrl:
            'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800',
        category: 'Networking',
        isFree: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: systemUserId,
      ),
      EventModel(
        id: '',
        name: 'Afro-Caribbean Dance Workshop',
        description:
            'Learn traditional and modern Afro-Caribbean dance moves. Suitable for all skill levels. Bring comfortable clothes and dancing shoes!',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 5, hours: 3)),
        location: const EventLocation(
          name: 'Terra Kulture, Victoria Island',
          address: 'Terra Kulture, Victoria Island, Lagos',
          latitude: 6.4302,
          longitude: 3.4147,
        ),
        imageUrl:
            'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=800',
        category: 'Sports & Fitness',
        isFree: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: systemUserId,
      ),
    ];
  }
}
