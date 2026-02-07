import '../../onboarding/bloc/onboarding_data.dart';
import '../models/matched_user_model.dart';

/// Service for managing match-related operations including personalized matching,
/// category-based filtering, and match scoring algorithms.
class MatchService {
  /// Sample data for all potential matches - in production this would come from Firestore
  static final List<MatchedUser> _allPotentialMatches = [
    MatchedUser(
      id: '1',
      name: 'Amina',
      age: 26,
      location: 'Lagos',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Hausa',
      profession: 'Doctor',
      personality: ['Outgoing', 'Ambitious'],
      bio:
          'I love traveling and experiencing new cultures. When I\'m not at the hospital, you can find me exploring local markets or trying new recipes.',
      interests: ['Cooking', 'Travel', 'Reading', 'Afrobeats'],
    ),
    MatchedUser(
      id: '2',
      name: 'Tunde',
      age: 28,
      location: 'Abuja',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Yoruba',
      profession: 'Software Engineer',
      personality: ['Creative', 'Analytical'],
      bio:
          'Tech enthusiast who loves building solutions that make a difference. I enjoy hiking on weekends and playing the guitar when I need to unwind.',
      interests: ['Hiking', 'Music', 'Technology', 'Photography'],
    ),
    MatchedUser(
      id: '3',
      name: 'Ngozi',
      age: 25,
      location: 'Port Harcourt',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Igbo',
      profession: 'Entrepreneur',
      personality: ['Confident', 'Driven'],
      bio:
          'Building my fashion brand while exploring life\'s adventures. I believe in hard work and creating meaningful connections with people.',
      interests: ['Fashion', 'Business', 'Dance', 'Cooking'],
    ),
    MatchedUser(
      id: '4',
      name: 'Kwame',
      age: 30,
      location: 'Accra',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Ashanti',
      profession: 'Architect',
      personality: ['Thoughtful', 'Detail-oriented'],
      bio:
          'I find beauty in structures and design. My passion is creating spaces that inspire people. I enjoy good conversations over coffee and weekend road trips.',
      interests: ['Architecture', 'Art', 'Coffee', 'Travel'],
    ),
    MatchedUser(
      id: '5',
      name: 'Zainab',
      age: 27,
      location: 'Kano',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Fulani',
      profession: 'Teacher',
      personality: ['Patient', 'Kind'],
      bio:
          'I believe education changes lives. When I\'m not teaching, I enjoy writing poetry and volunteering at local community centers.',
      interests: ['Poetry', 'Education', 'Community Service', 'Nature'],
    ),
    MatchedUser(
      id: '6',
      name: 'Chijioke',
      age: 32,
      location: 'Lagos',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Igbo',
      profession: 'Financial Analyst',
      personality: ['Organized', 'Strategic'],
      bio:
          'Finance professional with a passion for helping people achieve financial freedom. I enjoy playing tennis and exploring new restaurants in my free time.',
      interests: ['Finance', 'Tennis', 'Food', 'Travel'],
    ),
    MatchedUser(
      id: '7',
      name: 'Fatima',
      age: 24,
      location: 'Kaduna',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Hausa',
      profession: 'Graphic Designer',
      personality: ['Creative', 'Intuitive'],
      bio:
          'Visual storyteller who loves bringing ideas to life through design. I am passionate about art, photography, and discovering hidden gems in my city.',
      interests: ['Design', 'Art', 'Photography', 'Music'],
    ),
    MatchedUser(
      id: '8',
      name: 'Oluwaseun',
      age: 29,
      location: 'Ibadan',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Yoruba',
      profession: 'Marketing Manager',
      personality: ['Extroverted', 'Strategic'],
      bio:
          'Marketing professional who loves connecting brands with their audience. I enjoy networking events, playing basketball, and trying new recipes.',
      interests: ['Marketing', 'Basketball', 'Cooking', 'Networking'],
    ),
    MatchedUser(
      id: '9',
      name: 'Adanna',
      age: 26,
      location: 'Enugu',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Igbo',
      profession: 'Content Creator',
      personality: ['Creative', 'Expressive'],
      bio:
          'Digital storyteller passionate about African narratives. I create content that celebrates our culture and heritage. Love dancing and exploring new places.',
      interests: ['Content Creation', 'Culture', 'Dance', 'Travel'],
    ),
    MatchedUser(
      id: '10',
      name: 'Ibrahim',
      age: 31,
      location: 'Kano',
      profileImage: 'assets/images/placeholder_profile.jpg',
      tribe: 'Hausa',
      profession: 'Doctor',
      personality: ['Compassionate', 'Dedicated'],
      bio:
          'Healthcare professional committed to improving access to quality healthcare. I enjoy reading, playing chess, and volunteering in community health programs.',
      interests: ['Healthcare', 'Reading', 'Chess', 'Volunteering'],
    ),
  ];

  /// Get personalized matches based on user preferences
  ///
  /// [data] - The onboarding data containing user preferences
  /// [limit] - Maximum number of matches to return (default: 5)
  ///
  /// Returns a list of MatchedUser objects sorted by compatibility
  static List<MatchedUser> getPersonalizedMatches(
    OnboardingData data, {
    int limit = 5,
  }) {
    // Validate input parameters
    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    // Create a copy of all matches to work with
    final List<MatchedUser> filteredMatches = List.from(_allPotentialMatches);

    // Apply filters based on user preferences
    if (data.tribe.isNotEmpty) {
      // Prioritize matches from the same tribe but don't exclude others
      filteredMatches.sort((a, b) {
        if (a.tribe == data.tribe && b.tribe != data.tribe) {
          return -1; // a comes first
        } else if (a.tribe != data.tribe && b.tribe == data.tribe) {
          return 1; // b comes first
        }
        return 0; // no change in order
      });
    }

    // Filter by location if available
    if (data.locationName != null) {
      // Extract city from location (assuming format is "City, Country")
      final userCity = data.locationName!.split(',').first.trim();

      // Prioritize matches from the same location
      filteredMatches.sort((a, b) {
        final aCity = a.location.split(',').first.trim();
        final bCity = b.location.split(',').first.trim();

        if (aCity == userCity && bCity != userCity) {
          return -1; // a comes first
        } else if (aCity != userCity && bCity == userCity) {
          return 1; // b comes first
        }
        return 0; // no change in order
      });
    }

    // Filter by interests if available
    if (data.genres.isNotEmpty) {
      // Calculate interest match score for each potential match
      final Map<String, int> matchScores = {};

      for (final match in filteredMatches) {
        int score = 0;
        for (final interest in match.interests) {
          if (data.genres.contains(interest)) {
            score++;
          }
        }
        matchScores[match.id] = score;
      }

      // Sort by interest match score (higher scores first)
      filteredMatches.sort((a, b) {
        final scoreA = matchScores[a.id] ?? 0;
        final scoreB = matchScores[b.id] ?? 0;
        return scoreB.compareTo(scoreA);
      });
    }

    // Return limited number of matches
    return filteredMatches.take(limit).toList();
  }

  /// Get matches based on specific criteria (for Friendship/Networking tabs)
  ///
  /// [category] - The category to filter by (nearby, same_tribe, shared_interests)
  /// [data] - The onboarding data containing user preferences
  /// [limit] - Maximum number of matches to return (default: 5)
  ///
  /// Returns a list of MatchedUser objects filtered by the specified category
  static List<MatchedUser> getMatchesByCategory(
    String category,
    OnboardingData data, {
    int limit = 5,
  }) {
    // Validate input parameters
    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }
    if (category.isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }

    List<MatchedUser> matches = [];

    switch (category) {
      case 'nearby':
        // Get matches near the user's location
        if (data.locationName != null) {
          final userCity = data.locationName!.split(',').first.trim();
          matches = _allPotentialMatches.where((match) {
            final matchCity = match.location.split(',').first.trim();
            return matchCity == userCity;
          }).toList();
        }
        break;

      case 'same_tribe':
        // Get matches from the same tribe
        if (data.tribe.isNotEmpty) {
          matches = _allPotentialMatches
              .where((match) => match.tribe == data.tribe)
              .toList();
        }
        break;

      case 'shared_interests':
        // Get matches with shared interests
        if (data.genres.isNotEmpty) {
          matches = _allPotentialMatches.where((match) {
            for (final interest in match.interests) {
              if (data.genres.contains(interest)) {
                return true;
              }
            }
            return false;
          }).toList();
        }
        break;

      default:
        matches = List.from(_allPotentialMatches);
    }

    // If no matches found based on criteria, return random matches
    if (matches.isEmpty) {
      matches = List.from(_allPotentialMatches);
    }

    // Shuffle to add variety if there are enough matches
    if (matches.length > limit) {
      matches.shuffle();
    }

    return matches.take(limit).toList();
  }

  /// Get all available match categories
  static List<String> getAvailableCategories() =>
      ['nearby', 'same_tribe', 'shared_interests'];

  /// Calculate match compatibility score between two users
  static double calculateMatchScore(
    MatchedUser user1,
    MatchedUser user2,
  ) {
    double score = 0;
    int factors = 0;

    // Location compatibility (30% weight)
    if (user1.location == user2.location) {
      score += 0.3;
    }
    factors++;

    // Tribe compatibility (20% weight)
    if (user1.tribe == user2.tribe && user1.tribe != null) {
      score += 0.2;
    }
    factors++;

    // Interest compatibility (40% weight)
    final commonInterests = user1.interests
        .where((interest) => user2.interests.contains(interest))
        .length;
    final maxInterests = [user1.interests.length, user2.interests.length]
        .reduce((a, b) => a > b ? a : b);
    if (maxInterests > 0) {
      score += 0.4 * (commonInterests / maxInterests);
    }
    factors++;

    // Age compatibility (10% weight)
    final ageDiff = (user1.age - user2.age).abs();
    if (ageDiff <= 5) {
      score += 0.1;
    } else if (ageDiff <= 10) {
      score += 0.05;
    }
    factors++;

    return factors > 0 ? score : 0.0;
  }

  /// Get match statistics for analytics
  static Map<String, dynamic> getMatchStatistics() {
    final totalMatches = _allPotentialMatches.length;
    final tribes = _allPotentialMatches.map((m) => m.tribe).toSet();
    final locations = _allPotentialMatches.map((m) => m.location).toSet();

    return {
      'totalMatches': totalMatches,
      'uniqueTribes': tribes.length,
      'uniqueLocations': locations.length,
      'averageAge':
          _allPotentialMatches.map((m) => m.age).reduce((a, b) => a + b) /
              totalMatches,
    };
  }
}
