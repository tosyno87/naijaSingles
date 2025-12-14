import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Industry-standard advanced search service
/// Features:
/// - Multi-criteria filtering
/// - Location-based search
/// - Smart matching algorithm
/// - Search history
/// - Saved searches
/// - Real-time search suggestions
class AdvancedSearchService {
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();
  static final AdvancedSearchService _instance =
      AdvancedSearchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Advanced search with multiple criteria
  Future<List<UserModel>> searchUsers({
    required SearchCriteria criteria,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      log('🔍 Starting advanced search with criteria: $criteria');

      Query query = _firestore.collection('users');

      // Apply filters
      query = _applyFilters(query, criteria);

      // Apply location filter if provided
      if (criteria.location != null) {
        query = _applyLocationFilter(query, criteria.location!);
      }

      // Apply sorting
      query = _applySorting(query, criteria);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      // Execute query
      final QuerySnapshot snapshot = await query.get();

      // Convert to UserModel list
      final List<UserModel> users = snapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),)
          .toList();

      // Apply additional filtering (for complex criteria)
      final List<UserModel> filteredUsers =
          _applyAdditionalFilters(users, criteria);

      log('🔍 Found ${filteredUsers.length} users matching criteria');
      return filteredUsers;
    } catch (e) {
      log('❌ Error in advanced search: $e');
      return [];
    }
  }

  /// Apply basic filters to query
  Query _applyFilters(Query query, SearchCriteria criteria) {
    // Age range filter
    if (criteria.ageRange != null) {
      query =
          query.where('age', isGreaterThanOrEqualTo: criteria.ageRange!.min);
      query = query.where('age', isLessThanOrEqualTo: criteria.ageRange!.max);
    }

    // Gender filter
    if (criteria.gender != null && criteria.gender!.isNotEmpty) {
      query = query.where('gender', isEqualTo: criteria.gender);
    }

    // Interested in filter
    if (criteria.interestedIn != null && criteria.interestedIn!.isNotEmpty) {
      query = query.where('interestedIn', isEqualTo: criteria.interestedIn);
    }

    // Tribe filter
    if (criteria.tribe != null && criteria.tribe!.isNotEmpty) {
      query = query.where('tribe', isEqualTo: criteria.tribe);
    }

    // Nationality filter
    if (criteria.nationality != null && criteria.nationality!.isNotEmpty) {
      query = query.where('nationality', isEqualTo: criteria.nationality);
    }

    // Religion filter
    if (criteria.religion != null && criteria.religion!.isNotEmpty) {
      query = query.where('religion', isEqualTo: criteria.religion);
    }

    // Education filter
    if (criteria.education != null && criteria.education!.isNotEmpty) {
      query = query.where('education', isEqualTo: criteria.education);
    }

    // Occupation filter
    if (criteria.occupation != null && criteria.occupation!.isNotEmpty) {
      query = query.where('occupation', isEqualTo: criteria.occupation);
    }

    // Height range filter
    if (criteria.heightRange != null) {
      query = query.where('height',
          isGreaterThanOrEqualTo: criteria.heightRange!.min,);
      query =
          query.where('height', isLessThanOrEqualTo: criteria.heightRange!.max);
    }

    // Relationship intent filter
    if (criteria.relationshipIntent != null &&
        criteria.relationshipIntent!.isNotEmpty) {
      query = query.where('relationshipIntent',
          isEqualTo: criteria.relationshipIntent,);
    }

    // Looking for filter
    if (criteria.lookingFor != null && criteria.lookingFor!.isNotEmpty) {
      query = query.where('lookingFor', isEqualTo: criteria.lookingFor);
    }

    // Exclude current user
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      query = query.where(FieldPath.documentId, isNotEqualTo: currentUserId);
    }

    // Exclude blocked users
    query = query.where('isBlocked', isEqualTo: false);

    // Only show users with complete profiles
    query = query.where('isProfileComplete', isEqualTo: true);

    return query;
  }

  /// Apply location-based filtering
  Query _applyLocationFilter(Query query, LocationCriteria location) {
    // This is a simplified version. In production, you'd use GeoFirestore
    // or implement proper geospatial queries

    if (location.city != null && location.city!.isNotEmpty) {
      query = query.where('locationName', isEqualTo: location.city);
    }

    return query;
  }

  /// Apply sorting to query
  Query _applySorting(Query query, SearchCriteria criteria) {
    switch (criteria.sortBy) {
      case SearchSortBy.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SearchSortBy.oldest:
        query = query.orderBy('createdAt', descending: false);
        break;
      case SearchSortBy.lastActive:
        query = query.orderBy('lastActive', descending: true);
        break;
      case SearchSortBy.distance:
        // Distance sorting would require geospatial queries
        query = query.orderBy('lastActive', descending: true);
        break;
      case SearchSortBy.age:
        query = query.orderBy('age', descending: false);
        break;
    }

    return query;
  }

  /// Apply additional filters that can't be done in Firestore
  List<UserModel> _applyAdditionalFilters(
      List<UserModel> users, SearchCriteria criteria,) => users.where((user) {
      // Interest matching
      if (criteria.interests != null && criteria.interests!.isNotEmpty) {
        final userInterests =
            user.editInfo?['interests'] as List<String>? ?? [];
        final hasMatchingInterest = criteria.interests!.any(
          userInterests.contains,
        );
        if (!hasMatchingInterest) return false;
      }

      // Language matching
      if (criteria.languages != null && criteria.languages!.isNotEmpty) {
        final userLanguages = user.languages ?? [];
        final hasMatchingLanguage = criteria.languages!.any(
          userLanguages.contains,
        );
        if (!hasMatchingLanguage) return false;
      }

      // Bio keyword search
      if (criteria.bioKeywords != null && criteria.bioKeywords!.isNotEmpty) {
        final userBio = (user.bio ?? '').toLowerCase();
        final hasMatchingKeyword = criteria.bioKeywords!.any(
          (keyword) => userBio.contains(keyword.toLowerCase()),
        );
        if (!hasMatchingKeyword) return false;
      }

      return true;
    }).toList();

  /// Search suggestions based on user input
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      final List<String> suggestions = [];

      // Get tribe suggestions
      final tribeQuery = await _firestore
          .collection('users')
          .where('tribe', isGreaterThanOrEqualTo: query)
          .where('tribe', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(5)
          .get();

      suggestions.addAll(
        tribeQuery.docs.map((doc) => doc.data()['tribe'] as String),
      );

      // Get interest suggestions
      final interestQuery = await _firestore
          .collection('users')
          .where('interests', arrayContains: query)
          .limit(5)
          .get();

      for (final doc in interestQuery.docs) {
        final interests = List<String>.from(doc.data()['interests'] ?? []);
        suggestions.addAll(
          interests.where((interest) =>
              interest.toLowerCase().contains(query.toLowerCase()),),
        );
      }

      // Remove duplicates and return
      return suggestions.toSet().take(10).toList();
    } catch (e) {
      log('❌ Error getting search suggestions: $e');
      return [];
    }
  }

  /// Save search criteria for later use
  Future<void> saveSearch(String name, SearchCriteria criteria) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedSearches')
          .add({
        'name': name,
        'criteria': criteria.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('🔍 Search saved: $name');
    } catch (e) {
      log('❌ Error saving search: $e');
    }
  }

  /// Get saved searches
  Future<List<SavedSearch>> getSavedSearches() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedSearches')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SavedSearch(
          id: doc.id,
          name: data['name'] ?? '',
          criteria: SearchCriteria.fromMap(data['criteria'] ?? {}),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      log('❌ Error getting saved searches: $e');
      return [];
    }
  }

  /// Delete saved search
  Future<void> deleteSavedSearch(String searchId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedSearches')
          .doc(searchId)
          .delete();

      log('🔍 Search deleted: $searchId');
    } catch (e) {
      log('❌ Error deleting search: $e');
    }
  }

  /// Get search history
  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('searchHistory')
          .orderBy('searchedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SearchHistory(
          id: doc.id,
          query: data['query'] ?? '',
          resultCount: data['resultCount'] ?? 0,
          searchedAt:
              (data['searchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      log('❌ Error getting search history: $e');
      return [];
    }
  }

  /// Record search in history
  Future<void> recordSearch(String query, int resultCount) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('searchHistory')
          .add({
        'query': query,
        'resultCount': resultCount,
        'searchedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('❌ Error recording search: $e');
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('searchHistory')
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('🔍 Search history cleared');
    } catch (e) {
      log('❌ Error clearing search history: $e');
    }
  }
}

/// Search criteria model
class SearchCriteria {

  const SearchCriteria({
    this.ageRange,
    this.gender,
    this.interestedIn,
    this.tribe,
    this.nationality,
    this.religion,
    this.education,
    this.occupation,
    this.heightRange,
    this.relationshipIntent,
    this.lookingFor,
    this.interests,
    this.languages,
    this.bioKeywords,
    this.location,
    this.sortBy = SearchSortBy.lastActive,
  });

  factory SearchCriteria.fromMap(Map<String, dynamic> map) => SearchCriteria(
      ageRange:
          map['ageRange'] != null ? AgeRange.fromMap(map['ageRange']) : null,
      gender: map['gender'],
      interestedIn: map['interestedIn'],
      tribe: map['tribe'],
      nationality: map['nationality'],
      religion: map['religion'],
      education: map['education'],
      occupation: map['occupation'],
      heightRange: map['heightRange'] != null
          ? HeightRange.fromMap(map['heightRange'])
          : null,
      relationshipIntent: map['relationshipIntent'],
      lookingFor: map['lookingFor'],
      interests: List<String>.from(map['interests'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      bioKeywords: List<String>.from(map['bioKeywords'] ?? []),
      location: map['location'] != null
          ? LocationCriteria.fromMap(map['location'])
          : null,
      sortBy: SearchSortBy.values.firstWhere(
        (e) => e.name == map['sortBy'],
        orElse: () => SearchSortBy.lastActive,
      ),
    );
  final AgeRange? ageRange;
  final String? gender;
  final String? interestedIn;
  final String? tribe;
  final String? nationality;
  final String? religion;
  final String? education;
  final String? occupation;
  final HeightRange? heightRange;
  final String? relationshipIntent;
  final String? lookingFor;
  final List<String>? interests;
  final List<String>? languages;
  final List<String>? bioKeywords;
  final LocationCriteria? location;
  final SearchSortBy sortBy;

  Map<String, dynamic> toMap() => {
      'ageRange': ageRange?.toMap(),
      'gender': gender,
      'interestedIn': interestedIn,
      'tribe': tribe,
      'nationality': nationality,
      'religion': religion,
      'education': education,
      'occupation': occupation,
      'heightRange': heightRange?.toMap(),
      'relationshipIntent': relationshipIntent,
      'lookingFor': lookingFor,
      'interests': interests,
      'languages': languages,
      'bioKeywords': bioKeywords,
      'location': location?.toMap(),
      'sortBy': sortBy.name,
    };

  @override
  String toString() => 'SearchCriteria(ageRange: $ageRange, gender: $gender, tribe: $tribe, sortBy: $sortBy)';
}

/// Age range model
class AgeRange {

  const AgeRange({required this.min, required this.max});

  factory AgeRange.fromMap(Map<String, dynamic> map) =>
      AgeRange(min: map['min'], max: map['max']);
  final int min;
  final int max;

  Map<String, dynamic> toMap() => {'min': min, 'max': max};

  @override
  String toString() => 'AgeRange($min-$max)';
}

/// Height range model
class HeightRange {

  const HeightRange({required this.min, required this.max});

  factory HeightRange.fromMap(Map<String, dynamic> map) =>
      HeightRange(min: map['min'], max: map['max']);
  final double min;
  final double max;

  Map<String, dynamic> toMap() => {'min': min, 'max': max};

  @override
  String toString() => 'HeightRange($min-$max)';
}

/// Location criteria model
class LocationCriteria {

  const LocationCriteria({
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  factory LocationCriteria.fromMap(Map<String, dynamic> map) =>
      LocationCriteria(
        city: map['city'],
        country: map['country'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        radiusKm: map['radiusKm'],
      );
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  Map<String, dynamic> toMap() => {
        'city': city,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      };

  @override
  String toString() => 'LocationCriteria(city: $city, radius: ${radiusKm}km)';
}

/// Search sort options
enum SearchSortBy {
  newest,
  oldest,
  lastActive,
  distance,
  age,
}

/// Saved search model
class SavedSearch {

  const SavedSearch({
    required this.id,
    required this.name,
    required this.criteria,
    required this.createdAt,
  });
  final String id;
  final String name;
  final SearchCriteria criteria;
  final DateTime createdAt;

  @override
  String toString() => 'SavedSearch($name)';
}

/// Search history model
class SearchHistory {

  const SearchHistory({
    required this.id,
    required this.query,
    required this.resultCount,
    required this.searchedAt,
  });
  final String id;
  final String query;
  final int resultCount;
  final DateTime searchedAt;

  @override
  String toString() => 'SearchHistory($query: $resultCount results)';
}
