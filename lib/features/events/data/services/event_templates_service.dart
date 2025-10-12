import '../models/enhanced_event_model.dart';

class EventTemplatesService {
  static List<EventTemplate> getAfrocentricTemplates() {
    return [
      EventTemplate(
        id: 'afrobeats_party',
        name: 'Afrobeats Party',
        description: 'Dance the night away to the hottest Afrobeats hits',
        category: 'Music',
        icon: '🎵',
        color: 0xFF8E24AA,
        suggestedDuration: const Duration(hours: 6),
        defaultData: _createEventData(
          name: 'Afrobeats Night',
          description:
              'Join us for an unforgettable night of Afrobeats music, dancing, and good vibes. DJ will be spinning the latest hits from Nigeria, Ghana, and across Africa.',
          category: 'Music',
          tags: ['afrobeats', 'music', 'dance', 'nightlife', 'african'],
          isFree: false,
          ticketPrice: 25.0, // $25 for nightlife event
          maxAttendees: 200,
        ),
      ),
      EventTemplate(
        id: 'cultural_exhibition',
        name: 'Cultural Exhibition',
        description: 'Showcase African art, crafts, and heritage',
        category: 'Arts & Crafts',
        icon: '🎨',
        color: 0xFF5E35B1,
        suggestedDuration: const Duration(days: 2),
        defaultData: _createEventData(
          name: 'African Heritage Exhibition',
          description:
              'Discover the rich cultural heritage of Africa through art, crafts, and interactive displays. Meet local artists and learn about traditional practices.',
          category: 'Arts & Crafts',
          tags: ['art', 'culture', 'heritage', 'exhibition', 'african'],
          isFree: true, // Cultural exhibitions often free
          maxAttendees: 150,
        ),
      ),
      EventTemplate(
        id: 'food_festival',
        name: 'Food Festival',
        description: 'Celebrate African cuisine and flavors',
        category: 'Food & Dining',
        icon: '🍽️',
        color: 0xFF43A047,
        suggestedDuration: const Duration(hours: 8),
        defaultData: _createEventData(
          name: 'African Food Festival',
          description:
              'Taste authentic African dishes from different regions. Experience the diverse flavors of jollof rice, suya, injera, and many more traditional delicacies.',
          category: 'Food & Dining',
          tags: ['food', 'festival', 'cuisine', 'traditional', 'african'],
          isFree: false,
          ticketPrice: 15.0, // $15 for food festival
          maxAttendees: 300,
        ),
      ),
      EventTemplate(
        id: 'networking_event',
        name: 'Networking Event',
        description: 'Connect with the African diaspora community',
        category: 'Professional Networking',
        icon: '🤝',
        color: 0xFF1E88E5,
        suggestedDuration: const Duration(hours: 3),
        defaultData: _createEventData(
          name: 'Diaspora Connect Event',
          description:
              'Network with fellow Africans and friends of Africa. Share experiences, build connections, and strengthen our community bonds.',
          category: 'Professional Networking',
          tags: [
            'networking',
            'diaspora',
            'community',
            'professional',
            'event'
          ],
          isFree: false,
          ticketPrice: 10.0, // $10 for networking event
          maxAttendees: 80,
        ),
      ),
      EventTemplate(
        id: 'dance_workshop',
        name: 'Dance Workshop',
        description: 'Learn traditional and modern African dances',
        category: 'Sports & Fitness',
        icon: '💃',
        color: 0xFFFF7043,
        suggestedDuration: const Duration(hours: 2),
        defaultData: _createEventData(
          name: 'African Dance Workshop',
          description:
              'Learn energetic African dance moves in a fun, supportive environment. Suitable for all skill levels. Come ready to move and groove!',
          category: 'Sports & Fitness',
          tags: ['dance', 'workshop', 'fitness', 'african', 'traditional'],
          isFree: false,
          ticketPrice: 20.0, // $20 for workshop
          maxAttendees: 50,
        ),
      ),
      EventTemplate(
        id: 'business_conference',
        name: 'Business Conference',
        description: 'African entrepreneurship and business development',
        category: 'Business',
        icon: '💼',
        color: 0xFF6D4C41,
        suggestedDuration: const Duration(hours: 8),
        defaultData: _createEventData(
          name: 'African Business Summit',
          description:
              'Join entrepreneurs, investors, and business leaders to discuss opportunities in African markets. Network and learn from industry experts.',
          category: 'Business',
          tags: [
            'business',
            'entrepreneurship',
            'conference',
            'networking',
            'african'
          ],
          isFree: false,
          ticketPrice: 50.0, // $50 for business conference
          maxAttendees: 120,
        ),
      ),
      EventTemplate(
        id: 'fashion_show',
        name: 'Fashion Show',
        description: 'Showcase African fashion and designers',
        category: 'Entertainment',
        icon: '👗',
        color: 0xFFE91E63,
        suggestedDuration: const Duration(hours: 4),
        defaultData: _createEventData(
          name: 'African Fashion Showcase',
          description:
              'Experience the beauty and creativity of African fashion. Featuring local designers, traditional wear, and contemporary African-inspired pieces.',
          category: 'Entertainment',
          tags: ['fashion', 'design', 'showcase', 'african', 'style'],
          isFree: false,
          ticketPrice: 30.0, // $30 for fashion show
          maxAttendees: 150,
        ),
      ),
      EventTemplate(
        id: 'book_club',
        name: 'Book Club',
        description: 'Discuss African literature and authors',
        category: 'Education',
        icon: '📚',
        color: 0xFF795548,
        suggestedDuration: const Duration(hours: 2),
        defaultData: _createEventData(
          name: 'African Literature Book Club',
          description:
              'Join our monthly book club focusing on African authors and stories. Engage in thoughtful discussions about literature that celebrates African experiences.',
          category: 'Education',
          tags: ['books', 'literature', 'discussion', 'education', 'african'],
          isFree: true, // Book clubs are typically free
          maxAttendees: 25,
        ),
      ),
      EventTemplate(
        id: 'speed_dating',
        name: 'Speed Dating',
        description: 'Quick meet-and-greet for singles',
        category: 'Social Gatherings',
        icon: '💕',
        color: 0xFFE91E63,
        suggestedDuration: const Duration(hours: 3),
        defaultData: _createEventData(
          name: 'African Singles Speed Dating',
          description:
              'Meet amazing singles in a fun, structured environment. Enjoy quick conversations, great music, and the chance to make meaningful connections.',
          category: 'Social Gatherings',
          tags: ['dating', 'singles', 'networking', 'social', 'african'],
          isFree: false,
          ticketPrice: 20.0, // $20 for speed dating
          maxAttendees: 40,
        ),
      ),
      EventTemplate(
        id: 'cooking_class',
        name: 'Cooking Class',
        description: 'Learn to cook African dishes',
        category: 'Food & Dining',
        icon: '🍳',
        color: 0xFFFF5722,
        suggestedDuration: const Duration(hours: 4),
        defaultData: _createEventData(
          name: 'African Cuisine Cooking Class',
          description:
              'Learn to cook authentic African dishes from expert chefs. Includes ingredients, recipes, and a delicious meal to enjoy together.',
          category: 'Food & Dining',
          tags: ['cooking', 'food', 'learning', 'african cuisine', 'hands-on'],
          isFree: false,
          ticketPrice: 35.0, // $35 for cooking class
          maxAttendees: 20,
        ),
      ),
      EventTemplate(
        id: 'fitness_workout',
        name: 'Fitness Workout',
        description: 'Group fitness and wellness session',
        category: 'Sports & Fitness',
        icon: '💪',
        color: 0xFF4CAF50,
        suggestedDuration: const Duration(hours: 2),
        defaultData: _createEventData(
          name: 'African Dance Fitness',
          description:
              'Get your heart pumping with energetic African dance moves! Perfect for all fitness levels. Bring water and wear comfortable clothes.',
          category: 'Sports & Fitness',
          tags: ['fitness', 'dance', 'workout', 'african music', 'wellness'],
          isFree: true, // Fitness events often free
          maxAttendees: 30,
        ),
      ),
      EventTemplate(
        id: 'movie_night',
        name: 'Movie Night',
        description: 'Watch and discuss African films',
        category: 'Entertainment',
        icon: '🎬',
        color: 0xFF9C27B0,
        suggestedDuration: const Duration(hours: 3),
        defaultData: _createEventData(
          name: 'African Cinema Night',
          description:
              'Join us for a screening of amazing African films followed by a discussion. Popcorn and refreshments provided!',
          category: 'Entertainment',
          tags: [
            'movies',
            'cinema',
            'african films',
            'discussion',
            'entertainment'
          ],
          isFree: true, // Movie nights often free
          maxAttendees: 50,
        ),
      ),
    ];
  }

  static EventTemplate? getTemplateById(String id) {
    try {
      return getAfrocentricTemplates()
          .firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper method to create EventCreationData with proper initialization
  static EventCreationData _createEventData({
    required String name,
    required String description,
    required String category,
    required List<String> tags,
    bool isFree = false,
    double? ticketPrice,
    int maxAttendees = 100,
  }) {
    final data = EventCreationData();
    data.name = name;
    data.description = description;
    data.category = category;
    data.tags = tags;
    data.isFree = isFree;
    data.ticketPrice = ticketPrice;
    data.maxAttendees = maxAttendees;
    return data;
  }
}

class EventTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int color;
  final Duration suggestedDuration;
  final EventCreationData defaultData;

  const EventTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.suggestedDuration,
    required this.defaultData,
  });
}
